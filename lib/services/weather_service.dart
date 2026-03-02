import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_env.dart';
import '../models/weather_forecast.dart';

/// Fetches weather data from WeatherAPI.com and caches in trip_metadata.
class WeatherService {
  final SupabaseClient _supabase = Supabase.instance.client;

  String get _apiKey => AppEnv.weatherApiKey;
  bool get _hasKey => _apiKey.isNotEmpty;

  // ── Public API ──

  /// Get weather for a trip location. Uses 6-hour cache from DB.
  /// Returns null if API key is missing or all calls fail.
  Future<WeatherForecast?> getWeatherForTrip({
    required String tripId,
    required String location,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!_hasKey) return null;

    // 1. Check cache
    final cached = await _getCachedWeather(tripId);
    if (cached != null && !cached.isStale) return cached;

    // 2. Fetch fresh data
    try {
      final forecast = await _fetchForecast(location, startDate, endDate);
      if (forecast != null) {
        await _cacheWeather(tripId, forecast);
      }
      return forecast;
    } catch (e) {
      debugPrint('WeatherService error: $e');
      // Return stale cache if fresh call failed
      return cached;
    }
  }

  // ── Cache Layer ──

  Future<WeatherForecast?> _getCachedWeather(String tripId) async {
    try {
      final row = await _supabase
          .from('trip_metadata')
          .select('weather_data, weather_updated_at')
          .eq('trip_id', tripId)
          .maybeSingle();

      if (row == null) return null;
      final weatherJson = row['weather_data'];
      if (weatherJson == null) return null;

      final data = weatherJson is String ? jsonDecode(weatherJson) : weatherJson;
      return WeatherForecast.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Weather cache read failed: $e');
      return null;
    }
  }

  Future<void> _cacheWeather(String tripId, WeatherForecast forecast) async {
    try {
      await _supabase
          .from('trip_metadata')
          .update({
            'weather_data': forecast.toJson(),
            'weather_updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('trip_id', tripId);
    } catch (e) {
      debugPrint('Weather cache write failed: $e');
    }
  }

  // ── WeatherAPI.com calls ──

  /// Decide which API call to make based on trip dates.
  Future<WeatherForecast?> _fetchForecast(
    String location,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final now = DateTime.now();

    // Determine trip timing
    final bool isOngoing = startDate != null &&
        endDate != null &&
        now.isAfter(startDate) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
    final bool isUpcoming = startDate != null &&
        startDate.isAfter(now) &&
        startDate.difference(now).inDays <= 13;

    if (isOngoing || isUpcoming) {
      // Use forecast API (up to 14 days with free tier = 3 days, paid = 14)
      return _fetchForecastApi(location);
    }

    // Trip is far out or past — still show current + short forecast as reference
    return _fetchForecastApi(location);
  }

  /// Fetch 3-day forecast + current weather from WeatherAPI.com free tier
  Future<WeatherForecast?> _fetchForecastApi(String location) async {
    final uri = Uri.https(
      'api.weatherapi.com',
      '/v1/forecast.json',
      {
        'key': _apiKey,
        'q': location,
        'days': '3',
        'aqi': 'no',
        'alerts': 'no',
      },
    );

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      debugPrint('Weather API error ${response.statusCode}: ${response.body}');
      return null;
    }

    final data = jsonDecode(response.body);

    // Parse current conditions
    final currentRaw = data['current'];
    final current = WeatherCurrent(
      tempC: (currentRaw['temp_c'] ?? 0).toDouble(),
      feelsLikeC: (currentRaw['feelslike_c'] ?? 0).toDouble(),
      condition: currentRaw['condition']?['text'] ?? '',
      iconUrl: 'https:${currentRaw['condition']?['icon'] ?? ''}',
      humidity: currentRaw['humidity'] ?? 0,
      windKph: (currentRaw['wind_kph'] ?? 0).toDouble(),
      uv: (currentRaw['uv'] ?? 0).toDouble(),
    );

    // Parse forecast days
    final forecastDays = <WeatherDay>[];
    final rawDays = data['forecast']?['forecastday'] as List? ?? [];
    for (final day in rawDays) {
      final dayData = day['day'];
      final astro = day['astro'];
      forecastDays.add(WeatherDay(
        date: DateTime.tryParse(day['date'] ?? '') ?? DateTime.now(),
        maxTempC: (dayData['maxtemp_c'] ?? 0).toDouble(),
        minTempC: (dayData['mintemp_c'] ?? 0).toDouble(),
        avgTempC: (dayData['avgtemp_c'] ?? 0).toDouble(),
        condition: dayData['condition']?['text'] ?? '',
        iconUrl: 'https:${dayData['condition']?['icon'] ?? ''}',
        chanceOfRain: dayData['daily_chance_of_rain'] ?? 0,
        maxWindKph: (dayData['maxwind_kph'] ?? 0).toDouble(),
        uv: (dayData['uv'] ?? 0).toDouble(),
        sunrise: astro?['sunrise'] ?? '',
        sunset: astro?['sunset'] ?? '',
      ));
    }

    final locationName = data['location']?['name'] ?? location;

    return WeatherForecast(
      location: locationName,
      current: current,
      days: forecastDays,
      fetchedAt: DateTime.now(),
    );
  }
}
