import 'package:flutter/material.dart';

/// Daftar kampus tujuan. 4 kampus pertama berasal dari desain Stitch; sisanya
/// kampus papan atas dunia (acuan: QS World University Rankings 2027).
/// Untuk foto sendiri: taruh file di assets/universities/, daftarkan di
/// pubspec.yaml, lalu isi [asset]. Jika [asset] dan [image] kosong/gagal,
/// hero Beranda memakai gradien + ikon dari [c1]/[c2].
/// Catatan: [name] harus unik (dipakai sebagai kunci penyimpanan tujuan).
class University {
  final String name, city, country;
  final String? image; // URL jaringan
  final Color c1, c2;
  final IconData icon;
  const University({
    required this.name,
    required this.city,
    required this.country,
    this.image,
    required this.c1,
    required this.c2,
    this.icon = Icons.account_balance,
  });
  String get place => '$city, $country';
    /// Path foto lokal, otomatis dari tabel _assetNames di bawah.
  String? get asset {
    final f = _assetNames[name];
    return f == null ? null : 'assets/universities/$f.$_assetExt';
  }
}

const kUniversities = <University>[
  // ---- Dari desain Stitch ----
  University(
    name: 'The University of Edinburgh',
    city: 'Edinburgh',
    country: 'Skotlandia',
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuBNCaPewXf8BXyxlrWXkbonUg0qu7rOcDHM_H8YYAcYioS70bRHuEFeVIiip6uuJO6_X-5bfjk-GDmGqAepSF1B2lBPi4Jvq_W6qiK9tJb8C4_qs9TSOqzpZZ0HLcD6uEx6gkAsI6WqeH7pXYGLlB9fCraUXrLVXJPOYxX5MhwarXbp1r1P6iMgZMPVc0QNv8OwQHG0VMJyG2HJSMclAc2itmZmoD1opbOHYq0aiEycO47RHrAOanV-',
    c1: Color(0xFF1E8289),
    c2: Color(0xFF0F2537),
  ),
  University(
    name: 'University of Manchester',
    city: 'Manchester',
    country: 'Inggris',
    image:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuA-bLQgSqIyH-l9gz9ILoHPd4Qw2ihtmwtf7rIgyYrvtgVe77n4Fcnm-Ysbh6B5sKFd_rM5pRDkxJ_zpvVOdVYkTjxSxlf9cg_31OZIZXJUPUaeVQcS1trjibG_sl5xjZHAIZKJjIvdeNQWXbV975WlBht6pfMG4VmOdXT14qPfrvLHc1YC-qn8WGtlnp4H8nA1ZRNZFnqqQN6viNXHlhtwGc_wilhltKTZunB7kkxMAi6awgP7Et0H',
    c1: Color(0xFF8C4D12),
    c2: Color(0xFF2B1A12),
    icon: Icons.apartment,
  ),
  University(
    name: "King's College London",
    city: 'London',
    country: 'Inggris',
    c1: Color(0xFFB02A37),
    c2: Color(0xFF1B1F3B),
    icon: Icons.location_city,
  ),
  University(
    name: 'TU Delft',
    city: 'Delft',
    country: 'Belanda',
    c1: Color(0xFF00A6D6),
    c2: Color(0xFF0C2340),
    icon: Icons.engineering,
  ),

  // ---- Kampus papan atas dunia ----
  University(
    name: 'Massachusetts Institute of Technology (MIT)',
    city: 'Cambridge',
    country: 'Amerika Serikat',
    c1: Color(0xFFA31F34),
    c2: Color(0xFF2B2B2B),
    icon: Icons.engineering,
  ),
  University(
    name: 'Imperial College London',
    city: 'London',
    country: 'Inggris',
    c1: Color(0xFF0F4C9C),
    c2: Color(0xFF0A1F44),
    icon: Icons.science,
  ),
  University(
    name: 'Stanford University',
    city: 'Stanford',
    country: 'Amerika Serikat',
    c1: Color(0xFF8C1515),
    c2: Color(0xFF2E1A1A),
    icon: Icons.school,
  ),
  University(
    name: 'Harvard University',
    city: 'Cambridge',
    country: 'Amerika Serikat',
    c1: Color(0xFFA51C30),
    c2: Color(0xFF1E1E1E),
    icon: Icons.school,
  ),
  University(
    name: 'University of Oxford',
    city: 'Oxford',
    country: 'Inggris',
    c1: Color(0xFF002147),
    c2: Color(0xFF0B3C6F),
    icon: Icons.account_balance,
  ),
  University(
    name: 'University of Cambridge',
    city: 'Cambridge',
    country: 'Inggris',
    c1: Color(0xFF1E6B5C),
    c2: Color(0xFF0E2B30),
    icon: Icons.account_balance,
  ),
  University(
    name: 'ETH Zurich',
    city: 'Zurich',
    country: 'Swiss',
    c1: Color(0xFF1F407A),
    c2: Color(0xFF0D1B33),
    icon: Icons.engineering,
  ),
  University(
    name: 'National University of Singapore (NUS)',
    city: 'Singapura',
    country: 'Singapura',
    c1: Color(0xFFEF7C00),
    c2: Color(0xFF003D7C),
    icon: Icons.location_city,
  ),
  University(
    name: 'University College London (UCL)',
    city: 'London',
    country: 'Inggris',
    c1: Color(0xFF8B1A3C),
    c2: Color(0xFF2A1420),
    icon: Icons.location_city,
  ),
  University(
    name: 'California Institute of Technology (Caltech)',
    city: 'Pasadena',
    country: 'Amerika Serikat',
    c1: Color(0xFFFF6C0C),
    c2: Color(0xFF3A1D0C),
    icon: Icons.science,
  ),
  University(
    name: 'The University of Hong Kong (HKU)',
    city: 'Hong Kong',
    country: 'Hong Kong',
    c1: Color(0xFF1C6B3A),
    c2: Color(0xFF0B2A1A),
    icon: Icons.location_city,
  ),
  University(
    name: 'Nanyang Technological University (NTU)',
    city: 'Singapura',
    country: 'Singapura',
    c1: Color(0xFFC8102E),
    c2: Color(0xFF1A1F3C),
    icon: Icons.engineering,
  ),
  University(
    name: 'Peking University',
    city: 'Beijing',
    country: 'Tiongkok',
    c1: Color(0xFF9B1B1B),
    c2: Color(0xFF2A1414),
    icon: Icons.account_balance,
  ),
  University(
    name: 'Tsinghua University',
    city: 'Beijing',
    country: 'Tiongkok',
    c1: Color(0xFF6A1B9A),
    c2: Color(0xFF1E1233),
    icon: Icons.engineering,
  ),
  University(
    name: 'The Chinese University of Hong Kong (CUHK)',
    city: 'Hong Kong',
    country: 'Hong Kong',
    c1: Color(0xFF7A4B00),
    c2: Color(0xFF2A1B07),
    icon: Icons.school,
  ),
  University(
    name: 'UNSW Sydney',
    city: 'Sydney',
    country: 'Australia',
    c1: Color(0xFFF2C500),
    c2: Color(0xFF2B2A12),
    icon: Icons.apartment,
  ),
  University(
    name: 'Johns Hopkins University',
    city: 'Baltimore',
    country: 'Amerika Serikat',
    c1: Color(0xFF002D72),
    c2: Color(0xFF0B1A38),
    icon: Icons.local_hospital,
  ),
  University(
    name: 'University of California, Berkeley',
    city: 'Berkeley',
    country: 'Amerika Serikat',
    c1: Color(0xFF003262),
    c2: Color(0xFF3B2F0A),
    icon: Icons.school,
  ),
  University(
    name: 'Technical University of Munich (TUM)',
    city: 'Munich',
    country: 'Jerman',
    c1: Color(0xFF0065BD),
    c2: Color(0xFF0A1F33),
    icon: Icons.engineering,
  ),
  University(
    name: 'Yale University',
    city: 'New Haven',
    country: 'Amerika Serikat',
    c1: Color(0xFF00356B),
    c2: Color(0xFF0B1630),
    icon: Icons.account_balance,
  ),
  University(
    name: 'Cornell University',
    city: 'Ithaca',
    country: 'Amerika Serikat',
    c1: Color(0xFFB31B1B),
    c2: Color(0xFF2A1414),
    icon: Icons.school,
  ),
  University(
    name: 'University of Pennsylvania',
    city: 'Philadelphia',
    country: 'Amerika Serikat',
    c1: Color(0xFF011F5B),
    c2: Color(0xFF7A1020),
    icon: Icons.account_balance,
  ),
];

