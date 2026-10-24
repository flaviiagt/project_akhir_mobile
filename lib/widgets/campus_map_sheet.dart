import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../pages/campus_map_page.dart';
import '../theme/app_theme.dart';

/// Modal Peta Interaktif & Location-Based Services (FR-19).
/// Menampilkan lokasi kampus di peta OpenStreetMap, koordinat GPS,
/// dan kalkulasi jarak geospasial dari Indonesia.
class CampusMapSheet extends StatefulWidget {
  final String campusName;
  final String locationName;
  final double latitude;
  final double longitude;

  const CampusMapSheet({
    super.key,
    required this.campusName,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  static const LatLng jakartaLocation = LatLng(-6.2088, 106.8456);

  @override
  State<CampusMapSheet> createState() => _CampusMapSheetState();
}

class _CampusMapSheetState extends State<CampusMapSheet> {
  late final MapController _mapController;
  late LatLng _targetCenter;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _targetCenter = LatLng(widget.latitude, widget.longitude);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Hitung jarak Geodesic (Haversine formula) dalam km
  double _calculateDistanceKm(LatLng from, LatLng to) {
    const r = 6371.0; // Radius bumi dalam km
    final dLat = (to.latitude - from.latitude) * pi / 180.0;
    final dLon = (to.longitude - from.longitude) * pi / 180.0;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(from.latitude * pi / 180.0) *
            cos(to.latitude * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = _calculateDistanceKm(CampusMapSheet.jakartaLocation, _targetCenter);
    final flightHours = (distanceKm / 850).round(); // rata-rata kecepatan pesawat 850 km/jam

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD7F0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.map_outlined, color: AppColors.teal, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.campusName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Peta LBS: ${widget.locationName}',
                        style: const TextStyle(fontSize: 11, color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Buka Peta Dunia Lengkap',
                  icon: const Icon(Icons.open_in_new, color: AppColors.teal, size: 20),
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    navigator.push(
                      MaterialPageRoute(builder: (_) => const CampusMapPage()),
                    );
                  },
                ),
                IconButton(
                  tooltip: 'Tutup Peta',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // LBS Distance Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E2DC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _lbsInfo(
                  Icons.near_me_outlined,
                  'JARAK DARI INDO',
                  '${distanceKm.round()} km',
                  AppColors.teal,
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE5E2DC)),
                _lbsInfo(
                  Icons.flight_takeoff,
                  'ESTIMASI TERBANG',
                  '~$flightHours Jam',
                  AppColors.brown,
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE5E2DC)),
                _lbsInfo(
                  Icons.pin_drop_outlined,
                  'KOORDINAT',
                  '${widget.latitude.toStringAsFixed(2)}, ${widget.longitude.toStringAsFixed(2)}',
                  Color(0xFF1B5A8C),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Peta Interaktif OpenStreetMap
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _targetCenter,
                      initialZoom: 14.5,
                      minZoom: 3,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.studytrip',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _targetCenter,
                            width: 60,
                            height: 60,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.teal,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black26, blurRadius: 6),
                                    ],
                                  ),
                                  child: const Icon(Icons.school, color: Colors.white, size: 20),
                                ),
                                const Icon(Icons.arrow_drop_down, color: AppColors.teal, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Floating Map Controls (Hero-free untuk cegah _dependents.isEmpty crash)
                Positioned(
                  right: 16,
                  bottom: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _mapActionButton(
                        icon: Icons.add,
                        onTap: () {
                          final z = _mapController.camera.zoom + 1;
                          _mapController.move(_targetCenter, z);
                        },
                      ),
                      const SizedBox(height: 8),
                      _mapActionButton(
                        icon: Icons.remove,
                        onTap: () {
                          final z = _mapController.camera.zoom - 1;
                          _mapController.move(_targetCenter, z);
                        },
                      ),
                      const SizedBox(height: 8),
                      _mapActionButton(
                        icon: Icons.my_location,
                        bgColor: AppColors.teal,
                        fgColor: Colors.white,
                        onTap: () {
                          _mapController.move(_targetCenter, 14.5);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapActionButton({
    required IconData icon,
    required VoidCallback onTap,
    Color bgColor = Colors.white,
    Color fgColor = AppColors.ink,
  }) {
    return Material(
      color: bgColor,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black38,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: fgColor, size: 20),
        ),
      ),
    );
  }

  Widget _lbsInfo(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.slate,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}
