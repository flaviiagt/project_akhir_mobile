import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class IndoZone {
  final String code; // WIB, WITA, WIT
  final String label;
  final String city;
  final int offsetHours;

  const IndoZone({
    required this.code,
    required this.label,
    required this.city,
    required this.offsetHours,
  });
}

class DestZone {
  final String city;
  final String country;
  final String code;
  final int offsetHours;

  const DestZone({
    required this.city,
    required this.country,
    required this.code,
    required this.offsetHours,
  });
}

const List<IndoZone> kIndoZones = [
  IndoZone(
    code: 'WIB',
    label: 'WIB',
    city: 'Jakarta',
    offsetHours: 7,
  ),
  IndoZone(
    code: 'WITA',
    label: 'WITA',
    city: 'Bali / Makassar',
    offsetHours: 8,
  ),
  IndoZone(
    code: 'WIT',
    label: 'WIT',
    city: 'Jayapura',
    offsetHours: 9,
  ),
];

const List<DestZone> kDestZones = [
  DestZone(
    city: 'London',
    country: 'UK',
    code: 'BST (GMT+1)',
    offsetHours: 1,
  ),
  DestZone(
    city: 'Edinburgh',
    country: 'UK',
    code: 'BST (GMT+1)',
    offsetHours: 1,
  ),
];

/// Kartu konversi zona waktu (WIB, WITA, WIT, London).
class TimezoneConverterCard extends StatefulWidget {
  final ValueChanged<int>? onDifferenceChanged;

  const TimezoneConverterCard({
    super.key,
    this.onDifferenceChanged,
  });

  @override
  State<TimezoneConverterCard> createState() => _TimezoneConverterCardState();
}

class _TimezoneConverterCardState extends State<TimezoneConverterCard> {
  IndoZone _selectedIndo = kIndoZones[0]; // WIB (GMT+7)
  DestZone _selectedDest = kDestZones[0]; // London (GMT+1)

