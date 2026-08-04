import 'dart:async';

import 'package:flutter/material.dart';

import '../api/weather_api.dart';
import '../main.dart';
import '../theme/glass_components.dart';
import '../theme/pluma_theme.dart';

class DashboardView extends StatefulWidget {
  final AppServices services;
  const DashboardView({super.key, required this.services});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  static const _default = CityResult(
    name: 'Jastrzebie-Zdroj',
    admin1: 'Slask',
    country: 'Polska',
    latitude: 49.9542,
    longitude: 18.5833,
  );

  CityResult _location = _default;
  WeatherData? _weather;
  bool _searching = false;
  String _searchQuery = '';
  List<CityResult> _results = [];
  DateTime _now = DateTime.now();
  Timer? _clock;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
    _fetchWeather();
    _refresh = Timer.periodic(const Duration(hours: 1), (_) => _fetchWeather());
  }

  @override
  void dispose() {
    _clock?.cancel();
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    try {
      final w = await widget.services.api.weatherApi.getWeather(
        lat: _location.latitude,
        lon: _location.longitude,
      );
      if (mounted) setState(() => _weather = w);
    } catch (_) {
      // keep previous data
    }
  }

  Future<void> _search(String query) async {
    setState(() => _searchQuery = query);
    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final r = await widget.services.api.weatherApi.searchCities(query);
      if (mounted) setState(() => _results = r);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectCity(CityResult loc) {
    setState(() {
      _location = loc;
      _searchQuery = '';
      _results = [];
    });
    _fetchWeather();
  }

  String _time(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final w = _weather;
    final color = Theme.of(context).colorScheme.primary;
    final timeStr = '${_time(_now.hour)}:${_time(_now.minute)}:${_time(_now.second)}';

    const days = [
      'niedziela', 'poniedzialek', 'wtorek', 'sroda', 'czwartek', 'piatek', 'sobota'
    ];
    const months = [
      'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
      'lipca', 'sierpnia', 'wrzesnia', 'pazdziernika', 'listopada', 'grudnia'
    ];
    final dateStr = '${_now.day} ${months[_now.month - 1]} ${_now.year}';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          radius: 28,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.cloud, color: PlumaColors.primary, size: 24),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'pogoda na zywo (odswiezanie co 1h)',
                      style: TextStyle(
                        color: PlumaColors.onSurfaceVariant,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x1A4ADE80),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x334ADE80)),
                    ),
                    child: Text(
                      timeStr,
                      style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 11,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // City search
              TextField(
                onChanged: _search,
                style: const TextStyle(color: PlumaColors.onSurface, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Wpisz nazwe miasta (np. Warszawa, Katowice, Londyn)...',
                  hintStyle: TextStyle(
                    color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(Icons.search, color: PlumaColors.primary, size: 20),
                  suffixIcon: _searching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: PlumaColors.primary,
                            ),
                          ),
                        )
                      : _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => _search(''),
                            )
                          : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: color.withValues(alpha: 0.5)),
                  ),
                ),
              ),
              if (_results.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xE60C2500),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: _results.map((loc) {
                      return ListTile(
                        dense: true,
                        title: Text(
                          loc.name,
                          style: const TextStyle(color: PlumaColors.onSurface, fontSize: 13),
                        ),
                        subtitle: Text(
                          [loc.admin1, loc.country].where((e) => e != null && e.isNotEmpty).join(', '),
                          style: const TextStyle(color: PlumaColors.onSurfaceVariant, fontSize: 11),
                        ),
                        onTap: () => _selectCity(loc),
                      );
                    }).toList(),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, color: PlumaColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      w?.cityName ?? _location.displayLabel,
                      style: const TextStyle(
                        color: PlumaColors.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (w != null) ...[
                Row(
                  children: [
                    Icon(w.icon.isEmpty ? Icons.wb_sunny : _iconFor(w.icon),
                        color: color, size: 56),
                    const SizedBox(width: 16),
                    Text(
                      '${w.temp}°',
                      style: const TextStyle(
                        color: PlumaColors.onSurface,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.arrow_upward, size: 14, color: PlumaColors.primary),
                          Text('${w.high}°', style: const TextStyle(color: PlumaColors.onSurface, fontSize: 16, fontFamily: 'monospace')),
                          const SizedBox(width: 4),
                          const Text('max', style: TextStyle(color: PlumaColors.onSurfaceVariant, fontSize: 10)),
                        ]),
                        const SizedBox(height: 4),
                        Row(children: [
                          const Icon(Icons.arrow_downward, size: 14, color: PlumaColors.onSurfaceVariant),
                          Text('${w.low}°', style: const TextStyle(color: PlumaColors.onSurface, fontSize: 16, fontFamily: 'monospace')),
                          const SizedBox(width: 4),
                          const Text('min', style: TextStyle(color: PlumaColors.onSurfaceVariant, fontSize: 10)),
                        ]),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${w.condition} - ${w.cityName}',
                  style: const TextStyle(
                    color: PlumaColors.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                // Metrics
                Row(
                  children: [
                    _metric('wilgotnosc', '${w.humidity}%', Icons.water_drop),
                    _metric('wiatr', '${w.windSpeed} km/h', Icons.air),
                    _metric('cisnienie', '${w.pressure} hPa', Icons.speed),
                  ],
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 16),

              // Clock
              GlassCard(
                padding: const EdgeInsets.all(16),
                radius: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_time(_now.hour)}:${_time(_now.minute)}',
                          style: const TextStyle(
                            color: PlumaColors.onSurface,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                        Text(
                          _time(_now.second),
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          days[_now.weekday % 7],
                          style: TextStyle(
                            color: color,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: PlumaColors.onSurfaceVariant,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: PlumaColors.primary, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    color: PlumaColors.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace')),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: PlumaColors.onSurfaceVariant, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String icon) {
    switch (icon) {
      case 'sunny':
        return Icons.wb_sunny;
      case 'rainy':
        return Icons.umbrella;
      case 'cloud':
        return Icons.cloud;
      case 'foggy':
        return Icons.foggy;
      case 'thunderstorm':
        return Icons.thunderstorm;
      case 'ac_unit':
        return Icons.ac_unit;
      default:
        return Icons.wb_cloudy;
    }
  }
}
