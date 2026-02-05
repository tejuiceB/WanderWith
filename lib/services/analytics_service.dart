import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> logEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    final user = _supabase.auth.currentUser;
    // Silent failure is acceptable for analytics
    try {
      await _supabase.from('analytics').insert({
        'event_name': eventName,
        'user_id': user?.id,
        'parameters': parameters ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Fail silently in production, maybe print in debug
      // print('Analytics Error: $e'); 
    }
  }
}