/// Cocokkan teks tujuan tersimpan (nama kampus, atau data lama seperti
/// "Edinburgh, Britania Raya") ke daftar kampus.
University? findUniversity(String? s) {
  if (s == null || s.trim().isEmpty) return null;
  final t = s.toLowerCase();
  for (final u in kUniversities) {
    if (u.name.toLowerCase() == t) return u;
  }
  for (final u in kUniversities) {
    if (t.contains(u.city.toLowerCase())) return u;
  }
  return null;
}

/// Ekstensi file foto di assets/universities/ (ubah ke 'jpeg' kalau file-mu .jpeg).
const _assetExt = 'jpeg';

/// Nama kampus -> nama file (tanpa ekstensi).
const _assetNames = <String, String>{
  'The University of Edinburgh': 'edinburgh',
  'University of Manchester': 'manchester',
  "King's College London": 'kingscollege',
  'TU Delft': 'delft',
  'Massachusetts Institute of Technology (MIT)': 'mit',
  'Imperial College London': 'imperial',
  'Stanford University': 'stanford',
  'Harvard University': 'harvard',
  'University of Oxford': 'oxford',
  'University of Cambridge': 'cambridge',
  'ETH Zurich': 'zurich',
  'National University of Singapore (NUS)': 'nus',
  'University College London (UCL)': 'ucl',
  'California Institute of Technology (Caltech)': 'caltech',
  'The University of Hong Kong (HKU)': 'hku',
  'Nanyang Technological University (NTU)': 'ntu',
  'Peking University': 'peking',
  'Tsinghua University': 'tsinghua',
  'The Chinese University of Hong Kong (CUHK)': 'chineseuniv',
  'UNSW Sydney': 'unsw',
  'Johns Hopkins University': 'hopkins',
  'University of California, Berkeley': 'california',
  'Technical University of Munich (TUM)': 'tum',
  'Yale University': 'yale',
  'Cornell University': 'cornell',
  'University of Pennsylvania': 'pennsylvania',
};