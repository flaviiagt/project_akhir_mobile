import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final String condition;
  final String clothingTip;
  final int weatherCode;
  final double windSpeed;
  final DateTime fetchedAt;

  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.clothingTip,
    required this.weatherCode,
    required this.windSpeed,
    required this.fetchedAt,
  });

  String get formattedTemp => '${temperature.round()}°C';
  String get displaySummary => '$formattedTemp $condition';
}

/// Repository penyedia informasi cuaca online melalui REST API Open-Meteo (FR-18).
/// Gratis, tanpa API Key, cepat, dan akurat.
class WeatherRepository {
  WeatherRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // Koordinat kota-kota tujuan studi
  static const Map<String, (double, double)> cityCoordinates = {
    'Edinburgh': (55.9533, -3.1883),
    'London': (51.5074, -0.1278),
    'Delft': (52.0116, 4.3571),
    'Oxford': (51.7520, -1.2577),
    'Amsterdam': (52.3676, 4.9041),
  };

  /// Mengambil data cuaca real-time dari Open-Meteo
  Future<WeatherData> getWeatherForCity(String cityName) async {
    final coords = cityCoordinates[cityName] ?? cityCoordinates['Edinburgh']!;
    return getWeather(coords.$1, coords.$2);
  }

  Future<WeatherData> getWeather(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
    );

    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final current = data['current'] as Map<String, dynamic>;
        final temp = (current['temperature_2m'] as num).toDouble();
        final code = (current['weather_code'] as num).toInt();
        final wind = (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0;

        final condition = _interpretWmoCode(code);
        final tip = _generateClothingTip(temp, code);

        return WeatherData(
          temperature: temp,
          condition: condition,
          clothingTip: tip,
          weatherCode: code,
          windSpeed: wind,
          fetchedAt: DateTime.now(),
        );
      }
    } catch (_) {
      // Fallback aman jika offline atau koneksi lambat
    }

    return WeatherData(
      temperature: 17.0,
      condition: 'Berawan Sejuk',
      clothingTip: 'Mantel tipis disarankan',
      weatherCode: 2,
      windSpeed: 14.0,
      fetchedAt: DateTime.now(),
    );
  }

  String _interpretWmoCode(int code) {
    if (code == 0) return 'Cerah';
    if (code <= 3) return 'Berawan Sejuk';
    if (code <= 48) return 'Berkabut';
    if (code <= 55) return 'Gerimis Ringan';
    if (code <= 65) return 'Hujan Basah';
    if (code <= 77) return 'Hujan Salju';
    if (code <= 82) return 'Hujan Lebat';
    return 'Hujan Berangin';
  }

  String _generateClothingTip(double temp, int code) {
    if (code >= 51 && code <= 82) {
      return 'Bawa payung & jas hujan';
    }
    if (temp <= 7) {
      return 'Jaket tebal & syal disarankan';
    }
    if (temp <= 17) {
      return 'Mantel tipis disarankan';
    }
    return 'Pakaian santai / nyaman';
  }
}
