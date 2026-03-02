import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    Future<void> tryLoad(String file) async {
      if (_initialized) return;
      try {
        await dotenv.load(fileName: file);
        _initialized = true;
      } catch (_) {
        // ignore: the file might not exist; we'll fall back
      }
    }

    await tryLoad('.env.local');
    await tryLoad('.env');

    if (!_initialized) {
      await dotenv.load(fileName: '.env.example');
      _initialized = true;
    }

    validate();
  }

  static String get supabaseUrl => _get('SUPABASE_URL');
  static String get supabaseAnonKey => _get('SUPABASE_ANON_KEY');
  static String get googleWebClientId => _get('GOOGLE_WEB_CLIENT_ID');
  static String get googleMapsApiKey => _get('GOOGLE_MAPS_API_KEY');
  static String get geminiApiKey => _get('GEMINI_API_KEY');
  static String get weatherApiKey => _get('WEATHER_API_KEY');

  static String _get(String key) {
    final fromDefine = _valueFromDartDefine(key);
    if (fromDefine.isNotEmpty) return fromDefine;

    if (!dotenv.isInitialized) return '';
    return dotenv.env[key] ?? '';
  }

  static String _valueFromDartDefine(String key) {
    switch (key) {
      case 'SUPABASE_URL':
        return const String.fromEnvironment('SUPABASE_URL');
      case 'SUPABASE_ANON_KEY':
        return const String.fromEnvironment('SUPABASE_ANON_KEY');
      case 'GOOGLE_WEB_CLIENT_ID':
        return const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      case 'GOOGLE_MAPS_API_KEY':
        return const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
      case 'GEMINI_API_KEY':
        return const String.fromEnvironment('GEMINI_API_KEY');
      case 'WEATHER_API_KEY':
        return const String.fromEnvironment('WEATHER_API_KEY');
      default:
        return '';
    }
  }

  static void validate() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (googleWebClientId.isEmpty) missing.add('GOOGLE_WEB_CLIENT_ID');
    // if (googleMapsApiKey.isEmpty) missing.add('GOOGLE_MAPS_API_KEY'); // Optional for now to prevent crash if not set immediately
    if (geminiApiKey.isEmpty) missing.add('GEMINI_API_KEY');

    if (missing.isNotEmpty) {
      throw StateError('Missing environment values: ${missing.join(', ')}');
    }
  }
}
