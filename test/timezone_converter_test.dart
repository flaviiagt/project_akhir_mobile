import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studytrip/data/universities.dart';
import 'package:studytrip/widgets/timezone_converter_card.dart';

void main() {
  test('setiap kampus memiliki zona waktu yang dikenali', () {
    for (final university in kUniversities) {
      final zone = destinationZoneForProgram(university.name);
      expect(
        zone,
        isNotNull,
        reason: 'Zona waktu belum ada: ${university.name}',
      );
      expect(
        destinationTimeAt(zone!, DateTime.utc(2026, 1, 15)).timeZoneOffset,
        isNotNull,
      );
    }
  });

  test('London selalu menjadi pilihan default dan pilihan pertama', () {
    expect(destinationZonesForProgram(null), [kLondonDestZone]);
    expect(
      destinationZonesForProgram('University of Manchester').first,
      kLondonDestZone,
    );
  });

  test('kampus tujuan menambahkan kota kampusnya ke pilihan London', () {
    final zones = destinationZonesForProgram('Stanford University');

    expect(zones.map((zone) => zone.city), ['London', 'Stanford']);
    expect(zones.last.timeZoneId, 'America/Los_Angeles');
  });

  test('kota bernama sama memakai zona waktu kampus yang benar', () {
    final mit = destinationZoneForProgram(
      'Massachusetts Institute of Technology (MIT)',
    );
    final cambridge = destinationZoneForProgram('University of Cambridge');

    expect(mit?.timeZoneId, 'America/New_York');
    expect(cambridge?.timeZoneId, 'Europe/London');
  });

  test('perbedaan musim panas dan dingin dihitung sesuai zona kota', () {
    final london = destinationZoneForProgram('The University of Edinburgh')!;

    expect(
      destinationTimeAt(
        london,
        DateTime.utc(2026, 1, 15),
      ).timeZoneOffset.inHours,
      0,
    );
    expect(
      destinationTimeAt(
        london,
        DateTime.utc(2026, 7, 15),
      ).timeZoneOffset.inHours,
      1,
    );
  });

  testWidgets('pilihan kota mengikuti kampus profil dengan London default', (
    tester,
  ) async {
    var program = 'Stanford University';
    late StateSetter updateProgram;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateProgram = setState;
            return Scaffold(
              body: TimezoneConverterCard(destinationProgram: program),
            );
          },
        ),
      ),
    );
    await tester.pump();

    final londonChip = find.widgetWithText(ChoiceChip, 'London');
    final stanfordChip = find.widgetWithText(ChoiceChip, 'Stanford');
    expect(tester.widget<ChoiceChip>(londonChip).selected, isTrue);
    expect(tester.widget<ChoiceChip>(stanfordChip).selected, isFalse);

    await tester.tap(stanfordChip);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(stanfordChip).selected, isTrue);

    updateProgram(() => program = 'The University of Edinburgh');
    await tester.pump();
    expect(find.widgetWithText(ChoiceChip, 'Stanford'), findsNothing);
    expect(tester.widget<ChoiceChip>(londonChip).selected, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
