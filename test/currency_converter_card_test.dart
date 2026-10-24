import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studytrip/data/currency_repository.dart';
import 'package:studytrip/widgets/currency_converter_card.dart';

class _FakeCurrencyRepository extends CurrencyRepository {
  @override
  Future<RateSnapshot> getRates() async => RateSnapshot(
    rates: const {'USD': 1, 'GBP': 0.8, 'IDR': 16000, 'JPY': 150, 'EUR': 0.9},
    sourceDate: '2026-10-24',
    fetchedAt: DateTime(2026, 10, 24),
  );
}

void main() {
  testWidgets('menampilkan hasil konversi dengan kurs dari repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CurrencyConverterCard(repository: _FakeCurrencyRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('500.000'), findsOneWidget);
    expect(find.textContaining('Sumber:'), findsOneWidget);
    expect(find.text('Aktif'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text('Nonaktif'), findsOneWidget);
  });
}
