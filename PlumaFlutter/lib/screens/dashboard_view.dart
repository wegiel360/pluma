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
    name: 'Katowice',
    admin1: 'Śląsk',
    country: 'Polska',
    latitude: 50.2649,
    longitude: 19.0238,
  );

  CityResult _location = _default;
  WeatherData? _weather;
  bool _loading = false;
  bool _searching = false;
  String _searchQuery = '';
  List<CityResult> _results = [];
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _refresh = Timer.periodic(const Duration(hours: 1), (_) => _fetchWeather());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    setState(() => _loading = true);
    try {
      final w = await widget.services.weatherApi.getWeather(
        lat: _location.latitude,
        lon: _location.longitude,
        city: _location.displayLabel,
      );
      if (mounted) setState(() => _weather = w);
    } catch (_) {
      // keep previous data
    } finally {
      if (mounted) setState(() => _loading = false);
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
      final r = await widget.services.weatherApi.searchCities(query);
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

  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final w = _weather;
    final color = Theme.of(context).colorScheme.primary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            radius: 28,
            child: _buildWeatherSection(color, w),
          ),
        ),
      ),
    );
  }

  Widget _buildWeatherSection(Color color, WeatherData? w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.cloud, color: PlumaColors.primary, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'pogoda na żywo (odświeżanie co 1h)',
                style: TextStyle(
                  color: PlumaColors.onSurfaceVariant,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            GestureDetector(
              onTap: _loading ? null : _fetchWeather,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white10),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: PlumaColors.primary,
                        ),
                      )
                    : const Icon(Icons.refresh,
                        size: 16, color: PlumaColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: TextField(
            onChanged: _search,
            style:
                const TextStyle(color: PlumaColors.onSurface, fontSize: 12),
            decoration: InputDecoration(
              hintText:
                  'Wpisz nazwę miasta (np. Warszawa, Kraków, Londyn)...',
              hintStyle: TextStyle(
                color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.5),
                fontSize: 12,
              ),
              prefixIcon: const Icon(Icons.search,
                  color: PlumaColors.primary, size: 20),
              suffixIcon: _searching
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: PlumaColors.primary),
                      ),
                    )
                  : _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _search(''),
                        )
                      : null,
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  title: Text(loc.name,
                      style: const TextStyle(
                          color: PlumaColors.onSurface, fontSize: 13)),
                  subtitle: Text(
                    [loc.admin1, loc.country]
                        .where((e) => e != null && e.isNotEmpty)
                        .join(', '),
                    style: const TextStyle(
                        color: PlumaColors.onSurfaceVariant, fontSize: 11),
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
            if (w != null && w.lastUpdated.isNotEmpty)
              Text(
                'Ostatnia zmiana: ${w.lastUpdated}',
                style: TextStyle(
                  color: PlumaColors.onSurfaceVariant.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontFamily: 'monospace',
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
                '${w.temp}\u00B0',
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
                    const Icon(Icons.arrow_upward,
                        size: 14, color: PlumaColors.primary),
                    Text('${w.high}\u00B0',
                        style: const TextStyle(
                            color: PlumaColors.onSurface,
                            fontSize: 16,
                            fontFamily: 'monospace')),
                    const SizedBox(width: 4),
                    const Text('max',
                        style: TextStyle(
                            color: PlumaColors.onSurfaceVariant, fontSize: 10)),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.arrow_downward,
                        size: 14, color: PlumaColors.onSurfaceVariant),
                    Text('${w.low}\u00B0',
                        style: const TextStyle(
                            color: PlumaColors.onSurface,
                            fontSize: 16,
                            fontFamily: 'monospace')),
                    const SizedBox(width: 4),
                    const Text('min',
                        style: TextStyle(
                            color: PlumaColors.onSurfaceVariant, fontSize: 10)),
                  ]),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${w.condition} — ${w.cityName}',
            style: const TextStyle(
              color: PlumaColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _metric('wilgotność', '${w.humidity}%', Icons.water_drop),
              _metric('wiatr', '${w.windSpeed} km/h', Icons.air),
              _metric('ciśnienie', '${w.pressure} hPa', Icons.speed),
            ],
          ),
          const SizedBox(height: 16),

          if (w.hourly.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'prognoza godzinowa 24h',
                        style: TextStyle(
                          color: PlumaColors.onSurfaceVariant,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'przewijaj →',
                        style: TextStyle(
                          color: PlumaColors.primary.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: w.hourly.length,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final f = w.hourly[i];
                        return RepaintBoundary(
                          child: Container(
                            width: 72,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(f.time,
                                    style: const TextStyle(
                                        color: PlumaColors.onSurfaceVariant,
                                        fontSize: 10,
                                        fontFamily: 'monospace')),
                                Icon(_iconFor(f.icon),
                                    color: PlumaColors.primary, size: 20),
                                Text('${f.temp}\u00B0',
                                    style: const TextStyle(
                                        color: PlumaColors.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace')),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.water_drop,
                                        size: 10, color: PlumaColors.primary),
                                    const SizedBox(width: 2),
                                    Text('${f.rainChance}%',
                                        style: TextStyle(
                                            color: PlumaColors.primary
                                                .withValues(alpha: 0.7),
                                            fontSize: 9,
                                            fontFamily: 'monospace')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _metric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
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
      case 'nights_stay':
        return Icons.nights_stay;
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
      case 'grain':
        return Icons.grain;
      case 'partly_cloudy_day':
        return Icons.wb_cloudy;
      default:
        return Icons.wb_cloudy;
    }
  }
}
