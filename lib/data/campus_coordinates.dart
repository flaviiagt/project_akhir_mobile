import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'universities.dart'; // milik tim: class University + kUniversities

/// Koordinat titik kampus utama (perkiraan). Kunci = University.name persis
/// seperti di kUniversities. Cocokkan beberapa titik di Google Maps bila perlu.
const Map<String, LatLng> kCampusCoordinates = {
  'The University of Edinburgh': LatLng(55.9445, -3.1892),
  'University of Manchester': LatLng(53.4668, -2.2339),
  "King's College London": LatLng(51.5115, -0.1160),
  'TU Delft': LatLng(52.0022, 4.3736),
  'Massachusetts Institute of Technology (MIT)': LatLng(42.3601, -71.0942),
  'Imperial College London': LatLng(51.4988, -0.1749),
  'Stanford University': LatLng(37.4275, -122.1697),
  'Harvard University': LatLng(42.3770, -71.1167),
  'University of Oxford': LatLng(51.7548, -1.2544),
  'University of Cambridge': LatLng(52.2043, 0.1186),
  'ETH Zurich': LatLng(47.3763, 8.5480),
  'National University of Singapore (NUS)': LatLng(1.2966, 103.7764),
  'University College London (UCL)': LatLng(51.5246, -0.1340),
  'California Institute of Technology (Caltech)': LatLng(34.1377, -118.1253),
  'The University of Hong Kong (HKU)': LatLng(22.2830, 114.1371),
  'Nanyang Technological University (NTU)': LatLng(1.3483, 103.6831),
  'Peking University': LatLng(39.9869, 116.3056),
  'Tsinghua University': LatLng(40.0003, 116.3264),
  'The Chinese University of Hong Kong (CUHK)': LatLng(22.4196, 114.2068),
  'UNSW Sydney': LatLng(-33.9173, 151.2313),
  'Johns Hopkins University': LatLng(39.3299, -76.6205),
  'University of California, Berkeley': LatLng(37.8719, -122.2585),
  'Technical University of Munich (TUM)': LatLng(48.1497, 11.5679),
  'Yale University': LatLng(41.3163, -72.9223),
  'Cornell University': LatLng(42.4534, -76.4735),
  'University of Pennsylvania': LatLng(39.9522, -75.1932),
};

/// Satu kampus di peta (University milik tim + koordinatnya).
class MapCampus {
  const MapCampus(this.uni, this.point);

  final University uni;
  final LatLng point;

  String get name => uni.name;
  String get city => uni.city;
  String get country => uni.country;
  String get place => uni.place;

  /// "Massachusetts Institute of Technology (MIT)" -> "MIT"
  String get shortName {
    final m = RegExp(r'\(([^)]+)\)').firstMatch(uni.name);
    return m != null ? m.group(1)! : uni.name;
  }
}

/// Semua kampus yang punya koordinat.
List<MapCampus> buildMapCampuses() => [
      for (final u in kUniversities)
        if (kCampusCoordinates[u.name] != null)
          MapCampus(u, kCampusCoordinates[u.name]!),
    ];

/// Skotlandia dikelompokkan ke Inggris pada chip filter.
String chipCountry(String country) =>
    country == 'Skotlandia' ? 'Inggris' : country;

/// Warna bulatan penanda per negara.
Color countryColor(String country) {
  switch (chipCountry(country)) {
    case 'Inggris':
      return const Color(0xFF1B5A8C);
    case 'Amerika Serikat':
      return const Color(0xFFD64545);
    case 'Belanda':
      return const Color(0xFFEF7C00);
    case 'Swiss':
      return const Color(0xFF8C1515);
    case 'Jerman':
      return const Color(0xFF444B55);
    case 'Singapura':
      return const Color(0xFF00696E);
    case 'Hong Kong':
      return const Color(0xFF6B3FA0);
    case 'Tiongkok':
      return const Color(0xFFB8860B);
    case 'Australia':
      return const Color(0xFF1E7A52);
    default:
      return const Color(0xFF4C6075);
  }
}
