import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/currency_converter_card.dart';
import '../widgets/emergency_shortcut_card.dart';
import '../widgets/gyroscope_compass_card.dart';
import '../widgets/studybuddy_ai_card.dart';
import '../widgets/studytrip_app_bar.dart';
import '../widgets/timezone_converter_card.dart';

/// Halaman Alat & Utilitas: Keuangan & Konversi, Waktu & Komunikasi, Sensor & Bantuan Lapangan.
class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  int _timeDifference = -6;

  @override
  Widget build(BuildContext context) {
    final diffSign = _timeDifference > 0 ? '+' : '';
    final diffLabel = '$diffSign$_timeDifference Jam Selisih';

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: StudyTripAppBar(
        title: 'Alat & Utilitas',
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.navy),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.teal,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // Section 1: Keuangan & Konversi
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Keuangan & Konversi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7F0F0),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  '• Kurs Langsung',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const CurrencyConverterCard(),

          const SizedBox(height: 28),

          // Section 2: Waktu & Komunikasi
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.brown,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Waktu & Komunikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE3CF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  diffLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TimezoneConverterCard(
            onDifferenceChanged: (diff) {
              if (mounted && _timeDifference != diff) {
                setState(() {
                  _timeDifference = diff;
                });
              }
            },
          ),

          const SizedBox(height: 28),

          // Section 3: Sensor & Bantuan Lapangan
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.slate,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sensor & Bantuan Lapangan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const EmergencyShortcutCard(),
          const SizedBox(height: 14),
          const GyroscopeCompassCard(),
          const SizedBox(height: 14),
          const StudyBuddyAiCard(),
        ],
      ),
    );
  }
}