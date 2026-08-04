import 'dart:convert';
import 'package:http/http.dart' as http;

class CityResult {
  final String name;
  final String? admin1;
  final String? country;
  final double latitude;
  final double longitude;

  const CityResult({
    required this.name,
    this.admin1,
    this.country,
    required this.latitude,
    required this.longitude,
  });

  factory CityResult.fromJson(Map<String, dynamic> json) {
    return CityResult(
      name: json['name']?.toString() ?? '',
      admin1: json['admin1']?.toString(),
      country: json['country']?.toString(),
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  String get displayLabel => [name, admin1, country]
      .where((e) => e != null && e.isNotEmpty)
      .join(', ');
}

class WeatherData {
  final String cityName;
  final int temp;
  final int high;
  final int low;
  final String condition;
  final int humidity;
  final int windSpeed;
  final int pressure;
  final String icon;

  const WeatherData({
    required this.cityName,
    required this.temp,
    required this.high,
    required this.low,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.icon,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final w = json['weather'] as Map<String, dynamic>? ?? {};
    int toInt(dynamic v, int fallback) =>
        v is int ? v : (v is double ? v.round() : int.tryParse(v?.toString() ?? '') ?? fallback);
    return WeatherData(
      cityName: w['cityName']?.toString() ?? '',
      temp: toInt(w['temp'], 20),
      high: toInt(w['high'], 24),
      low: toInt(w['low'], 16),
      condition: w['condition']?.toString() ?? '',
      humidity: toInt(w['humidity'], 50),
      windSpeed: toInt(w['windSpeed'], 10),
      pressure: toInt(w['pressure'], 1013),
      icon: w['icon']?.toString() ?? '',
    );
  }
}

class WeatherApi {
  Future<WeatherData> getWeather({double? lat, double? lon, String? city}) async {
    final latitude = lat ?? 49.9542;
    final longitude = lon ?? 18.5833;

    final currentUri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,surface_pressure'
      '&daily=temperature_2m_max,temperature_2m_min'
      '&timezone=auto&forecast_days=1',
    );

    final res = await http.get(currentUri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Bledne dane pogodowe');

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>? ?? {};
    final daily = data['daily'] as Map<String, dynamic>? ?? {};

    final code = (current['weather_code'] ?? 0) as int;
    final condition = _conditionFromCode(code);
    final icon = _iconFromCode(code);

    final tempsMax = daily['temperature_2m_max'] as List?;
    final tempsMin = daily['temperature_2m_min'] as List?;

    return WeatherData(
      cityName: city ?? 'Jastrzebie-Zdroj',
      temp: (current['temperature_2m'] ?? 20).round(),
      high: tempsMax != null && tempsMax.isNotEmpty
          ? (tempsMax[0] as num).round()
          : 24,
      low: tempsMin != null && tempsMin.isNotEmpty
          ? (tempsMin[0] as num).round()
          : 16,
      condition: condition,
      humidity: (current['relative_humidity_2m'] ?? 50).round(),
      windSpeed: (current['wind_speed_10m'] ?? 10).round(),
      pressure: (current['surface_pressure'] ?? 1013).round(),
      icon: icon,
    );
  }

  Future<List<CityResult>> searchCities(String query) async {
    final q = Uri.encodeComponent(query.trim());
    final uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=$q&count=8&language=pl&format=json',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List? ?? [];
    return results.map((c) => CityResult.fromJson(c as Map<String, dynamic>)).toList();
  }

  String _conditionFromCode(int code) {
    if (code == 0) return 'Slonecznie';
    if (code <= 3) return 'Czesciowe chmury';
    if (code <= 49) return 'Mgla';
    if (code <= 59) return 'Mzawka';
    if (code <= 69) return 'Deszcz';
    if (code <= 79) return 'Snieg';
    if (code <= 82) return 'Przelotny deszcz';
    if (code <= 86) return 'Snieg przelotny';
    if (code <= 99) return 'Burza';
    return 'Nieznana';
  }

  String _iconFromCode(int code) {
    if (code == 0) return 'sunny';
    if (code <= 3) return 'cloud';
    if (code <= 59) return 'foggy';
    if (code <= 69) return 'rainy';
    if (code <= 79) return 'ac_unit';
    if (code <= 82) return 'rainy';
    if (code <= 86) return 'ac_unit';
    if (code <= 99) return 'thunderstorm';
    return 'cloud';
  }
}
