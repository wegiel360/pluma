import 'api_client.dart';

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
  final ApiClient _client;

  WeatherApi(this._client);

  Future<WeatherData> getWeather({double? lat, double? lon, String? city}) async {
    final params = <String>[];
    if (lat != null) params.add('lat=$lat');
    if (lon != null) params.add('lon=$lon');
    if (city != null) params.add('city=${Uri.encodeComponent(city)}');
    final suffix = params.isEmpty ? '' : '?${params.join('&')}';
    final res = await _client.get('/weather$suffix');
    return WeatherData.fromJson(res);
  }

  Future<List<CityResult>> searchCities(String query) async {
    final q = Uri.encodeComponent(query.trim());
    final res = await _client.get('/weather/search?q=$q');
    final list = (res['results'] as List? ?? []);
    return list
        .map((c) => CityResult.fromJson(c as Map<String, dynamic>))
        .toList();
  }
}
