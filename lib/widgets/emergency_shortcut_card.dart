import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/user_events.dart';
import '../data/emergency_numbers.dart';
import '../data/universities.dart';
import '../theme/app_theme.dart';

/// Kartu "Pintasan Gerak Darurat" (FR-20: accelerometer).
/// Guncang HP -> tampil nomor darurat negara kampus tujuan.
///
/// Tujuan diambil otomatis dari profil (field `program` di server, sama seperti
/// Beranda) dan disalin ke shared_preferences supaya tetap tersedia saat offline.
/// [destination] opsional: kalau diisi, dipakai menggantikan data profil.
/// Jika tujuan kosong/tidak cocok, pengguna memilih negara lewat chip.
class EmergencyShortcutCard extends StatefulWidget {
  const EmergencyShortcutCard({super.key, this.destination});

  final String? destination;

  @override
  State<EmergencyShortcutCard> createState() => _EmergencyShortcutCardState();
}

class _EmergencyShortcutCardState extends State<EmergencyShortcutCard> {
  bool _isActive = true;
  bool _sensorError = false;
  bool _sheetOpen = false;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  DateTime? _lastShake;
  String? _program; // nama kampus tujuan dari profil
  static const _prefKey = 'emergency_last_program';

  @override
  void initState() {
    super.initState();
    profileVersion.addListener(_loadProgram);
    _loadProgram();
    _startShakeSensor();
  }

  /// Coba server dulu; kalau gagal/offline pakai salinan lokal terakhir.
  Future<void> _loadProgram() async {
    String? program;
    try {
      final r = await ApiClient.get('me.php', auth: true, redirect: false);
      final u = r['user'] as Map<String, dynamic>?;
      program = u?['program'] as String?;
      if (program != null && program.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, program);
      }
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        program = prefs.getString(_prefKey);
      } catch (_) {}
    }
    if (mounted) setState(() => _program = program);
  }

  void _startShakeSensor() {
    _accelSub?.cancel();
    _accelSub = null;
    if (!_isActive) return;

    try {
      _accelSub = userAccelerometerEventStream().listen(
        (event) {
          if (!_isActive || !mounted) return;
          final magnitude =
              sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          if (magnitude > 13.0) {
            final now = DateTime.now();
            if (_lastShake == null ||
                now.difference(_lastShake!) > const Duration(seconds: 3)) {
              _lastShake = now;
              HapticFeedback.heavyImpact();
              _openSheet();
            }
          }
        },
        onError: (_) {
          if (mounted) setState(() => _sensorError = true);
        },
      );
    } catch (_) {
      _sensorError = true;
    }
  }

  @override
  void dispose() {
    profileVersion.removeListener(_loadProgram);
    _accelSub?.cancel();
    super.dispose();
  }

  Future<void> _openSheet() async {
    if (_sheetOpen) return; // cegah sheet terbuka dobel saat guncangan beruntun
    _sheetOpen = true;

    final country = findUniversity(widget.destination ?? _program)?.country;
    final idx = emergencyIndexForCountry(country);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmergencySheet(
        initialIndex: idx < 0 ? 0 : idx,
        destinationMatched: idx >= 0,
        isActive: _isActive,
        onToggleActive: (v) {
          setState(() => _isActive = v);
          _startShakeSensor();
        },
      ),
    );
    _sheetOpen = false;
  }

  String get _subtitle {
    if (_sensorError) {
      return 'Sensor tidak tersedia • Ketuk untuk melihat nomor darurat';
    }
    return _isActive
        ? 'Aktif • Guncang perangkat untuk nomor darurat'
        : 'Nonaktif • Ketuk untuk melihat nomor darurat';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: ToolColors.navy.withValues(alpha: 0.06),
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
          onTap: _openSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8D6),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Icon(Icons.screen_rotation_rounded,
                        color: ToolColors.brown, size: 26),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Flexible(
                            child: Text(
                              'Pintasan Gerak Darurat',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: ToolColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: (_isActive && !_sensorError)
                                  ? ToolColors.teal
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: ToolColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDECE8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stay_current_portrait_rounded,
                      color: ToolColors.slate, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet nomor darurat
// ---------------------------------------------------------------------------

class _EmergencySheet extends StatefulWidget {
  const _EmergencySheet({
    required this.initialIndex,
    required this.destinationMatched,
    required this.isActive,
    required this.onToggleActive,
  });

  final int initialIndex;
  final bool destinationMatched;
  final bool isActive;
  final ValueChanged<bool> onToggleActive;

  @override
  State<_EmergencySheet> createState() => _EmergencySheetState();
}

class _EmergencySheetState extends State<_EmergencySheet> {
  late int _index = widget.initialIndex;
  late bool _active = widget.isActive;

  @override
  Widget build(BuildContext context) {
    final data = kEmergencyList[_index];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: ToolColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE8D6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emergency_outlined,
                      color: ToolColors.brown, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nomor Darurat',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: ToolColors.ink,
                        ),
                      ),
                      Text(
                        'Tersimpan offline di aplikasi',
                        style:
                            TextStyle(fontSize: 12, color: ToolColors.slate),
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
            const SizedBox(height: 14),

            if (!widget.destinationMatched)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Negara tujuan belum dipilih. Pilih negara di bawah.',
                  style: TextStyle(fontSize: 12, color: ToolColors.slate),
                ),
              ),

            // pilih negara
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < kEmergencyList.length; i++)
                  ChoiceChip(
                    label: Text(kEmergencyList[i].title),
                    selected: i == _index,
                    showCheckmark: false,
                    selectedColor: ToolColors.teal,
                    backgroundColor: const Color(0xFFEDECE8),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: i == _index ? Colors.white : ToolColors.ink,
                    ),
                    onSelected: (_) => setState(() => _index = i),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // daftar nomor
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < data.numbers.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    _NumberTile(item: data.numbers[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            const Text(
              'Untuk masalah paspor atau bantuan WNI, hubungi KBRI/KJRI '
              'setempat. Ketuk nomor untuk menyalin.',
              style: TextStyle(fontSize: 12, color: ToolColors.slate),
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Aktifkan Sensor Gerak (Guncang HP)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: const Text(
                'Guncang HP kapan saja untuk membuka nomor darurat',
                style: TextStyle(fontSize: 12, color: ToolColors.slate),
              ),
              value: _active,
              activeThumbColor: ToolColors.teal,
              onChanged: (v) {
                setState(() => _active = v);
                widget.onToggleActive(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberTile extends StatefulWidget {
  const _NumberTile({required this.item});
  final EmergencyNumber item;

  @override
  State<_NumberTile> createState() => _NumberTileState();
}

class _NumberTileState extends State<_NumberTile> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.item.number));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _copy,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(widget.item.icon, size: 22, color: ToolColors.brown),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ToolColors.ink,
                ),
              ),
            ),
            Text(
              widget.item.number,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: ToolColors.teal,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _copied ? Icons.check_circle : Icons.copy_rounded,
              size: 18,
              color: _copied ? ToolColors.teal : ToolColors.slate,
            ),
          ],
        ),
      ),
    );
  }
}