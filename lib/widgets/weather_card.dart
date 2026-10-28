import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/weather_repository.dart';
import '../theme/app_theme.dart';

class WeatherCard extends StatefulWidget {
  final String? destinationCity;
  final WeatherRepository? repository;

  const WeatherCard({super.key, this.destinationCity, this.repository});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  late WeatherRepository _repository;
  bool _ownsRepository = false;
  String? _selectedCity;
  WeatherData? _weather;
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  List<String> get _cities => WeatherRepository.cityCoordinates.keys.toList();

  @override
  void initState() {
    super.initState();
    _setRepository(widget.repository);
    _selectedCity = _supportedDestinationCity;
    if (_selectedCity != null) _loadWeather();
  }

  @override
  void didUpdateWidget(covariant WeatherCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final destinationChanged =
        oldWidget.destinationCity != widget.destinationCity;
    if (oldWidget.repository != widget.repository) {
      if (_ownsRepository) _repository.close();
      _setRepository(widget.repository);
    }
    if (destinationChanged) {
      _selectedCity = _supportedDestinationCity;
      _weather = null;
      if (_selectedCity != null) {
        _loadWeather();
      } else {
        _requestId++;
        _loading = false;
        _error = null;
      }
    } else if (oldWidget.repository != widget.repository &&
        _selectedCity != null) {
      _loadWeather();
    }
  }

  String? get _supportedDestinationCity {
    final city = widget.destinationCity;
    return city != null && WeatherRepository.cityCoordinates.containsKey(city)
        ? city
        : null;
  }

  void _setRepository(WeatherRepository? repository) {
    _ownsRepository = repository == null;
    _repository = repository ?? WeatherRepository();
  }

  Future<void> _loadWeather() async {
    final city = _selectedCity;
    if (city == null) return;
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final weather = await _repository.getWeatherForCity(city);
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _weather = weather;
        _loading = false;
      });
    } on Exception {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _weather = null;
        _loading = false;
        _error = 'Gagal memuat cuaca. Periksa koneksi internet lalu coba lagi.';
      });
    }
  }

  void _selectCity(String? city) {
    if (city == null || city == _selectedCity) return;
    setState(() {
      _selectedCity = city;
      _weather = null;
    });
    _loadWeather();
  }

  @override
  void dispose() {
    _requestId++;
    if (_ownsRepository) _repository.close();
    super.dispose();
  }

  IconData _weatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_outlined;
    if (code <= 3) return Icons.cloud_outlined;
    if (code <= 48) return Icons.foggy;
    if (code <= 67 || (code >= 80 && code <= 82)) {
      return Icons.umbrella_outlined;
    }
    if (code <= 77) return Icons.ac_unit;
    return Icons.thunderstorm_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: kNavy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: DefaultTextStyle.merge(
        style: GoogleFonts.beVietnamPro(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, color: kTertiary),
                const SizedBox(width: 8),
                Text('Cuaca Tujuan', style: headlineStyle(17, color: kNavy)),
                const Spacer(),
                if (_selectedCity != null)
                  IconButton(
                    tooltip: 'Muat ulang cuaca',
                    onPressed: _loading ? null : _loadWeather,
                    icon: const Icon(Icons.refresh),
                    color: kPrimary,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              decoration: const InputDecoration(
                labelText: 'Kota tujuan',
                isDense: true,
              ),
              hint: const Text('Pilih kota'),
              items: _cities
                  .map(
                    (city) => DropdownMenuItem(value: city, child: Text(city)),
                  )
                  .toList(),
              onChanged: _selectCity,
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cloud_off_outlined, color: kDanger),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: kDanger),
                    ),
                  ),
                ],
              )
            else if (_weather != null)
              _buildWeatherDetails(_weather!)
            else
              const Text(
                'Pilih kota untuk melihat cuaca dan saran pakaian.',
                style: TextStyle(color: kSecondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetails(WeatherData weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_weatherIcon(weather.weatherCode), color: kTertiary, size: 36),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.formattedTemp,
                  style: headlineStyle(28, color: kNavy),
                ),
                Text(
                  weather.condition,
                  style: const TextStyle(color: kSecondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.air, size: 18, color: kSecondary),
            const SizedBox(width: 6),
            Text('Angin ${weather.windSpeed.round()} km/jam'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.water_drop_outlined, size: 18, color: kSecondary),
            const SizedBox(width: 6),
            Text('Kelembapan ${weather.relativeHumidity}%'),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.checkroom_outlined, size: 18, color: kPrimary),
            const SizedBox(width: 6),
            Expanded(child: Text(weather.clothingTip)),
          ],
        ),
      ],
    );
  }
}
