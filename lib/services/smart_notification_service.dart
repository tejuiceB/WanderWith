import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_env.dart';
import '../config/notification_templates.dart';
import '../models/notification.dart';
import 'notification_service.dart';

/// Orchestrates all notification layers — checks user preferences, resolves
/// language, enforces anti-spam, and routes to the correct delivery path.
///
/// Layers:
///   A — Transactional (instant, via [NotificationService])
///   B — Smart engagement (scheduled)
///   C — AI-generated marketing (scheduled)
///   D — Regional language (template resolution)
///   E — Festival alerts (scheduled)
///   F — Trip lifecycle (scheduled)
///   G — Weather-triggered (scheduled)
///   H — User controls (pref check)
///   I — Smart timing (optimal hour)
///   J — Memory anniversary (scheduled)
class SmartNotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final NotificationService _notifService = NotificationService();

  // ── Singleton ─────────────────────────────────────────────────────
  static final SmartNotificationService _instance = SmartNotificationService._internal();
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();

  // ── Preference keys → NotificationType mapping ────────────────────
  static const _prefMapping = <NotificationType, String>{
    NotificationType.message: 'messages',
    NotificationType.chatMention: 'mentions',
    NotificationType.chatReply: 'messages',
    NotificationType.chatReaction: 'messages',
    NotificationType.joinRequest: 'trip_updates',
    NotificationType.joinResponse: 'trip_updates',
    NotificationType.dateChange: 'trip_updates',
    NotificationType.budgetChange: 'trip_updates',
    NotificationType.tripUpdate: 'trip_updates',
    NotificationType.adminPromoted: 'trip_updates',
    NotificationType.removedFromTrip: 'trip_updates',
    NotificationType.pollAdded: 'trip_updates',
    NotificationType.pollCreated: 'trip_updates',
    NotificationType.like: 'likes_comments',
    NotificationType.comment: 'likes_comments',
    NotificationType.followRequest: 'follow_activity',
    NotificationType.followAccepted: 'follow_activity',
    NotificationType.feedbackRequest: 'trip_reminders',
    NotificationType.tripReminder: 'trip_reminders',
    NotificationType.weatherAlert: 'weather_alerts',
    NotificationType.festivalAlert: 'festival_alerts',
    NotificationType.travelInspiration: 'travel_inspiration',
    NotificationType.memoryAnniversary: 'travel_inspiration',
  };

  // Non-transactional types are scheduled (not instant)
  static const _scheduledTypes = <NotificationType>{
    NotificationType.tripReminder,
    NotificationType.weatherAlert,
    NotificationType.festivalAlert,
    NotificationType.travelInspiration,
    NotificationType.memoryAnniversary,
  };

  // ── Public API ────────────────────────────────────────────────────

  /// Send a notification respecting user preferences, language, and timing.
  /// For non-transactional types this schedules at the user's optimal hour.
  Future<void> send({
    required String toUserId,
    required String title,
    required String body,
    required NotificationType type,
    String? tripId,
    String? subtype,
    String? deepLink,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 1. Fetch user prefs
      final prefs = await _getUserPrefs(toUserId);
      if (prefs == null) return; // user not found

      // 2. Check if this category is enabled
      if (!_isCategoryEnabled(type, prefs)) return;

      // 3. Check quiet hours for non-transactional
      // (quiet hours only block non-transactional; transactional always go through)
      final isScheduled = _scheduledTypes.contains(type);

      if (isScheduled) {
        // Schedule at optimal time
        final optimalHour = prefs['optimal_send_hour'] as int? ?? 9;
        final tz = prefs['user_timezone'] as String?;
        final scheduledFor = _nextOptimalTime(optimalHour, tz);

        // Anti-spam: check notification_log for recent same subtype
        if (subtype != null) {
          final isDuplicate = await _isDuplicate(toUserId, subtype, tripId);
          if (isDuplicate) return;
        }

        // Insert into scheduled_notifications
        await _supabase.from('scheduled_notifications').insert({
          'user_id': toUserId,
          'title': title,
          'body': body,
          'type': AppNotification.typeToString(type),
          'subtype': subtype,
          'trip_id': tripId,
          'deep_link': deepLink,
          'image_url': imageUrl,
          'language': _resolveLanguage(prefs),
          'scheduled_for': scheduledFor.toIso8601String(),
        });
      } else {
        // Instant delivery
        await _notifService.sendNotification(
          toUserId: toUserId,
          title: title,
          body: body,
          type: type,
          tripId: tripId,
          metadata: {
            if (deepLink != null) 'deep_link': deepLink,
            if (imageUrl != null) 'image_url': imageUrl,
            if (metadata != null) ...metadata,
          },
        );
      }

      // 4. Log for dedup & analytics
      await _logNotification(toUserId, type, subtype, tripId);
    } catch (e) {
      print('SmartNotificationService.send error: $e');
    }
  }

  /// Send a localized notification using a template key.
  Future<void> sendTemplated({
    required String toUserId,
    required String templateKey,
    required NotificationType type,
    Map<String, String> vars = const {},
    String? tripId,
    String? deepLink,
    String? imageUrl,
  }) async {
    try {
      final prefs = await _getUserPrefs(toUserId);
      if (prefs == null) return;
      final lang = _resolveLanguage(prefs);
      final resolvedBody = NotificationTemplates.get(templateKey, lang, vars);
      // Use the first line as title, or a generic title
      final title = _titleForType(type, lang);

      await send(
        toUserId: toUserId,
        title: title,
        body: resolvedBody,
        type: type,
        tripId: tripId,
        subtype: templateKey,
        deepLink: deepLink,
        imageUrl: imageUrl,
      );
    } catch (e) {
      print('SmartNotificationService.sendTemplated error: $e');
    }
  }

  /// Generate an AI-powered notification using Gemini.
  /// Returns the generated text, or null on failure.
  Future<String?> generateAINotification({
    required String context,
    required String language,
    String tone = 'friendly, witty',
  }) async {
    try {
      final apiKey = AppEnv.geminiApiKey;
      final prompt = '''Generate a short, emotional travel notification in $language for a user who $context.
Rules:
- Max 80 characters
- Include 1 emoji
- Tone: $tone
- No hashtags
- Return ONLY the notification text, nothing else''';

      final models = [
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-1.5-flash-latest',
      ];

      for (final model in models) {
        try {
          final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey'
          );
          final resp = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [{'parts': [{'text': prompt}]}],
            }),
          );
          if (resp.statusCode == 200) {
            final data = jsonDecode(resp.body);
            final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
            if (text != null && text.trim().isNotEmpty) {
              return text.trim();
            }
          }
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (e) {
      print('SmartNotificationService.generateAINotification error: $e');
      return null;
    }
  }

  // ── Preference helpers ────────────────────────────────────────────

  /// Get user notification prefs + language + timing fields.
  Future<Map<String, dynamic>?> _getUserPrefs(String userId) async {
    try {
      final resp = await _supabase
          .from('profiles')
          .select('notification_prefs, preferred_notification_language, optimal_send_hour, user_timezone, country')
          .eq('id', userId)
          .maybeSingle();
      if (resp == null) return null;

      final prefs = Map<String, dynamic>.from(resp['notification_prefs'] ?? _defaultPrefs);
      prefs['preferred_notification_language'] = resp['preferred_notification_language'] ?? 'auto';
      prefs['optimal_send_hour'] = resp['optimal_send_hour'] ?? 9;
      prefs['user_timezone'] = resp['user_timezone'];
      prefs['country'] = resp['country'];
      return prefs;
    } catch (e) {
      return null;
    }
  }

  bool _isCategoryEnabled(NotificationType type, Map<String, dynamic> prefs) {
    final prefKey = _prefMapping[type];
    if (prefKey == null) return true; // unknown type → allow
    // Mentions are forced on
    if (type == NotificationType.chatMention) return true;
    return prefs[prefKey] as bool? ?? true;
  }

  String _resolveLanguage(Map<String, dynamic> prefs) {
    final pref = prefs['preferred_notification_language'] as String? ?? 'auto';
    if (pref != 'auto') return pref;
    // Fallback: use country to guess
    final country = prefs['country'] as String? ?? '';
    switch (country.toLowerCase()) {
      case 'india': return 'en';   // default en for India — user can override to hi/mr
      case 'japan': return 'ja';
      case 'brazil': return 'pt';
      case 'germany': case 'austria': return 'de';
      case 'france': return 'fr';
      case 'spain': case 'mexico': case 'argentina': case 'colombia': return 'es';
      default: return 'en';
    }
  }

  // ── Anti-spam / dedup ─────────────────────────────────────────────

  Future<bool> _isDuplicate(String userId, String subtype, String? tripId) async {
    try {
      final query = _supabase
          .from('notification_log')
          .select('id')
          .eq('user_id', userId)
          .eq('subtype', subtype)
          .gte('sent_at', DateTime.now().subtract(const Duration(hours: 12)).toIso8601String());

      if (tripId != null) {
        final result = await query.eq('trip_id', tripId).limit(1);
        return (result as List).isNotEmpty;
      } else {
        final result = await query.limit(1);
        return (result as List).isNotEmpty;
      }
    } catch (_) {
      return false; // on error, allow — better to send than to silently drop
    }
  }

  Future<void> _logNotification(String userId, NotificationType type, String? subtype, String? tripId) async {
    try {
      final category = _scheduledTypes.contains(type)
          ? (type == NotificationType.travelInspiration || type == NotificationType.memoryAnniversary
              ? 'marketing' : 'engagement')
          : 'transactional';

      await _supabase.from('notification_log').insert({
        'user_id': userId,
        'notification_type': category,
        'subtype': subtype ?? AppNotification.typeToString(type),
        'trip_id': tripId,
      });
    } catch (_) {
      // non-critical — don't block the send
    }
  }

  // ── Timing ────────────────────────────────────────────────────────

  DateTime _nextOptimalTime(int optimalHour, String? timezone) {
    // Simple approach: schedule for today at optimalHour if still in future,
    // otherwise tomorrow. Uses UTC offset heuristic from timezone string.
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, optimalHour);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  String _titleForType(NotificationType type, String lang) {
    switch (type) {
      case NotificationType.tripReminder:
        return lang == 'hi' ? 'ट्रिप रिमाइंडर' :
               lang == 'mr' ? 'ट्रिप रिमाइंडर' :
               lang == 'es' ? 'Recordatorio de viaje' :
               lang == 'fr' ? 'Rappel de voyage' :
               lang == 'ja' ? '旅行リマインダー' :
               lang == 'pt' ? 'Lembrete de viagem' :
               lang == 'de' ? 'Reise-Erinnerung' :
               'Trip Reminder';
      case NotificationType.weatherAlert:
        return lang == 'hi' ? 'मौसम अलर्ट' :
               lang == 'mr' ? 'हवामान अलर्ट' :
               lang == 'es' ? 'Alerta meteorológica' :
               lang == 'fr' ? 'Alerte météo' :
               lang == 'ja' ? '天気アラート' :
               lang == 'pt' ? 'Alerta de clima' :
               lang == 'de' ? 'Wetterwarnung' :
               'Weather Alert';
      case NotificationType.festivalAlert:
        return lang == 'hi' ? 'त्योहार अलर्ट' :
               lang == 'mr' ? 'सणाचा अलर्ट' :
               lang == 'es' ? 'Alerta de festival' :
               lang == 'fr' ? 'Alerte festival' :
               lang == 'ja' ? 'フェスティバルアラート' :
               lang == 'pt' ? 'Alerta de festival' :
               lang == 'de' ? 'Festival-Hinweis' :
               'Festival Alert';
      case NotificationType.travelInspiration:
        return lang == 'hi' ? 'ट्रैवल इंस्पिरेशन' :
               lang == 'mr' ? 'ट्रॅव्हल इन्स्पिरेशन' :
               'Travel Inspiration ✨';
      case NotificationType.memoryAnniversary:
        return lang == 'hi' ? 'यादें 💛' :
               lang == 'mr' ? 'आठवणी 💛' :
               'Memories 💛';
      default:
        return 'WanderWith';
    }
  }

  static const _defaultPrefs = {
    'messages': true,
    'mentions': true,
    'trip_updates': true,
    'likes_comments': true,
    'follow_activity': true,
    'trip_reminders': true,
    'festival_alerts': true,
    'travel_inspiration': true,
    'marketing': true,
    'weather_alerts': true,
    'quiet_hours_enabled': false,
    'quiet_hours_start': '22:00',
    'quiet_hours_end': '08:00',
  };

  /// Public access to default prefs (used by preferences screen).
  static Map<String, dynamic> get defaultPrefs => Map.from(_defaultPrefs);
}
