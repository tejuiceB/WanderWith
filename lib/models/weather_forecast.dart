/// Holds weather data for a trip destination.
class WeatherForecast {
  final String location;
  final WeatherCurrent? current;
  final List<WeatherDay> days;
  final DateTime fetchedAt;

  WeatherForecast({
    required this.location,
    this.current,
    required this.days,
    required this.fetchedAt,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    return WeatherForecast(
      location: json['location'] ?? '',
      current: json['current'] != null
          ? WeatherCurrent.fromJson(json['current'])
          : null,
      days: (json['days'] as List? ?? [])
          .map((d) => WeatherDay.fromJson(d))
          .toList(),
      fetchedAt: json['fetched_at'] != null
          ? DateTime.parse(json['fetched_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'location': location,
        if (current != null) 'current': current!.toJson(),
        'days': days.map((d) => d.toJson()).toList(),
        'fetched_at': fetchedAt.toIso8601String(),
      };

  bool get isStale =>
      DateTime.now().difference(fetchedAt).inHours >= 6;
}

/// Current weather conditions.
class WeatherCurrent {
  final double tempC;
  final double feelsLikeC;
  final String condition;
  final String iconUrl;
  final int humidity;
  final double windKph;
  final double uv;

  WeatherCurrent({
    required this.tempC,
    required this.feelsLikeC,
    required this.condition,
    required this.iconUrl,
    required this.humidity,
    required this.windKph,
    required this.uv,
  });

  factory WeatherCurrent.fromJson(Map<String, dynamic> json) {
    return WeatherCurrent(
      tempC: (json['temp_c'] ?? 0).toDouble(),
      feelsLikeC: (json['feels_like_c'] ?? 0).toDouble(),
      condition: json['condition'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      humidity: json['humidity'] ?? 0,
      windKph: (json['wind_kph'] ?? 0).toDouble(),
      uv: (json['uv'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'temp_c': tempC,
        'feels_like_c': feelsLikeC,
        'condition': condition,
        'icon_url': iconUrl,
        'humidity': humidity,
        'wind_kph': windKph,
        'uv': uv,
      };
}

/// One day of forecast.
class WeatherDay {
  final DateTime date;
  final double maxTempC;
  final double minTempC;
  final double avgTempC;
  final String condition;
  final String iconUrl;
  final int chanceOfRain;
  final double maxWindKph;
  final double uv;
  final String sunrise;
  final String sunset;

  WeatherDay({
    required this.date,
    required this.maxTempC,
    required this.minTempC,
    required this.avgTempC,
    required this.condition,
    required this.iconUrl,
    required this.chanceOfRain,
    required this.maxWindKph,
    required this.uv,
    this.sunrise = '',
    this.sunset = '',
  });

  factory WeatherDay.fromJson(Map<String, dynamic> json) {
    return WeatherDay(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      maxTempC: (json['max_temp_c'] ?? 0).toDouble(),
      minTempC: (json['min_temp_c'] ?? 0).toDouble(),
      avgTempC: (json['avg_temp_c'] ?? 0).toDouble(),
      condition: json['condition'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      chanceOfRain: json['chance_of_rain'] ?? 0,
      maxWindKph: (json['max_wind_kph'] ?? 0).toDouble(),
      uv: (json['uv'] ?? 0).toDouble(),
      sunrise: json['sunrise'] ?? '',
      sunset: json['sunset'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String().substring(0, 10),
        'max_temp_c': maxTempC,
        'min_temp_c': minTempC,
        'avg_temp_c': avgTempC,
        'condition': condition,
        'icon_url': iconUrl,
        'chance_of_rain': chanceOfRain,
        'max_wind_kph': maxWindKph,
        'uv': uv,
        'sunrise': sunrise,
        'sunset': sunset,
      };

  /// Emoji for condition text
  String get conditionEmoji {
    final c = condition.toLowerCase();
    if (c.contains('sunny') || c.contains('clear')) return '☀️';
    if (c.contains('partly cloudy')) return '⛅';
    if (c.contains('cloudy') || c.contains('overcast')) return '☁️';
    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    if (c.contains('thunder') || c.contains('storm')) return '⛈️';
    if (c.contains('snow') || c.contains('blizzard')) return '❄️';
    if (c.contains('fog') || c.contains('mist')) return '🌫️';
    if (c.contains('sleet') || c.contains('ice')) return '🌨️';
    if (c.contains('wind')) return '💨';
    return '🌤️';
  }
}
