import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../theme/app_theme.dart';

/// Kartu Sensor Gyroscope (FR-21).
/// Mengukur kecepatan sudut (rad/s) pada sumbu 3D (X: Pitch, Y: Roll, Z: Yaw)
/// serta menampilkan orientasi kemiringan visual (3D Level & Kompas).
class GyroscopeCompassCard extends StatefulWidget {
  const GyroscopeCompassCard({super.key});

  @override
  State<GyroscopeCompassCard> createState() => _GyroscopeCompassCardState();
}

class _GyroscopeCompassCardState extends State<GyroscopeCompassCard> {
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _x = 0.0; // rad/s Pitch
  double _y = 0.0; // rad/s Roll
  double _z = 0.0; // rad/s Yaw

  double _pitchDeg = 0.0;
  double _rollDeg = 0.0;
  DateTime? _lastTimestamp;
  bool _isSensorAvailable = true;

  @override
  void initState() {
    super.initState();
    _startGyroscope();
  }

  void _startGyroscope() {
    try {
      _gyroSub = gyroscopeEventStream().listen(
        (event) {
          final now = DateTime.now();
          if (_lastTimestamp != null) {
            final dt = now.difference(_lastTimestamp!).inMicroseconds / 1000000.0;
            // Integrasi kecepatan sudut ke estimasi derajat orientasi
            _pitchDeg = (_pitchDeg + event.x * dt * (180 / pi)).clamp(-90.0, 90.0);
            _rollDeg = (_rollDeg + event.y * dt * (180 / pi)).clamp(-90.0, 90.0);
          }
          _lastTimestamp = now;

          if (mounted) {
            setState(() {
              _x = event.x;
              _y = event.y;
              _z = event.z;
              _isSensorAvailable = true;
            });
          }
        },
        onError: (_) {
          if (mounted) {
            setState(() => _isSensorAvailable = false);
          }
        },
      );
    } catch (_) {
      _isSensorAvailable = false;
    }
  }

  void _resetOrientation() {
    setState(() {
      _pitchDeg = 0.0;
      _rollDeg = 0.0;
      _x = 0.0;
      _y = 0.0;
      _z = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sensor Gyroscope dikalibrasi ke posisi datar (0°).'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _simulateTilt() {
    setState(() {
      _pitchDeg = (_pitchDeg + 12.0) % 45.0;
      _rollDeg = (_rollDeg - 8.0) % 45.0;
      _x = 0.35;
      _y = -0.22;
      _z = 0.15;
    });
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Bubble indicator position based on roll & pitch
    final bubbleX = (_rollDeg / 45.0).clamp(-1.0, 1.0) * 40.0;
    final bubbleY = (_pitchDeg / 45.0).clamp(-1.0, 1.0) * 40.0;
    final isLevel = _pitchDeg.abs() < 3.0 && _rollDeg.abs() < 3.0;

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F5F2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore_rounded,
                    color: AppColors.teal,
                    size: 24,
                  ),
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
                              'Gyroscope & Orientasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD7F0F0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'FR-21',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Sensor gerak rotasi 3-sumbu & waterpass level',
                        style: TextStyle(fontSize: 12, color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isSensorAvailable
                        ? (isLevel ? const Color(0xFFD8F6E8) : const Color(0xFFFFF2D6))
                        : const Color(0xFFF1F0EC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _isSensorAvailable
                              ? (isLevel ? const Color(0xFF0E8A63) : const Color(0xFFD97706))
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLevel ? 'Level Seimbang' : 'Terdeteksi Miring',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isLevel ? const Color(0xFF0E8A63) : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Visual Dial / Bubble Level Container
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F6),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFEDEAE3)),
              ),
              child: Row(
                children: [
                  // Circular Bubble Level
                  Expanded(
                    flex: 4,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer Target Ring
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.teal.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                          ),
                          // Middle Ring
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.slate.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                          ),
                          // Crosshairs
                          Container(
                            width: 120,
                            height: 1,
                            color: AppColors.slate.withValues(alpha: 0.2),
                          ),
                          Container(
                            width: 1,
                            height: 120,
                            color: AppColors.slate.withValues(alpha: 0.2),
                          ),
                          // Center target dot
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: isLevel ? AppColors.teal : AppColors.slate,
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Moving Bubble
                          Transform.translate(
                            offset: Offset(bubbleX, bubbleY),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 100),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isLevel
                                    ? AppColors.teal.withValues(alpha: 0.85)
                                    : const Color(0xFFE27D60).withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLevel ? AppColors.teal : const Color(0xFFE27D60))
                                        .withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.adjust_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Degrees and Axis Readings
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDegreeRow(
                          label: 'Pitch (Sumbu X)',
                          value: '${_pitchDeg.toStringAsFixed(1)}°',
                          color: AppColors.ink,
                        ),
                        const SizedBox(height: 8),
                        _buildDegreeRow(
                          label: 'Roll (Sumbu Y)',
                          value: '${_rollDeg.toStringAsFixed(1)}°',
                          color: AppColors.ink,
                        ),
                        const SizedBox(height: 8),
                        _buildDegreeRow(
                          label: 'Yaw Speed (Z)',
                          value: '${_z.toStringAsFixed(2)} rad/s',
                          color: AppColors.teal,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Live 3-Axis Velocity Metrics
            Row(
              children: [
                _buildAxisMetric('X (Pitch)', _x, const Color(0xFF007A80)),
                const SizedBox(width: 8),
                _buildAxisMetric('Y (Roll)', _y, AppColors.brown),
                const SizedBox(width: 8),
                _buildAxisMetric('Z (Yaw)', _z, const Color(0xFF1B5A8C)),
              ],
            ),

            const SizedBox(height: 16),

            // Buttons: Kalibrasi Ulang & Simulasi Sensor
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD6D3CC)),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _resetOrientation,
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.ink),
                    label: const Text(
                      'Kalibrasi 0°',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD7F0F0),
                      foregroundColor: AppColors.teal,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: _simulateTilt,
                    icon: const Icon(Icons.screen_rotation_rounded, size: 16),
                    label: const Text(
                      'Tes Rotasi',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDegreeRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate),
        ),
        Text(
          value,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAxisMetric(String label, double val, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F5F2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate),
            ),
            const SizedBox(height: 2),
            Text(
              '${val.toStringAsFixed(2)} r/s',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
