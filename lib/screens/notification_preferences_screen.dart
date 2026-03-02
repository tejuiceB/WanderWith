import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/notification_templates.dart';
import '../services/smart_notification_service.dart';
import '../theme/theme_extensions.dart';

/// Full notification preferences screen (Layer H).
///
/// Stores prefs as JSONB in `profiles.notification_prefs` and language in
/// `profiles.preferred_notification_language`.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final _supabase = Supabase.instance.client;
  bool _loading = true;
  bool _saving = false;

  // ── Notification category toggles ─────────────────────────────────
  late bool _messages;
  late bool _mentions;
  late bool _tripUpdates;
  late bool _likesComments;
  late bool _followActivity;
  late bool _tripReminders;
  late bool _festivalAlerts;
  late bool _travelInspiration;
  late bool _marketing;
  late bool _weatherAlerts;

  // ── Quiet hours ───────────────────────────────────────────────────
  late bool _quietHoursEnabled;
  late TimeOfDay _quietStart;
  late TimeOfDay _quietEnd;

  // ── Language ──────────────────────────────────────────────────────
  late String _language; // 'auto', 'en', 'hi', ...

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      final resp = await _supabase
          .from('profiles')
          .select('notification_prefs, preferred_notification_language')
          .eq('id', uid)
          .maybeSingle();

      final prefs = Map<String, dynamic>.from(
        resp?['notification_prefs'] ?? SmartNotificationService.defaultPrefs
      );

      setState(() {
        _messages = prefs['messages'] as bool? ?? true;
        _mentions = prefs['mentions'] as bool? ?? true;
        _tripUpdates = prefs['trip_updates'] as bool? ?? true;
        _likesComments = prefs['likes_comments'] as bool? ?? true;
        _followActivity = prefs['follow_activity'] as bool? ?? true;
        _tripReminders = prefs['trip_reminders'] as bool? ?? true;
        _festivalAlerts = prefs['festival_alerts'] as bool? ?? true;
        _travelInspiration = prefs['travel_inspiration'] as bool? ?? true;
        _marketing = prefs['marketing'] as bool? ?? true;
        _weatherAlerts = prefs['weather_alerts'] as bool? ?? true;
        _quietHoursEnabled = prefs['quiet_hours_enabled'] as bool? ?? false;
        _quietStart = _parseTime(prefs['quiet_hours_start'] as String? ?? '22:00');
        _quietEnd = _parseTime(prefs['quiet_hours_end'] as String? ?? '08:00');
        _language = resp?['preferred_notification_language'] as String? ?? 'auto';
        _loading = false;
      });
    } catch (e) {
      // Fallback to defaults
      setState(() {
        _messages = true; _mentions = true; _tripUpdates = true;
        _likesComments = true; _followActivity = true; _tripReminders = true;
        _festivalAlerts = true; _travelInspiration = true; _marketing = true;
        _weatherAlerts = true; _quietHoursEnabled = false;
        _quietStart = const TimeOfDay(hour: 22, minute: 0);
        _quietEnd = const TimeOfDay(hour: 8, minute: 0);
        _language = 'auto';
        _loading = false;
      });
    }
  }

  Future<void> _savePrefs() async {
    setState(() => _saving = true);
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return;

      final prefs = {
        'messages': _messages,
        'mentions': _mentions,
        'trip_updates': _tripUpdates,
        'likes_comments': _likesComments,
        'follow_activity': _followActivity,
        'trip_reminders': _tripReminders,
        'festival_alerts': _festivalAlerts,
        'travel_inspiration': _travelInspiration,
        'marketing': _marketing,
        'weather_alerts': _weatherAlerts,
        'quiet_hours_enabled': _quietHoursEnabled,
        'quiet_hours_start': _formatTime(_quietStart),
        'quiet_hours_end': _formatTime(_quietEnd),
      };

      await _supabase.from('profiles').update({
        'notification_prefs': prefs,
        'preferred_notification_language': _language,
      }).eq('id', uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification preferences saved ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.iconDefault),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(color: colors.textPrimary, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _savePrefs,
            child: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF448AFF))),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                // ── Communication ─────────────────────────────────
                _sectionHeader('Communication'),
                _toggleTile(
                  icon: Icons.chat_bubble_outline,
                  title: 'Chat Messages',
                  subtitle: 'New messages in trip chats',
                  value: _messages,
                  onChanged: (v) => setState(() => _messages = v),
                ),
                _toggleTile(
                  icon: Icons.alternate_email,
                  title: 'Mentions',
                  subtitle: '@Mentions are always enabled',
                  value: _mentions,
                  onChanged: null, // Locked ON
                  locked: true,
                ),

                const SizedBox(height: 16),
                _sectionHeader('Trip Activity'),
                _toggleTile(
                  icon: Icons.info_outline,
                  title: 'Trip Updates',
                  subtitle: 'Members joined/left, dates changed, admin changes',
                  value: _tripUpdates,
                  onChanged: (v) => setState(() => _tripUpdates = v),
                ),
                _toggleTile(
                  icon: Icons.alarm_outlined,
                  title: 'Trip Reminders',
                  subtitle: 'Packing, weather, checklist, departure',
                  value: _tripReminders,
                  onChanged: (v) => setState(() => _tripReminders = v),
                ),
                _toggleTile(
                  icon: Icons.cloud_outlined,
                  title: 'Weather Alerts',
                  subtitle: 'Weather warnings for upcoming trips',
                  value: _weatherAlerts,
                  onChanged: (v) => setState(() => _weatherAlerts = v),
                ),

                const SizedBox(height: 16),
                _sectionHeader('Social'),
                _toggleTile(
                  icon: Icons.favorite_border,
                  title: 'Likes & Comments',
                  subtitle: 'Activity on your posts',
                  value: _likesComments,
                  onChanged: (v) => setState(() => _likesComments = v),
                ),
                _toggleTile(
                  icon: Icons.person_add_outlined,
                  title: 'Follow Activity',
                  subtitle: 'New followers and follow accepts',
                  value: _followActivity,
                  onChanged: (v) => setState(() => _followActivity = v),
                ),

                const SizedBox(height: 16),
                _sectionHeader('Inspiration'),
                _toggleTile(
                  icon: Icons.celebration_outlined,
                  title: 'Festival Alerts',
                  subtitle: 'Festival travel suggestions for your country',
                  value: _festivalAlerts,
                  onChanged: (v) => setState(() => _festivalAlerts = v),
                ),
                _toggleTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Travel Inspiration',
                  subtitle: 'AI-generated travel nudges',
                  value: _travelInspiration,
                  onChanged: (v) => setState(() => _travelInspiration = v),
                ),
                _toggleTile(
                  icon: Icons.campaign_outlined,
                  title: 'Promotions',
                  subtitle: 'Promotional messages and tips',
                  value: _marketing,
                  onChanged: (v) => setState(() => _marketing = v),
                ),

                // ── Language ──────────────────────────────────────
                const SizedBox(height: 24),
                _sectionHeader('Language'),
                _buildLanguagePicker(colors),

                // ── Quiet Hours ───────────────────────────────────
                const SizedBox(height: 24),
                _sectionHeader('Quiet Hours'),
                _toggleTile(
                  icon: Icons.do_not_disturb_on_outlined,
                  title: 'Do Not Disturb',
                  subtitle: 'Delay non-urgent notifications during quiet hours',
                  value: _quietHoursEnabled,
                  onChanged: (v) => setState(() => _quietHoursEnabled = v),
                ),
                if (_quietHoursEnabled) ...[
                  const SizedBox(height: 8),
                  _buildTimePicker(
                    label: 'From',
                    time: _quietStart,
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _quietStart);
                      if (picked != null) setState(() => _quietStart = picked);
                    },
                    colors: colors,
                  ),
                  const SizedBox(height: 8),
                  _buildTimePicker(
                    label: 'Until',
                    time: _quietEnd,
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _quietEnd);
                      if (picked != null) setState(() => _quietEnd = picked);
                    },
                    colors: colors,
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
    );
  }

  // ── Widget builders ───────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.appColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool locked = false,
  }) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ListTile(
        leading: Icon(icon, color: colors.iconDefault, size: 22),
        title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: colors.textPrimary)),
        subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
        trailing: locked
            ? Icon(Icons.lock_outline, size: 18, color: colors.textMuted)
            : Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF448AFF),
              ),
      ),
    );
  }

  Widget _buildLanguagePicker(dynamic colors) {
    final langs = <String, String>{
      'auto': 'Auto (Device)',
      ...NotificationTemplates.supportedLanguages,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ListTile(
        leading: Icon(Icons.language, color: colors.iconDefault, size: 22),
        title: Text('Notification Language', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: colors.textPrimary)),
        subtitle: Text(langs[_language] ?? 'Auto', style: GoogleFonts.inter(fontSize: 12, color: colors.textSecondary)),
        trailing: Icon(Icons.chevron_right, size: 18, color: colors.iconMuted),
        onTap: () => _showLanguagePicker(langs),
      ),
    );
  }

  void _showLanguagePicker(Map<String, String> langs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            expand: false,
            builder: (ctx, scrollController) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text('Notification Language', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      ...langs.entries.map((e) => ListTile(
                        leading: _language == e.key
                            ? const Icon(Icons.check_circle, color: Color(0xFF448AFF))
                            : const Icon(Icons.circle_outlined, color: Colors.grey),
                        title: Text(e.value, style: GoogleFonts.inter(fontWeight: _language == e.key ? FontWeight.bold : FontWeight.normal)),
                        onTap: () {
                          setState(() => _language = e.key);
                          Navigator.pop(ctx);
                        },
                      )),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required dynamic colors,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16),
      decoration: BoxDecoration(
        color: colors.surfaceBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.access_time, color: colors.iconDefault, size: 20),
        title: Text(label, style: GoogleFonts.inter(fontSize: 14, color: colors.textPrimary)),
        trailing: Text(
          _formatTimeDisplay(time),
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF448AFF)),
        ),
        onTap: onTap,
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────

  TimeOfDay _parseTime(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.tryParse(parts[0]) ?? 22, minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
  }

  String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatTimeDisplay(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }
}
