import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:studytrip/data/campus_coordinates.dart';
import 'package:studytrip/data/universities.dart';
import 'package:studytrip/logic/geo_utils.dart';
import 'package:studytrip/widgets/campus_map_sheet.dart';

void main() {
  test('semua kampus di kUniversities punya koordinat valid', () {
    for (final u in kUniversities) {
      final p = kCampusCoordinates[u.name];
      expect(p, isNotNull, reason: 'Koordinat belum ada: ${u.name}');
      expect(p!.latitude, inInclusiveRange(-90, 90));
      expect(p.longitude, inInclusiveRange(-180, 180));
    }
  });

  test('jarak Jakarta ke London sekitar 11.700 km', () {
    const jakarta = LatLng(-6.2088, 106.8456);
    const london = LatLng(51.5074, -0.1278);
    expect(haversineKm(jakarta, london), inInclusiveRange(11500, 11900));
  });

  test('jarak dua titik yang sama adalah nol', () {
    const p = LatLng(-7.78, 110.36);
    expect(haversineKm(p, p), closeTo(0, 0.001));
  });

  test('busur Jakarta-London: satu segmen, ujung sesuai', () {
    const jakarta = LatLng(-6.2088, 106.8456);
    const london = LatLng(51.5074, -0.1278);
    final arc = greatCircleArc(jakarta, london);
    expect(arc.length, 1);
    expect(arc.first.first.latitude, jakarta.latitude);
    expect(arc.last.last.longitude, london.longitude);
  });

  test('busur Jakarta-Stanford menerus melewati garis bujur 180', () {
    const jakarta = LatLng(-6.2088, 106.8456);
    final stanford = kCampusCoordinates['Stanford University']!;
    final arc = greatCircleArc(jakarta, stanford);
    expect(arc.length, 1);
    for (var i = 1; i < arc.single.length; i++) {
      expect(
        (arc.single[i].longitude - arc.single[i - 1].longitude).abs(),
        lessThan(180),
      );
    }
    expect(arc.single.last.longitude, closeTo(stanford.longitude + 360, 0.001));
  });

  test('format estimasi waktu terbang', () {
    expect(flightDurationText(850), '1j 0m');
    expect(flightDurationText(425), '30m');
  });

  test('kampus sekota dikenali (London punya 3)', () {
    final london = buildMapCampuses().where((c) => c.city == 'London');
    expect(london.length, 3);
  });

  testWidgets('tombol peta lengkap dari LBS membuka halaman peta dunia', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const CampusMapSheet(
                  campusName: 'The University of Edinburgh',
                  locationName: 'Edinburgh, UK',
                  latitude: 55.9445,
                  longitude: -3.1892,
                ),
              ),
              child: const Text('Buka LBS'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka LBS'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Buka Peta Dunia Lengkap'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(find.text('Peta Kampus Dunia'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
