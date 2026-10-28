import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studytrip/data/weather_repository.dart';
import 'package:studytrip/widgets/weather_card.dart';

class _FakeWeatherRepository extends WeatherRepository {
  _FakeWeatherRepository(this.result);

  final WeatherData result;
  String? requestedCity;

  @override
  Future<WeatherData> getWeatherForCity(String cityName) async {
    requestedCity = cityName;
    return result;
  }

  @override
  void close() {}
}

void main() {
  testWidgets('menampilkan cuaca kampus tujuan dari repository', (
    tester,
  ) async {
    final repository = _FakeWeatherRepository(
      WeatherData(
        temperature: 12.4,
        condition: 'Cerah',
        clothingTip: 'Mantel tipis disarankan',
        weatherCode: 0,
        relativeHumidity: 72,
        windSpeed: 8,
        fetchedAt: DateTime(2026, 10, 28),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeatherCard(
            destinationCity: 'Edinburgh',
            repository: repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedCity, 'Edinburgh');
    expect(find.text('12°C'), findsOneWidget);
    expect(find.text('Cerah'), findsOneWidget);
    expect(find.text('Kelembapan 72%'), findsOneWidget);
    expect(find.text('Mantel tipis disarankan'), findsOneWidget);
  });

  testWidgets('meminta pengguna memilih kota yang didukung', (tester) async {
    final repository = _FakeWeatherRepository(
      WeatherData(
        temperature: 12,
        condition: 'Cerah',
        clothingTip: 'Pakaian nyaman',
        weatherCode: 0,
        relativeHumidity: 72,
        windSpeed: 8,
        fetchedAt: DateTime(2026, 10, 28),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeatherCard(
            destinationCity: 'Cambridge',
            repository: repository,
          ),
        ),
      ),
    );

    expect(repository.requestedCity, isNull);
    expect(
      find.text('Pilih kota untuk melihat cuaca dan saran pakaian.'),
      findsOneWidget,
    );
  });
}
