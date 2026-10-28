import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:studytrip/data/weather_repository.dart';

void main() {
  test('membaca kondisi cuaca dari respons Open-Meteo', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'api.open-meteo.com');
      return http.Response(
        jsonEncode({
          'current': {
            'temperature_2m': 12.4,
            'relative_humidity_2m': 72,
            'weather_code': 0,
            'wind_speed_10m': 8.0,
          },
        }),
        200,
      );
    });
    final repository = WeatherRepository(client: client);
    addTearDown(repository.close);

    final weather = await repository.getWeatherForCity('Edinburgh');

    expect(weather.temperature, 12.4);
    expect(weather.condition, 'Cerah');
    expect(weather.relativeHumidity, 72);
    expect(weather.windSpeed, 8);
    expect(weather.clothingTip, 'Mantel tipis disarankan');
  });

  test('melempar error untuk kota yang tidak didukung', () async {
    final repository = WeatherRepository(
      client: MockClient((_) async => http.Response('', 200)),
    );
    addTearDown(repository.close);

    expect(
      () => repository.getWeatherForCity('Cambridge'),
      throwsArgumentError,
    );
  });

  test('tidak mengganti kegagalan API dengan data cuaca contoh', () async {
    final repository = WeatherRepository(
      client: MockClient((_) async => http.Response('Unavailable', 503)),
    );
    addTearDown(repository.close);

    expect(
      () => repository.getWeather(55.9533, -3.1883),
      throwsA(isA<http.ClientException>()),
    );
  });
}
