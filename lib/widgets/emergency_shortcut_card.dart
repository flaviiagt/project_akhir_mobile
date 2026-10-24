import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../theme/app_theme.dart';

/// Kartu "Pintasan Gerak Darurat" (FR-20: Sensor accelerometer untuk membuka brankas paspor).
class EmergencyShortcutCard extends StatefulWidget {
  const EmergencyShortcutCard({super.key});

  @override
  State<EmergencyShortcutCard> createState() => _EmergencyShortcutCardState();
}

class _EmergencyShortcutCardState extends State<EmergencyShortcutCard> {
  bool _isActive = true;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  DateTime? _lastShake;

  @override
  void initState() {
    super.initState();
    _startShakeSensor();
  }

  void _startShakeSensor() {
    _accelSub?.cancel();
    if (!_isActive) return;

    try {
      _accelSub = userAccelerometerEventStream().listen(
        (event) {
          if (!_isActive || !mounted) return;
          // Hitung besar vektor percepatan pengguna
          final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          // Ambang batas guncangan tangan (shake threshold > 13 m/s²)
          if (magnitude > 13.0) {
            final now = DateTime.now();
            if (_lastShake == null || now.difference(_lastShake!) > const Duration(seconds: 3)) {
              _lastShake = now;
              _openPassportVault();
            }
          }
        },
        onError: (_) {},
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  void _openPassportVault() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PassportVaultModal(
        isActive: _isActive,
        onToggleActive: (val) {
          setState(() {
            _isActive = val;
            _startShakeSensor();
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _openPassportVault,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon box kiri
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8D6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.screen_rotation_rounded,
                      color: AppColors.brown,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Teks tengah
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Pintasan Gerak Darurat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _isActive ? AppColors.teal : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _isActive
                            ? 'Aktif • Guncang perangkat untuk brankas paspor'
                            : 'Nonaktif • Ketuk untuk membuka brankas paspor',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Tombol kanan
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDECE8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stay_current_portrait_rounded,
                    color: AppColors.slate,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal Brankas Paspor Darurat
class _PassportVaultModal extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onToggleActive;

  const _PassportVaultModal({
    required this.isActive,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE8D6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, color: AppColors.brown, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Brankas Paspor Darurat',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE8D6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'FR-20',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brown,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Akses cepat offline via sensor accelerometer',
                      style: TextStyle(fontSize: 12, color: AppColors.slate),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Kartu Paspor Digital
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F3558), Color(0xFF1B5A8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'PASPOR INDONESIA',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'OFFLINE VAULT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'STUDENT STUDYTRIP',
                  style: GoogleFonts.bricolageGrotesque(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _infoCol('NOMOR PASPOR', 'X 9283741'),
                    _infoCol('WARGA NEGARA', 'IDN'),
                    _infoCol('BERLAKU S/D', '18 OKT 2030'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Kontak Bantuan Darurat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kontak Bantuan Darurat di UK:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate),
                ),
                const SizedBox(height: 10),
                _contactRow(Icons.account_balance, 'KBRI London (24 Jam)', '+44 20 7499 7661'),
                const Divider(height: 16),
                _contactRow(Icons.local_police_outlined, 'Layanan Darurat Inggris (Polisi/Ambulans)', '999'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Switch sensor aktif
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Aktifkan Sensor Gerak (Guncang HP)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            subtitle: const Text(
              'Guncang HP kapan saja untuk langsung membuka paspor ini',
              style: TextStyle(fontSize: 12, color: AppColors.slate),
            ),
            value: isActive,
            activeThumbColor: AppColors.teal,
            onChanged: (val) {
              onToggleActive(val);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val ? 'Pintasan gerak darurat diaktifkan.' : 'Pintasan gerak dinonaktifkan.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD6D3CC)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Simulasi sensor accelerometer berhasil memicu brankas paspor!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.vibration_rounded, color: AppColors.brown, size: 18),
            label: const Text(
              'Tes Simulasi Sensor Guncangan (Shake)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _contactRow(IconData icon, String name, String phone) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.brown),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
              Text(phone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.teal)),
            ],
          ),
        ),
      ],
    );
  }
}
