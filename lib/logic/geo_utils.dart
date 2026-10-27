import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

double _rad(double d) => d * math.pi / 180.0;
double _deg(double r) => r * 180.0 / math.pi;

/// Jarak lingkaran-besar (km) antara dua koordinat (rumus haversine).
double haversineKm(LatLng a, LatLng b) {
  const r = 6371.0088;
  final dLat = _rad(b.latitude - a.latitude);
  final dLon = _rad(b.longitude - a.longitude);
  final sLat = math.sin(dLat / 2);
  final sLon = math.sin(dLon / 2);
  final h = sLat * sLat +
      math.cos(_rad(a.latitude)) * math.cos(_rad(b.latitude)) * sLon * sLon;
  return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
}

/// Busur lingkaran-besar dari [a] ke [b] sebagai SATU garis menerus.
///
/// Bujur sengaja "tidak dibungkus" (boleh lewat 180 atau -180). Contoh:
/// Depok (107) -> Berkeley (-122) menjadi 107 ... 180 ... 238. Dengan begitu
/// garis tidak patah di tepi peta dan kamera cukup memuat selisih bujur
/// terpendek, sehingga kedua ujung rute muat di layar tanpa menggeser peta.
///
/// Tipe kembalian tetap List<List<LatLng>> agar kompatibel dengan halaman peta.
List<List<LatLng>> greatCircleArc(LatLng a, LatLng b, {int steps = 96}) {
  final lat1 = _rad(a.latitude), lon1 = _rad(a.longitude);
  final lat2 = _rad(b.latitude), lon2 = _rad(b.longitude);

  final sLat = math.sin((lat2 - lat1) / 2);
  final sLon = math.sin((lon2 - lon1) / 2);
  final d = 2 *
      math.asin(math.min(
          1.0,
          math.sqrt(sLat * sLat +
              math.cos(lat1) * math.cos(lat2) * sLon * sLon)));
  if (d < 1e-9) {
    return [
      [a, b]
    ];
  }

  final pts = <LatLng>[];
  var prevLon = a.longitude;
  for (var i = 0; i <= steps; i++) {
    final f = i / steps;
    final k1 = math.sin((1 - f) * d) / math.sin(d);
    final k2 = math.sin(f * d) / math.sin(d);
    final x = k1 * math.cos(lat1) * math.cos(lon1) +
        k2 * math.cos(lat2) * math.cos(lon2);
    final y = k1 * math.cos(lat1) * math.sin(lon1) +
        k2 * math.cos(lat2) * math.sin(lon2);
    final z = k1 * math.sin(lat1) + k2 * math.sin(lat2);

    final lat = _deg(math.atan2(z, math.sqrt(x * x + y * y)));
    var lon = _deg(math.atan2(y, x));

    // Buka lipatan bujur: pilih nilai (lon +/- 360) yang terdekat dengan
    // titik sebelumnya, sehingga garis kontinu.
    while (lon - prevLon > 180) {
      lon -= 360;
    }
    while (lon - prevLon < -180) {
      lon += 360;
    }
    prevLon = lon;
    pts.add(LatLng(lat, lon));
  }

  // Ujung busur dibuat persis sama dengan titik asal dan tujuan
  // (bujur tujuan tetap versi yang sudah dibuka lipatannya).
  pts[0] = a;
  pts[pts.length - 1] = LatLng(b.latitude, pts.last.longitude);
  return [pts];
}

/// Estimasi waktu terbang kasar (kecepatan rata-rata 850 km/jam, tanpa transit).
String flightDurationText(double km) {
  final minutes = (km / 850 * 60).round();
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0 ? '${h}j ${m}m' : '${m}m';
}