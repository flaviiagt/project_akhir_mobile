import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../data/universities.dart';
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
  final String timeZoneId;

  const DestZone({
    required this.city,
    required this.country,
    required this.timeZoneId,
  });
}

const List<IndoZone> kIndoZones = [
  IndoZone(code: 'WIB', label: 'WIB', city: 'Jakarta', offsetHours: 7),
  IndoZone(
    code: 'WITA',
    label: 'WITA',
    city: 'Bali / Makassar',
    offsetHours: 8,
  ),
  IndoZone(code: 'WIT', label: 'WIT', city: 'Jayapura', offsetHours: 9),
];

const DestZone kLondonDestZone = DestZone(
  city: 'London',
  country: 'Inggris',
  timeZoneId: 'Europe/London',
);

/// Mengembalikan zona waktu kota dari pilihan kampus di profil.
DestZone? destinationZoneForProgram(String? program) {
  final university = findUniversity(program);
  if (university == null) return null;

  final timeZoneId = switch (university.country) {
    'Skotlandia' || 'Inggris' => 'Europe/London',
    'Belanda' => 'Europe/Amsterdam',
    'Amerika Serikat' =>
      university.city == 'Stanford' ||
              university.city == 'Pasadena' ||
              university.city == 'Berkeley'
          ? 'America/Los_Angeles'
          : 'America/New_York',
    'Swiss' => 'Europe/Zurich',
    'Singapura' => 'Asia/Singapore',
    'Hong Kong' => 'Asia/Hong_Kong',
    'Tiongkok' => 'Asia/Shanghai',
    'Australia' => 'Australia/Sydney',
    'Jerman' => 'Europe/Berlin',
    _ => null,
  };
  if (timeZoneId == null) return null;
  return DestZone(
    city: university.city,
    country: university.country,
    timeZoneId: timeZoneId,
  );
}

/// London selalu tersedia; kampus tujuan menambahkan satu opsi kota profil.
List<DestZone> destinationZonesForProgram(String? program) {
  final campusZone = destinationZoneForProgram(program);
  if (campusZone == null || campusZone.city == kLondonDestZone.city) {
    return [kLondonDestZone];
  }
  return [kLondonDestZone, campusZone];
}

bool _timeZonesInitialized = false;

void _ensureTimeZonesInitialized() {
  if (_timeZonesInitialized) return;
  tzdata.initializeTimeZones();
  _timeZonesInitialized = true;
}

tz.TZDateTime destinationTimeAt(DestZone zone, DateTime utc) {
  _ensureTimeZonesInitialized();
  return tz.TZDateTime.from(utc, tz.getLocation(zone.timeZoneId));
}

/// Kartu konversi zona waktu (WIB, WITA, WIT, London).
class TimezoneConverterCard extends StatefulWidget {
  final ValueChanged<int>? onDifferenceChanged;
  final String? destinationProgram;

  const TimezoneConverterCard({
    super.key,
    this.onDifferenceChanged,
    this.destinationProgram,
  });

  @override
  State<TimezoneConverterCard> createState() => _TimezoneConverterCardState();
}

class _TimezoneConverterCardState extends State<TimezoneConverterCard> {
  IndoZone _selectedIndo = kIndoZones[0]; // WIB (GMT+7)
  DestZone _selectedDest = kLondonDestZone;

  Timer? _timer;
  DateTime _now = DateTime.now().toUtc();
  bool _isCustomTime = false;
  int _customHour = 20;
  int _customMinute = 30;
  int? _lastNotifiedDifference;

  @override
  void initState() {
    super.initState();
    _ensureTimeZonesInitialized();
    _startTimer();
    _notifyDifference();
  }

  @override
  void didUpdateWidget(covariant TimezoneConverterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destinationProgram != widget.destinationProgram) {
      if (_selectedDest.city != kLondonDestZone.city) {
        final campusZone = destinationZoneForProgram(widget.destinationProgram);
        if (campusZone != null &&
            campusZone.city == _selectedDest.city &&
            campusZone.timeZoneId == _selectedDest.timeZoneId) {
          _selectedDest = campusZone;
        } else {
          _selectedDest = kLondonDestZone;
        }
      }
      _notifyDifference();
    }
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
        _notifyDifference();
      }
    });
  }

  tz.TZDateTime get _destTime =>
      destinationTimeAt(_selectedDest, _effectiveUtc);

  int get _hourDifference =>
      _destTime.timeZoneOffset.inHours - _selectedIndo.offsetHours;

  void _notifyDifference() {
    final difference = _hourDifference;
    if (_lastNotifiedDifference == difference) return;
    _lastNotifiedDifference = difference;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onDifferenceChanged?.call(difference);
      }
    });
  }

  DateTime get _effectiveUtc {
    if (!_isCustomTime) {
      return _now;
    }
    final today = DateTime.now();
    // custom time is specified in selected Indo zone
    final indoDateTime = DateTime(
      today.year,
      today.month,
      today.day,
      _customHour,
      _customMinute,
    );
    return indoDateTime.subtract(Duration(hours: _selectedIndo.offsetHours));
  }

  DateTime get _indoTime =>
      _effectiveUtc.add(Duration(hours: _selectedIndo.offsetHours));
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
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

          // London is always available; the profile campus adds one city option.
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
                    children:
                        destinationZonesForProgram(widget.destinationProgram)
                            .map((d) {
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
                                    color: selected
                                        ? Colors.white
                                        : ToolColors.navy,
                                  ),
                                  shape: const StadiumBorder(),
                                  side: BorderSide.none,
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 0,
                                  ),
                                  onSelected: (_) {
                                    setState(() {
                                      _selectedDest = d;
                                      _notifyDifference();
                                    });
                                  },
                                ),
                              );
                            })
                            .toList(),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 18,
                  ),
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
                          color: indoNight
                              ? const Color(0xFFE2EAFD)
                              : const Color(0xFFFEF3D6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          indoNight
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_outlined,
                          color: indoNight
                              ? const Color(0xFF4C63B6)
                              : const Color(0xFFD97706),
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

              // Right Card: Kampus Tujuan
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 18,
                  ),
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
                          color: destNight
                              ? const Color(0xFFE2EAFD)
                              : const Color(0xFFFEF3D6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          destNight
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_outlined,
                          color: destNight
                              ? const Color(0xFF4C63B6)
                              : const Color(0xFFD97706),
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
                      const SizedBox(
                        height: 14,
                      ), // balancing height with (RUMAH)
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
                        '${_destTime.timeZoneName} (${_formatUtcOffset(_destTime.timeZoneOffset)})',
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
                Expanded(
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
                        '12:00 ${_selectedDest.city} = waktu santai keluarga',
                        style: TextStyle(fontSize: 10, color: ToolColors.slate),
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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
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
    final idealHour =
        (12 + (_selectedIndo.offsetHours - _destTime.timeZoneOffset.inHours)) %
        24;
    return '${idealHour.toString().padLeft(2, '0')}:00';
  }

  String _formatUtcOffset(Duration offset) {
    final minutes = offset.inMinutes;
    final sign = minutes >= 0 ? '+' : '-';
    final absolute = minutes.abs();
    final hours = (absolute ~/ 60).toString().padLeft(2, '0');
    final remainder = absolute % 60;
    return 'GMT$sign$hours${remainder == 0 ? '' : ':${remainder.toString().padLeft(2, '0')}'}';
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
