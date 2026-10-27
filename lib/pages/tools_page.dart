import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../core/user_events.dart';
import '../theme/app_theme.dart';
import '../widgets/currency_converter_card.dart';
import '../widgets/emergency_shortcut_card.dart';
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
  String? _destinationProgram;

  @override
  void initState() {
    super.initState();
    profileVersion.addListener(_loadDestinationProgram);
    _loadDestinationProgram();
    // Pasang bubble StudyBuddy yang melayang di atas semua halaman
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) StudyBuddyFloating.show(context);
    });
  }

  @override
  void dispose() {
    profileVersion.removeListener(_loadDestinationProgram);
    // Bubble ikut hilang saat halaman ini dihancurkan (mis. logout)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StudyBuddyFloating.hide();
    });
    super.dispose();
  }

  Future<void> _loadDestinationProgram() async {
    Map<String, dynamic>? user;
    try {
      user = await AuthService.me(redirect: false);
    } on ApiException {
      user = await AuthService.cachedUser();
    }

    final program = user?['program'] as String?;
    if (mounted && _destinationProgram != program) {
      setState(() => _destinationProgram = program);
    }
  }

  @override
  Widget build(BuildContext context) {
    final diffSign = _timeDifference > 0 ? '+' : '';
    final diffLabel = '$diffSign$_timeDifference Jam Selisih';

    return Scaffold(
      backgroundColor: ToolColors.cream,
      appBar: const StudyTripAppBar(title: 'Alat & Utilitas'),
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
                  color: ToolColors.teal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Keuangan & Konversi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ToolColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7F0F0),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  '• Kurs Langsung',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ToolColors.teal,
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
                  color: ToolColors.brown,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Waktu & Komunikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ToolColors.ink,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE3CF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  diffLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: ToolColors.brown,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TimezoneConverterCard(
            destinationProgram: _destinationProgram,
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
                  color: ToolColors.slate,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Sensor & Bantuan Lapangan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ToolColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const EmergencyShortcutCard(),
        ],
      ),
    );
  }
}
