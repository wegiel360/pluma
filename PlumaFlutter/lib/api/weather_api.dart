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

class HourlyForecast {
  final String time;
  final int temp;
  final String icon;
  final int rainChance;

  const HourlyForecast({
    required this.time,
    required this.temp,
    required this.icon,
    required this.rainChance,
  });
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
  final List<HourlyForecast> hourly;
  final String lastUpdated;

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
    this.hourly = const [],
    this.lastUpdated = '',
  });
}

class WeatherApi {
  Future<WeatherData> getWeather({
    double? lat,
    double? lon,
    String? city,
  }) async {
    final latitude = lat ?? 49.9542;
    final longitude = lon ?? 18.5833;

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,surface_pressure'
      '&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,weather_code'
      '&daily=temperature_2m_max,temperature_2m_min'
      '&timezone=auto&forecast_days=2',
    );

    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Bledne dane pogodowe');

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>? ?? {};
    final daily = data['daily'] as Map<String, dynamic>? ?? {};
    final hourly = data['hourly'] as Map<String, dynamic>? ?? {};

    final code = (current['weather_code'] ?? 0) as int;
    final currentHour = DateTime.now().hour;
    final isNight = currentHour >= 22 || currentHour < 5;
    final condition = _conditionFromCode(code);
    final icon = _iconFromCode(code, isNight);

    final tempsMax = daily['temperature_2m_max'] as List?;
    final tempsMin = daily['temperature_2m_min'] as List?;

    final hourlyList = _buildHourlyForecast(hourly);

    final h = DateTime.now().hour.toString().padLeft(2, '0');
    final m = DateTime.now().minute.toString().padLeft(2, '0');

    return WeatherData(
      cityName: city ?? 'Jastrzebie-Zdroj, Slask',
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
      hourly: hourlyList,
      lastUpdated: '$h:$m',
    );
  }

  List<HourlyForecast> _buildHourlyForecast(Map<String, dynamic> hourly) {
    final times = (hourly['time'] as List?)?.cast<String>() ?? [];
    final temps = (hourly['temperature_2m'] as List?) ?? [];
    final rainChances = (hourly['precipitation_probability'] as List?) ?? [];
    final codes = (hourly['weather_code'] as List?) ?? [];

    final nowIso = DateTime.now().toIso8601String().substring(0, 13);
    var startIndex = times.indexWhere((t) => t.startsWith(nowIso));
    if (startIndex == -1) startIndex = 0;

    final list = <HourlyForecast>[];
    for (var i = 0; i < 24; i++) {
      final idx = startIndex + i;
      if (idx >= times.length) break;
      final tDate = DateTime.parse(times[idx]);
      final hVal = tDate.hour;
      final itemNight = hVal >= 22 || hVal < 5;
      final itemCode = idx < codes.length ? (codes[idx] as num).round() : 0;

      list.add(HourlyForecast(
        time: i == 0 ? 'teraz' : '${hVal.toString().padLeft(2, '0')}:00',
        temp: idx < temps.length ? (temps[idx] as num).round() : 20,
        icon: _iconFromCode(itemCode, itemNight),
        rainChance:
            idx < rainChances.length ? (rainChances[idx] as num).round() : 0,
      ));
    }
    return list;
  }

  Future<List<CityResult>> searchCities(String query) async {
    final q = Uri.encodeComponent(query.trim());
    final uri = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=$q&count=5&language=pl&format=json',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final results = data['results'] as List? ?? [];
    return results
        .map((c) => CityResult.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  String _conditionFromCode(int code) {
    switch (code) {
      case 0:
        return 'Bezchmurnie';
      case 1:
        return 'Słonecznie';
      case 2:
        return 'Częściowe zachmurzenie';
      case 3:
        return 'Pochmurno';
      case 45:
      case 48:
        return 'Mgła';
      case 51:
      case 53:
      case 55:
        return 'Mżawka';
      case 61:
      case 63:
      case 65:
        return 'Deszcz';
      case 71:
      case 73:
      case 75:
        return 'Opady śniegu';
      case 80:
      case 81:
      case 82:
        return 'Przelotny deszcz';
      case 95:
      case 96:
      case 99:
        return 'Burza';
      default:
        return 'Umiarkowanie';
    }
  }

  String _iconFromCode(int code, bool isNight) {
    switch (code) {
      case 0:
      case 1:
        return isNight ? 'nights_stay' : 'sunny';
      case 2:
        return isNight ? 'nights_stay' : 'partly_cloudy_day';
      case 3:
        return 'cloud';
      case 45:
      case 48:
        return 'foggy';
      case 51:
      case 53:
      case 55:
        return 'grain';
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return 'rainy';
      case 71:
      case 73:
      case 75:
        return 'ac_unit';
      case 95:
      case 96:
      case 99:
        return 'thunderstorm';
      default:
        return 'partly_cloudy_day';
    }
  }
}