  Timer? _timer;
  DateTime _now = DateTime.now().toUtc();
  bool _isCustomTime = false;
  int _customHour = 20;
  int _customMinute = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isCustomTime && mounted) {
        setState(() {
          _now = DateTime.now().toUtc();
        });
      }
    });
  }

  int get _hourDifference => _selectedDest.offsetHours - _selectedIndo.offsetHours;

  void _notifyDifference() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDifferenceChanged?.call(_hourDifference);
      }
    });
  }

  DateTime get _effectiveUtc {
    if (!_isCustomTime) {
      return _now;
    }
    final today = DateTime.now();
    // custom time is specified in selected Indo zone
    final indoDateTime = DateTime(today.year, today.month, today.day, _customHour, _customMinute);
    return indoDateTime.subtract(Duration(hours: _selectedIndo.offsetHours));
  }

  DateTime get _indoTime => _effectiveUtc.add(Duration(hours: _selectedIndo.offsetHours));
  DateTime get _destTime => _effectiveUtc.add(Duration(hours: _selectedDest.offsetHours));

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _isNight(int hour) => hour < 6 || hour >= 18;

  @override
  Widget build(BuildContext context) {
    final indoDt = _indoTime;
    final destDt = _destTime;

    final indoNight = _isNight(indoDt.hour);
    final destNight = _isNight(destDt.hour);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: ToolColors.navy.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector chips for Indo zones
          Row(
            children: [
              const Text(
                'Zona Indonesia:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ToolColors.slate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: kIndoZones.map((z) {
                      final selected = z.code == _selectedIndo.code;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(z.code),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: ToolColors.teal,
                          backgroundColor: const Color(0xFFF3F5F7),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : ToolColors.navy,
                          ),
                          shape: const StadiumBorder(),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          onSelected: (_) {
                            setState(() {
                              _selectedIndo = z;
                              _notifyDifference();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Selector chips for Dest zones (London / Edinburgh)
          Row(
            children: [
              const Text(
                'Kota Tujuan:     ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: ToolColors.slate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: kDestZones.map((d) {
                      final selected = d.city == _selectedDest.city;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(d.city),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: ToolColors.brown,
                          backgroundColor: const Color(0xFFF3F5F7),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : ToolColors.navy,
                          ),
                          shape: const StadiumBorder(),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          onSelected: (_) {
                            setState(() {
                              _selectedDest = d;
                              _notifyDifference();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Dual cards: KELUARGA (RUMAH) vs KAMPUS TUJUAN
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Card: Keluarga (Rumah)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: indoNight ? const Color(0xFFE2EAFD) : const Color(0xFFFEF3D6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          indoNight ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                          color: indoNight ? const Color(0xFF4C63B6) : const Color(0xFFD97706),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'KELUARGA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: ToolColors.slate,
                        ),
                      ),
                      const Text(
                        '(RUMAH)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                          color: ToolColors.slate,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedIndo.city,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: ToolColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(indoDt),
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: ToolColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedIndo.code} (GMT+${_selectedIndo.offsetHours})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ToolColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Right Card: Kampus Tujuan (London / Edinburgh)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F8F8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: destNight ? const Color(0xFFE2EAFD) : const Color(0xFFFEF3D6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          destNight ? Icons.nightlight_round : Icons.wb_sunny_outlined,
                          color: destNight ? const Color(0xFF4C63B6) : const Color(0xFFD97706),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'KAMPUS TUJUAN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: ToolColors.teal,
                        ),
                      ),
                      const SizedBox(height: 14), // balancing height with (RUMAH)
                      Text(
                        _selectedDest.city,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: ToolColors.teal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(destDt),
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: ToolColors.teal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDest.code,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ToolColors.teal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bottom Bar: Waktu telepon ideal berikutnya
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE3CF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.call_outlined,
                    color: ToolColors.brown,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waktu telepon ideal berikutnya:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: ToolColors.ink,
                        ),
                      ),
                      Text(
                        '12:00 London = waktu santai keluarga',
                        style: TextStyle(
                          fontSize: 10,
                          color: ToolColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _calculateIdealIndoTime(),
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: ToolColors.teal,
                      ),
                    ),
                    Text(
                      _selectedIndo.code,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: ToolColors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Interactive Mode: Live vs Simulasi Jam
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: ToolColors.slate,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                icon: Icon(
                  _isCustomTime ? Icons.schedule : Icons.fiber_manual_record,
                  size: 14,
                  color: _isCustomTime ? ToolColors.brown : Colors.green,
                ),
                label: Text(
                  _isCustomTime ? 'Mode Simulasi Jam' : 'Live Waktu Nyata',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  setState(() {
                    _isCustomTime = !_isCustomTime;
                    if (!_isCustomTime) {
                      _now = DateTime.now().toUtc();
                    } else {
                      final local = DateTime.now();
                      _customHour = local.hour;
                      _customMinute = local.minute;
                    }
                  });
                },
              ),
              if (_isCustomTime)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: ToolColors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  onPressed: () => _pickCustomTime(context),
                  child: const Text(
                    'Pilih Jam Lain',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),

          if (_isCustomTime) ...[
            Slider(
              value: _customHour.toDouble(),
              min: 0,
              max: 23,
              divisions: 23,
              label: '${_customHour.toString().padLeft(2, '0')}:00',
              activeColor: ToolColors.teal,
              inactiveColor: const Color(0xFFE2EAFD),
              onChanged: (val) {
                setState(() {
                  _customHour = val.round();
                });
              },
            ),
            Center(
              child: Text(
                'Geser untuk simulasi jam di ${_selectedIndo.code}',
                style: const TextStyle(fontSize: 10, color: ToolColors.slate),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _calculateIdealIndoTime() {
    // 12:00 London is lunch break
    // In Indo = 12:00 + (Indo offset - Dest offset)
    // For WIB (7) & London (1): 12 + 6 = 18:00 WIB
    // For WITA (8) & London (1): 12 + 7 = 19:00 WITA
    // For WIT (9) & London (1): 12 + 8 = 20:00 WIT
    final idealHour = (12 + (_selectedIndo.offsetHours - _selectedDest.offsetHours)) % 24;
    return '${idealHour.toString().padLeft(2, '0')}:00';
  }

  Future<void> _pickCustomTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _customHour, minute: _customMinute),
    );
    if (picked != null) {
      setState(() {
        _customHour = picked.hour;
        _customMinute = picked.minute;
      });
    }
  }
}
