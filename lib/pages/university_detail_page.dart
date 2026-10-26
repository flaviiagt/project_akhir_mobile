import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/campus_coordinates.dart';
import '../data/universities.dart';
import '../data/university_profiles.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_map_sheet.dart';
import '../widgets/studytrip_app_bar.dart';

class UniversityDetailPage extends StatelessWidget {
  final University university;

  const UniversityDetailPage({super.key, required this.university});

  @override
  Widget build(BuildContext context) {
    final profile = kUniversityProfiles[university.name]!;
    final imagePath = university.asset;

    return Scaffold(
      backgroundColor: ToolColors.cream,
      appBar: const StudyTripAppBar(title: 'Detail Kampus'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Stack(
              children: [
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: imagePath == null
                      ? _imageFallback()
                      : Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imageFallback(),
                        ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        university.place,
                        style: const TextStyle(
                          color: Color(0xFFFFD27A),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        university.name,
                        style: GoogleFonts.bricolageGrotesque(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionCard(
            title: 'Tentang kampus',
            icon: Icons.account_balance_outlined,
            child: Text(
              profile.introduction,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: ToolColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Bidang studi',
            icon: Icons.auto_stories_outlined,
            child: Text(
              profile.studyAreas,
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: ToolColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Perkiraan biaya hidup',
            icon: Icons.payments_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.monthlyLivingCost} / bulan',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ToolColors.teal,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Kisaran perencanaan untuk akomodasi, makan, dan transportasi. '
                  'Pengeluaran sebenarnya bergantung pada gaya hidup, lokasi '
                  'tempat tinggal, dan pilihan akomodasi.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: ToolColors.slate,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 17,
                        color: ToolColors.brown,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Angka ini hanya estimasi umum kota tujuan, bukan '
                          'angka resmi universitas. Periksa sumber terbaru '
                          'sebelum menyusun anggaran.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: ToolColors.brown,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _sectionCard(
            title: 'Biaya kuliah',
            icon: Icons.school_outlined,
            child: const Text(
              'Biaya kuliah berbeda menurut program, jenjang, dan status '
              'mahasiswa. Cek situs resmi kampus untuk angka dan informasi '
              'beasiswa terbaru.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: ToolColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                final coordinates = kCampusCoordinates[university.name]!;
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => CampusMapSheet(
                    campusName: university.name,
                    locationName: university.place,
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFD7F0F0),
                      child: Icon(Icons.map_outlined, color: ToolColors.teal),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Peta kampus & jarak',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: ToolColors.ink,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Lihat lokasi kampus dan estimasi jarak',
                            style: TextStyle(
                              fontSize: 11,
                              color: ToolColors.slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: ToolColors.teal,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: university.c2,
      alignment: Alignment.center,
      child: Icon(university.icon, color: Colors.white70, size: 52),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ToolColors.navy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: ToolColors.teal),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: ToolColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
