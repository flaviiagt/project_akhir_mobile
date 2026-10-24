import 'package:flutter/material.dart';

/// Satu nomor darurat (mis. Polisi -> 999).
class EmergencyNumber {
  final String label;
  final String number;
  final IconData icon;
  const EmergencyNumber(this.label, this.number, this.icon);
}

/// Kumpulan nomor darurat untuk satu negara tujuan.
/// [countries] harus sama persis dengan field `country` di universities.dart.
class CountryEmergency {
  final String title;
  final List<String> countries;
  final List<EmergencyNumber> numbers;
  const CountryEmergency({
    required this.title,
    required this.countries,
    required this.numbers,
  });
}

const _general = Icons.emergency_outlined;
const _police = Icons.local_police_outlined;
const _ambulance = Icons.medical_services_outlined;
const _fire = Icons.local_fire_department_outlined;

/// Data offline. Sumber: daftar nomor darurat publik (Wikipedia "List of
/// emergency telephone numbers", daftar US State Dept / universitas).

const kEmergencyList = <CountryEmergency>[
  CountryEmergency(
    title: 'Inggris & Skotlandia',
    countries: ['Inggris', 'Skotlandia'],
    numbers: [
      EmergencyNumber('Polisi / Ambulans / Pemadam', '999', _general),
      EmergencyNumber('Alternatif (dari ponsel)', '112', _general),
    ],
  ),
  CountryEmergency(
    title: 'Belanda',
    countries: ['Belanda'],
    numbers: [
      EmergencyNumber('Darurat umum', '112', _general),
    ],
  ),
  CountryEmergency(
    title: 'Amerika Serikat',
    countries: ['Amerika Serikat'],
    numbers: [
      EmergencyNumber('Polisi / Ambulans / Pemadam', '911', _general),
    ],
  ),
  CountryEmergency(
    title: 'Swiss',
    countries: ['Swiss'],
    numbers: [
      EmergencyNumber('Darurat umum', '112', _general),
      EmergencyNumber('Polisi', '117', _police),
      EmergencyNumber('Pemadam', '118', _fire),
      EmergencyNumber('Ambulans', '144', _ambulance),
    ],
  ),
  CountryEmergency(
    title: 'Singapura',
    countries: ['Singapura'],
    numbers: [
      EmergencyNumber('Polisi', '999', _police),
      EmergencyNumber('Ambulans & Pemadam', '995', _ambulance),
    ],
  ),
  CountryEmergency(
    title: 'Hong Kong',
    countries: ['Hong Kong'],
    numbers: [
      EmergencyNumber('Polisi / Ambulans / Pemadam', '999', _general),
    ],
  ),
  CountryEmergency(
    title: 'Tiongkok',
    countries: ['Tiongkok'],
    numbers: [
      EmergencyNumber('Polisi', '110', _police),
      EmergencyNumber('Ambulans', '120', _ambulance),
      EmergencyNumber('Pemadam', '119', _fire),
    ],
  ),
  CountryEmergency(
    title: 'Australia',
    countries: ['Australia'],
    numbers: [
      EmergencyNumber('Polisi / Ambulans / Pemadam', '000', _general),
      EmergencyNumber('Alternatif (dari ponsel)', '112', _general),
    ],
  ),
  CountryEmergency(
    title: 'Jerman',
    countries: ['Jerman'],
    numbers: [
      EmergencyNumber('Polisi', '110', _police),
      EmergencyNumber('Ambulans & Pemadam', '112', _ambulance),
    ],
  ),
];

/// Indeks di [kEmergencyList] untuk nama negara, atau -1 jika tidak ada.
int emergencyIndexForCountry(String? country) {
  if (country == null) return -1;
  return kEmergencyList.indexWhere((e) => e.countries.contains(country));
}