import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../data/campus_coordinates.dart';
import '../logic/geo_utils.dart';
import '../theme/app_colors.dart';
import '../widgets/studytrip_app_bar.dart';

/// Status izin / posisi lokasi pengguna.
enum _Loc {
  idle,
  loading,
  active,
  off,
  denied,
  deniedForever,
  serviceOff,
  error,
}

/// Peta Kampus Dunia (LBS, FR-19).
/// - Meminta izin lokasi saat dibuka.
/// - Ketuk kampus: garis animasi dari koordinat pengguna ke kampus + jarak.
/// - Izin ditolak / lokasi dimatikan: tidak ada garis dan tidak ada jarak.
class CampusMapPage extends StatefulWidget {
  const CampusMapPage({super.key});

  @override
  State<CampusMapPage> createState() => _CampusMapPageState();
}

class _CampusMapPageState extends State<CampusMapPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final MapController _map = MapController();
  late final AnimationController _lineCtrl;
  final TextEditingController _search = TextEditingController();

  final List<MapCampus> _all = buildMapCampuses();
  late final List<String> _countries = [
    'Semua',
    ...{for (final c in _all) chipCountry(c.country)},
  ];

  String _country = 'Semua';
  MapCampus? _selected;

  _Loc _loc = _Loc.idle;
  LatLng? _user;
  String? _userPlace;

  List<List<LatLng>> _arc = const [];
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    // Izin lokasi diminta setelah halaman tampil.
    WidgetsBinding.instance.addPostFrameCallback((_) => _requestLocation());
  }

  @override
  void dispose() {
    _map.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _lineCtrl.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Kembali dari layar pengaturan: coba lagi otomatis.
    if (state == AppLifecycleState.resumed &&
        (_loc == _Loc.deniedForever || _loc == _Loc.serviceOff)) {
      _requestLocation();
    }
  }

  // ---------------------------------------------------------------- lokasi

  void _setLoc(_Loc l) {
    if (!mounted) return;
    setState(() => _loc = l);
  }

  Future<bool?> _showRationale() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Izinkan akses lokasi?'),
        content: const Text(
          'StudyTrip memakai lokasimu untuk menggambar garis dan menghitung '
          'jarak dari posisimu ke kampus yang kamu pilih.\n\n'
          'Lokasi tidak disimpan di aplikasi. Untuk menampilkan nama kotamu, '
          'koordinatmu dikirim sekali ke layanan peta OpenStreetMap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nanti saja'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Izinkan'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestLocation() async {
    if (!mounted) return;
    setState(() => _loc = _Loc.loading);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setLoc(_Loc.serviceOff);
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        final agree = await _showRationale();
        if (agree != true) {
          _setLoc(_Loc.denied);
          return;
        }
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _setLoc(_Loc.deniedForever);
        return;
      }
      if (perm != LocationPermission.always &&
          perm != LocationPermission.whileInUse) {
        _setLoc(_Loc.denied);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      setState(() {
        _user = LatLng(pos.latitude, pos.longitude);
        _userPlace = null;
        _loc = _Loc.active;
      });
      _resolvePlace(_user!);
      _drawRoute();
    } on TimeoutException {
      _setLoc(_Loc.error);
    } catch (_) {
      _setLoc(_Loc.error);
    }
  }

  void _turnOff() {
    _lineCtrl.stop();
    setState(() {
      _loc = _Loc.off;
      _user = null;
      _userPlace = null;
      _arc = const [];
      _distanceKm = null;
    });
  }

  /// Nama kota dari koordinat pengguna (OpenStreetMap Nominatim, 1x per fix).
  Future<void> _resolvePlace(LatLng p) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'jsonv2',
        'lat': '${p.latitude}',
        'lon': '${p.longitude}',
        'zoom': '10',
        'accept-language': 'id',
      });
      final res = await http
          .get(
            uri,
            headers: {'User-Agent': 'StudyTripApp/1.0 (tugas kuliah PAM)'},
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      final addr = (data is Map && data['address'] is Map)
          ? Map<String, dynamic>.from(data['address'] as Map)
          : <String, dynamic>{};
      String pick(List<String> keys) {
        for (final k in keys) {
          final v = addr[k];
          if (v is String && v.isNotEmpty) return v;
        }
        return '';
      }

      final city = pick([
        'city',
        'town',
        'village',
        'municipality',
        'county',
        'state',
      ]);
      final country = pick(['country']);
      final label = [city, country].where((s) => s.isNotEmpty).join(', ');
      if (!mounted || label.isEmpty || _user != p) return;
      setState(() => _userPlace = label);
    } catch (_) {
      // Nama kota gagal dimuat: koordinat tetap ditampilkan.
    }
  }

  // ----------------------------------------------------------------- peta

  List<MapCampus> get _visible => _all
      .where((c) => _country == 'Semua' || chipCountry(c.country) == _country)
      .toList();

  void _select(MapCampus c) {
    FocusScope.of(context).unfocus();
    _search.clear();
    setState(() {
      _selected = c;
      if (_country != 'Semua' && chipCountry(c.country) != _country) {
        _country = 'Semua';
      }
    });
    _drawRoute();
  }

  void _drawRoute() {
    final c = _selected;
    final u = _user;
    if (c == null) return;

    if (_loc == _Loc.active && u != null) {
      final arc = greatCircleArc(u, c.point);
      setState(() {
        _arc = arc;
        _distanceKm = haversineKm(u, c.point);
      });
      _lineCtrl.forward(from: 0);
      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: [for (final seg in arc) ...seg],
          padding: const EdgeInsets.fromLTRB(48, 90, 48, 270),
          maxZoom: 10,
        ),
      );
    } else {
      _lineCtrl.stop();
      setState(() {
        _arc = const [];
        _distanceKm = null;
      });
      _map.move(c.point, 6);
    }
  }

  void _pickCountry(String country) {
    setState(() {
      _country = country;
      _selected = null;
      _arc = const [];
      _distanceKm = null;
    });
    _lineCtrl.stop();
    if (country == 'Semua') {
      _map.move(const LatLng(25, 30), 1.2);
      return;
    }
    final pts = [for (final c in _visible) c.point];
    _map.fitCamera(
      CameraFit.coordinates(
        coordinates: pts,
        padding: const EdgeInsets.fromLTRB(48, 48, 48, 200),
        maxZoom: 9,
      ),
    );
  }

  /// Bagian garis yang sudah "tergambar" pada nilai animasi [t] (0..1).
  List<List<LatLng>> _partial(double t) {
    if (_arc.isEmpty) return const [];
    final total = _arc.fold<int>(0, (s, seg) => s + seg.length);
    var remaining = math.max(2, math.min(total, (total * t).round()));
    final out = <List<LatLng>>[];
    for (final seg in _arc) {
      if (remaining <= 0) break;
      final take = remaining < seg.length ? remaining : seg.length;
      out.add(seg.sublist(0, take));
      remaining -= take;
    }
    return out;
  }

  // ------------------------------------------------------------------ UI

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      appBar: const StudyTripAppBar(title: 'Peta Kampus Dunia'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _searchField(),
          ),
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final c in _countries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _country == c,
                      showCheckmark: false,
                      selectedColor: ToolColors.teal,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _country == c ? Colors.white : ToolColors.navy,
                      ),
                      onSelected: (_) => _pickCountry(c),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _locationBanner(),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  _mapView(visible),
                  if (_selected != null && _distanceKm != null)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 72,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _routePill(),
                      ),
                    ),
                  Positioned(top: 12, right: 12, child: _mapControls()),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _bottomCard(),
                  ),
                  if (_search.text.trim().isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 12,
                      right: 12,
                      child: _searchResults(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapView(List<MapCampus> visible) {
    // Kampus terpilih digambar paling akhir (paling atas).
    final ordered = [
      for (final c in visible)
        if (c.name != _selected?.name) c,
      for (final c in visible)
        if (c.name == _selected?.name) c,
    ];

    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: const LatLng(25, 30),
        initialZoom: 1.2,
        minZoom: 1,
        maxZoom: 17,
        cameraConstraint: CameraConstraint.containCenter(
          bounds: LatLngBounds(const LatLng(-85, -180), const LatLng(85, 180)),
        ),
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
        onTap: (_, _) => FocusScope.of(context).unfocus(),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.studytrip',
        ),
        AnimatedBuilder(
          animation: _lineCtrl,
          builder: (context, _) {
            final segs = _partial(_lineCtrl.value);
            return PolylineLayer(
              polylines: [
                for (final s in segs)
                  if (s.length > 1)
                    Polyline(
                      points: s,
                      strokeWidth: 3.5,
                      color: ToolColors.teal,
                    ),
              ],
            );
          },
        ),
        MarkerLayer(
          markers: [
            for (final c in ordered) _campusMarker(c),
            if (_user != null && _loc == _Loc.active)
              Marker(
                point: _user!,
                width: 26,
                height: 26,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F80ED),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 6),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Marker _campusMarker(MapCampus c) {
    final sel = _selected?.name == c.name;
    final size = sel ? 44.0 : 30.0;
    return Marker(
      point: c.point,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _select(c),
        child: Container(
          decoration: BoxDecoration(
            color: countryColor(c.country),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: sel ? 3 : 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Icon(Icons.school, size: sel ? 22 : 15, color: Colors.white),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFFE5E2DC)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search, color: ToolColors.slate, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 13, color: ToolColors.ink),
              decoration: InputDecoration(
                hintText: 'Cari dari ${_all.length} kampus dunia...',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: ToolColors.slate,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_search.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: ToolColors.slate),
              onPressed: () => setState(_search.clear),
            ),
        ],
      ),
    );
  }

  Widget _searchResults() {
    final q = _search.text.trim().toLowerCase();
    final results = _all
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.city.toLowerCase().contains(q) ||
              c.country.toLowerCase().contains(q),
        )
        .take(6)
        .toList();

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 280),
        child: results.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Kampus tidak ditemukan.'),
              )
            : ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final c in results)
                    ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: countryColor(c.country),
                        child: const Icon(
                          Icons.school,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        c.place,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () => _select(c),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _locationBanner() {
    var dot = ToolColors.slate;
    var text = '';
    String? action;
    VoidCallback? onTap;

    switch (_loc) {
      case _Loc.idle:
      case _Loc.loading:
        text = 'Mencari lokasimu...';
        break;
      case _Loc.active:
        dot = const Color(0xFF1E9E6A);
        final u = _user!;
        text =
            'Lokasi aktif: ${_userPlace ?? '${u.latitude.toStringAsFixed(3)}, ${u.longitude.toStringAsFixed(3)}'}';
        action = 'Matikan';
        onTap = _turnOff;
        break;
      case _Loc.off:
        text = 'Lokasi dimatikan. Garis dan jarak tidak ditampilkan.';
        action = 'Aktifkan';
        onTap = _requestLocation;
        break;
      case _Loc.denied:
        dot = const Color(0xFFE08A1E);
        text =
            'Izin lokasi belum diberikan. Garis dan jarak tidak ditampilkan.';
        action = 'Izinkan';
        onTap = _requestLocation;
        break;
      case _Loc.deniedForever:
        dot = const Color(0xFFD64545);
        text = 'Izin lokasi ditolak permanen. Buka pengaturan untuk mengaktifkannya.';
        action = 'Pengaturan';
        onTap = () => Geolocator.openAppSettings();
        break;
      case _Loc.serviceOff:
        dot = const Color(0xFFE08A1E);
        text = 'GPS mati. Aktifkan lokasi perangkat untuk melihat jarak.';
        action = 'Aktifkan GPS';
        onTap = () => Geolocator.openLocationSettings();
        break;
      case _Loc.error:
        dot = const Color(0xFFD64545);
        text = 'Gagal membaca lokasi. Coba lagi.';
        action = 'Coba lagi';
        onTap = _requestLocation;
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E2DC)),
      ),
      child: Row(
        children: [
          if (_loc == _Loc.loading || _loc == _Loc.idle)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: const Color(0xFFF1F8F7),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _routePill() {
    final c = _selected!;
    final from = (_userPlace ?? 'Lokasimu').split(',').first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flight_takeoff, size: 16, color: ToolColors.teal),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$from → ${c.shortName} • ${_formatKm(_distanceKm!)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: null,
          backgroundColor: Colors.white,
          foregroundColor: ToolColors.ink,
          onPressed: () =>
              _map.move(_map.camera.center, math.min(17, _map.camera.zoom + 1)),
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: null,
          backgroundColor: Colors.white,
          foregroundColor: ToolColors.ink,
          onPressed: () =>
              _map.move(_map.camera.center, math.max(1, _map.camera.zoom - 1)),
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: null,
          backgroundColor: ToolColors.teal,
          foregroundColor: Colors.white,
          onPressed: () {
            if (_loc == _Loc.active && _user != null) {
              _map.move(_user!, 8);
            } else {
              _requestLocation();
            }
          },
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }

  Widget _bottomCard() {
    final c = _selected;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: c == null ? _hintContent() : _campusContent(c),
    );
  }

  Widget _hintContent() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFFD7F0F0),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.touch_app_outlined, color: ToolColors.teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Ketuk salah satu titik kampus di peta untuk melihat jaraknya '
            'dari lokasimu. (${_visible.length} kampus ditampilkan)',
            style: const TextStyle(fontSize: 12, color: ToolColors.slate),
          ),
        ),
      ],
    );
  }

  Widget _campusContent(MapCampus c) {
    final sameCity = _all
        .where(
          (o) =>
              o.name != c.name &&
              o.city == c.city &&
              chipCountry(o.country) == chipCountry(c.country),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: countryColor(c.country),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                c.place,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ToolColors.slate,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          c.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: ToolColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        _distanceBox(),
        if (sameCity.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Kampus lain di ${c.city}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ToolColors.slate,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final o in sameCity)
                ActionChip(
                  label: Text(
                    o.shortName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: const Color(0xFFF1F8F7),
                  onPressed: () => _select(o),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _distanceBox() {
    final km = _distanceKm;
    if (_loc == _Loc.active && km != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6F2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _stat(
                Icons.near_me_outlined,
                'Jarak dari lokasimu',
                _formatKm(km),
                ToolColors.teal,
              ),
            ),
            Expanded(
              child: _stat(
                Icons.flight_takeoff,
                'Estimasi terbang (kasar)',
                flightDurationText(km),
                ToolColors.brown,
              ),
            ),
          ],
        ),
      );
    }

    final forever = _loc == _Loc.deniedForever;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 20,
            color: ToolColors.brown,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Aktifkan lokasi untuk melihat garis dan jarak ke kampus ini.',
              style: TextStyle(fontSize: 12, color: ToolColors.ink),
            ),
          ),
          if (_loc != _Loc.loading)
            TextButton(
              onPressed: forever
                  ? () => Geolocator.openAppSettings()
                  : _requestLocation,
              child: Text(
                forever ? 'Pengaturan' : 'Aktifkan',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: ToolColors.slate,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatKm(double km) =>
      '${NumberFormat.decimalPattern('id_ID').format(km.round())} km';
}
