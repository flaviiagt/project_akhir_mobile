import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'campus_map_page.dart';
import '../data/weather_repository.dart';
import '../models/exploration_item.dart';
import '../theme/app_theme.dart';
import '../widgets/campus_map_sheet.dart';
import '../widgets/studytrip_app_bar.dart';

/// Halaman Eksplorasi: Pencarian kota, negara, kampus impian, dan kurasi akademik.
class ExplorationPage extends StatefulWidget {
  const ExplorationPage({super.key});

  @override
  State<ExplorationPage> createState() => _ExplorationPageState();
}

class _ExplorationPageState extends State<ExplorationPage> {
  final _searchCtrl = TextEditingController();
  final WeatherRepository _weatherRepo = WeatherRepository();
  bool _isLoadingWeather = false;
  String _selectedCountry = 'Semua';

  final List<String> _countries = [
    'Semua',
    'GB United Kingdom',
    'NL Belanda',
    'AU Australia',
    'DE Jerman',
    'JP Jepang',
  ];

  late CityItem _featuredCity = const CityItem(
    id: 'edinburgh',
    name: 'Edinburgh',
    emoji: '🏰',
    region: 'SKOTLANDIA, BRITANIA RAYA',
    tag: 'Pilihan Utama LPDP',
    description:
        'Pusat riset kelas dunia berpadu harmoni dengan arsitektur bersejarah yang megah dan budaya akademik prestisius.',
    weather: '17°C Berawan Sejuk',
    weatherTip: 'Mantel tipis disarankan',
    ppiCommunity: 'PPI Edinburgh',
    ppiCount: '320+ mahasiswa aktif',
    livingCost: '£1.100 - £1.300/bln',
    livingCostIdr: '± Rp 22 - 26 jt',
    lpdpStandard: 'Sesuai standar LPDP',
    imageUrl:
        'https://images.unsplash.com/photo-1506377247377-2a5b3b417ebb?auto=format&fit=crop&w=1000&q=80',
    isFavorite: false,
  );

  late List<CampusItem> _campuses = [
    const CampusItem(
      id: 'edinburgh_uni',
      name: 'The University of Edinburgh',
      location: 'Edinburgh, UK',
      country: 'United Kingdom',
      countryCode: 'GB',
      qsRank: '#22 Dunia',
      description:
          'Terkenal dengan program Informatika, Kedokteran, dan Sastra Klasik. Rumah bagi 20+ peraih Nobel.',
      tags: [
        CampusTag(
          label: 'Beasiswa LPDP',
          icon: Icons.school_outlined,
          bg: Color(0xFFE6F7F5),
          fg: AppColors.teal,
        ),
        CampusTag(
          label: 'AI & Data Pioneer',
          icon: Icons.psychology_outlined,
          bg: Color(0xFFEDF4FE),
          fg: Color(0xFF1B5A8C),
        ),
      ],
      tuition: '£26.500 - £38.000/thn',
      imageUrl:
          'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=1000&q=80',
      popularMajor: 'Computer Science, Medicine, Law',
      latitude: 55.9445,
      longitude: -3.1892,
      isBookmarked: true,
      isComparing: true,
    ),
    const CampusItem(
      id: 'tu_delft',
      name: 'TU Delft (Delft University of Technology)',
      location: 'Delft, Belanda',
      country: 'Belanda',
      countryCode: 'NL',
      qsRank: '#47 Dunia',
      description:
          'Institut teknologi tertua dan terbesar di Belanda, unggul dalam Arsitektur, Teknik Sipil, dan Energi Terbarukan.',
      tags: [
        CampusTag(
          label: 'Erasmus+ Eligible',
          icon: Icons.flight_takeoff,
          bg: Color(0xFFF1ECFC),
          fg: Color(0xFF6B3FA0),
        ),
        CampusTag(
          label: '#3 Arsitektur Dunia',
          icon: Icons.apartment_outlined,
          bg: Color(0xFFFFF4E5),
          fg: AppColors.brown,
        ),
      ],
      tuition: '€15.200 - €21.000/thn',
      imageUrl:
          'https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=1000&q=80',
      popularMajor: 'Architecture, Civil Engineering, Aerospace',
      latitude: 52.0016,
      longitude: 4.3708,
      isBookmarked: false,
      isComparing: true,
    ),
    const CampusItem(
      id: 'oxford_uni',
      name: 'University of Oxford',
      location: 'Oxford, UK',
      country: 'United Kingdom',
      countryCode: 'GB',
      qsRank: '#3 Dunia',
      description:
          'Universitas tertua di dunia berbahasa Inggris dengan reputasi akademik tak tertandingi dan jaringan alumni global.',
      tags: [
        CampusTag(
          label: 'Beasiswa LPDP',
          icon: Icons.school_outlined,
          bg: Color(0xFFE6F7F5),
          fg: AppColors.teal,
        ),
        CampusTag(
          label: 'Riset Biomedis',
          icon: Icons.biotech_outlined,
          bg: Color(0xFFEDF4FE),
          fg: Color(0xFF1B5A8C),
        ),
      ],
      tuition: '£28.000 - £44.000/thn',
      imageUrl:
          'https://images.unsplash.com/photo-1580983561371-7f4b242d8ec0?auto=format&fit=crop&w=1000&q=80',
      popularMajor: 'Philosophy, Politics, Biomedical Science',
      latitude: 51.7548,
      longitude: -1.2544,
      isBookmarked: false,
      isComparing: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (_isLoadingWeather) return;
    setState(() => _isLoadingWeather = true);

    try {
      final data = await _weatherRepo.getWeatherForCity('Edinburgh');
      if (mounted) {
        setState(() {
          _featuredCity = _featuredCity.copyWith(
            weather: data.displaySummary,
            weatherTip: data.clothingTip,
          );
          _isLoadingWeather = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  void _openCampusMap(String title, String location, double lat, double lon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CampusMapSheet(
        campusName: title,
        locationName: location,
        latitude: lat,
        longitude: lon,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CampusItem> get _filteredCampuses {
    final query = _searchCtrl.text.toLowerCase().trim();
    return _campuses.where((c) {
      final matchesCountry = _selectedCountry == 'Semua' ||
          c.countryCode == _selectedCountry.split(' ').first;
      final matchesQuery = query.isEmpty ||
          c.name.toLowerCase().contains(query) ||
          c.location.toLowerCase().contains(query) ||
          c.description.toLowerCase().contains(query) ||
          c.popularMajor.toLowerCase().contains(query);
      return matchesCountry && matchesQuery;
    }).toList();
  }

  List<CampusItem> get _comparingCampuses =>
      _campuses.where((c) => c.isComparing).toList();

  void _toggleBookmark(String id) {
    setState(() {
      _campuses = _campuses.map((c) {
        if (c.id == id) {
          return c.copyWith(isBookmarked: !c.isBookmarked);
        }
        return c;
      }).toList();
    });
  }

  void _toggleComparing(String id) {
    setState(() {
      _campuses = _campuses.map((c) {
        if (c.id == id) {
          return c.copyWith(isComparing: !c.isComparing);
        }
        return c;
      }).toList();
    });
  }

  void _openComparisonModal() {
    final list = _comparingCampuses;
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal 1 kampus untuk dibandingkan.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CampusComparisonModal(campuses: list),
    );
  }

  void _openCampusDetail(CampusItem campus) async {
    CampusItem? targetMapCampus;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CampusDetailModal(
        campus: campus,
        onToggleBookmark: () => _toggleBookmark(campus.id),
        onToggleCompare: () => _toggleComparing(campus.id),
        onOpenMap: (c) {
          targetMapCampus = c;
          Navigator.of(ctx).pop();
        },
      ),
    );
    if (targetMapCampus != null && mounted) {
      _openCampusMap(
        targetMapCampus!.name,
        targetMapCampus!.location,
        targetMapCampus!.latitude,
        targetMapCampus!.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final campuses = _filteredCampuses;
    final compareCount = _comparingCampuses.length;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: StudyTripAppBar(
        title: 'Eksplorasi',
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
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
            children: [
              // Search Bar
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFFE5E2DC)),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Icon(Icons.search, color: AppColors.slate, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 13, color: AppColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'Cari kota, negara, atau kampus impian...',
                          hintStyle: TextStyle(fontSize: 13, color: AppColors.slate),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune_rounded, color: AppColors.slate, size: 20),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Filter Chips (Negara)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _countries.map((country) {
                    final selected = _selectedCountry == country;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(country),
                        selected: selected,
                        showCheckmark: false,
                        selectedColor: AppColors.teal,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppColors.navy,
                        ),
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: selected ? Colors.transparent : const Color(0xFFE5E2DC),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        onSelected: (_) {
                          setState(() {
                            _selectedCountry = country;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Featured City Card (Edinburgh) - Gambar 2
              _buildFeaturedCityCard(),

              const SizedBox(height: 28),

              // Kurasi Akademik Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'KURASI AKADEMIK',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brown,
                    ),
                  ),
                  InkWell(
                    onTap: () {},
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Semua',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.teal),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Campus Cards List
              if (campuses.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('Tidak ada kampus yang cocok dengan pencarian.'),
                  ),
                )
              else
                ...campuses.map((c) => _buildCampusCard(c)),
            ],
          ),

                    // Tombol mengambang: buka Peta Kampus Dunia (LBS)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              heroTag: 'open_campus_map',
              tooltip: 'Peta Kampus Dunia',
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CampusMapPage()),
              ),
              child: const Icon(Icons.public),
            ),
          ),

          // Floating Comparison Button (Bandingkan Kampus 2)
          if (compareCount > 0)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(99),
                  elevation: 8,
                  shadowColor: Colors.black45,
                  child: InkWell(
                    onTap: _openComparisonModal,
                    borderRadius: BorderRadius.circular(99),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.balance_rounded, color: Color(0xFFFFD27A), size: 18),
                          const SizedBox(width: 10),
                          const Text(
                            'Bandingkan Kampus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: const BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$compareCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget Featured City Card (Sesuai Gambar 2)
  Widget _buildFeaturedCityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Image Card with Gradient Overlay
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Container(
              constraints: const BoxConstraints(minHeight: 280),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_featuredCity.imageUrl),
                  fit: BoxFit.cover,
                  onError: (e, s) {},
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.25),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge & Favorite row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.settings, size: 13, color: AppColors.brown),
                              const SizedBox(width: 5),
                              Text(
                                _featuredCity.tag,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.brown,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 19,
                          backgroundColor: Colors.white,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              _featuredCity.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border_rounded,
                              color: _featuredCity.isFavorite ? Colors.red : AppColors.slate,
                              size: 19,
                            ),
                            onPressed: () {
                              setState(() {
                                _featuredCity = _featuredCity.copyWith(
                                  isFavorite: !_featuredCity.isFavorite,
                                );
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // Location Tag
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFFFD27A), size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _featuredCity.region,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFFD27A),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // City Name with Emoji
                    Text(
                      '${_featuredCity.name} ${_featuredCity.emoji}',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Description
                    Text(
                      _featuredCity.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Weather & PPI Pills
                    Row(
                      children: [
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Memperbarui cuaca Edinburgh via Open-Meteo REST API...'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                await _fetchWeather();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Cuaca saat ini: ${_featuredCity.weather} • ${_featuredCity.weatherTip}',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    _isLoadingWeather
                                        ? const SizedBox(
                                            width: 17,
                                            height: 17,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.cloud_outlined, color: Colors.white, size: 17),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _featuredCity.weather,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            _isLoadingWeather ? 'Memperbarui...' : _featuredCity.weatherTip,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.groups_outlined, color: Colors.white, size: 17),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _featuredCity.ppiCommunity,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        _featuredCity.ppiCount,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Living Cost Section (Anti-Overflow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2F8F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payments_outlined, color: Color(0xFF0E8A63), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'ESTIMASI BIAYA HIDUP',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          text: _featuredCity.livingCost.split('/')[0],
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                          children: const [
                            TextSpan(
                              text: '/bln',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8F6F6),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _featuredCity.livingCostIdr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF007A80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _featuredCity.lpdpStandard,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, color: AppColors.slate),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Tombol Buka Peta Edinburgh (LBS)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openCampusMap(
                'Edinburgh, UK',
                'Skotlandia, Britania Raya',
                55.9533,
                -3.1883,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map_rounded, color: AppColors.teal, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Peta Lokasi & Jarak dari RI (LBS)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: const Text(
                        'FR-19',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
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

  // Widget Campus Card (Sesuai Gambar 1)
  Widget _buildCampusCard(CampusItem c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Campus Header Photo
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Stack(
              children: [
                Container(
                  height: 190,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E2DC),
                    image: DecorationImage(
                      image: NetworkImage(c.imageUrl),
                      fit: BoxFit.cover,
                      onError: (e, s) {},
                    ),
                  ),
                ),
                // Gradient tint on image bottom
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // QS Rank Badge
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 13, color: AppColors.brown),
                        const SizedBox(width: 4),
                        Text(
                          'QS Rank ${c.qsRank}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bookmark Icon
                Positioned(
                  top: 14,
                  right: 14,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        c.isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
                        color: c.isBookmarked ? AppColors.teal : AppColors.slate,
                        size: 20,
                      ),
                      onPressed: () => _toggleBookmark(c.id),
                    ),
                  ),
                ),
                // Location badge at bottom-left of photo
                Positioned(
                  bottom: 12,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      c.location,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Campus Body Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  c.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 12),

                // Tags Row
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: c.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: tag.bg,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tag.icon, size: 14, color: tag.fg),
                          const SizedBox(width: 5),
                          Text(
                            tag.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: tag.fg,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // Tuition & Detail Button Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F6F2),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimasi Biaya Kuliah',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.slate,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              c.tuition,
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
                          minimumSize: const Size(70, 36),
                        ),
                        onPressed: () => _openCampusDetail(c),
                        child: const Text(
                          'Detail',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
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
}

/// Modal Perbandingan Kampus (Bandingkan Kampus)
class _CampusComparisonModal extends StatelessWidget {
  final List<CampusItem> campuses;

  const _CampusComparisonModal({required this.campuses});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD7F0F0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.balance_rounded, color: AppColors.teal, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Komparasi Kampus',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Perbandingan langsung biaya, reputasi & beasiswa',
                        style: TextStyle(fontSize: 11, color: AppColors.slate),
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
          ),

          const Divider(height: 1),

          // Comparison content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _compareRow(
                  title: 'Nama Kampus',
                  values: campuses.map((c) => c.name).toList(),
                  isHeader: true,
                ),
                _compareRow(
                  title: 'QS World Rank',
                  values: campuses.map((c) => c.qsRank).toList(),
                ),
                _compareRow(
                  title: 'Lokasi & Negara',
                  values: campuses.map((c) => c.location).toList(),
                ),
                _compareRow(
                  title: 'Estimasi Biaya Kuliah',
                  values: campuses.map((c) => c.tuition).toList(),
                ),
                _compareRow(
                  title: 'Jurusan Populer',
                  values: campuses.map((c) => c.popularMajor).toList(),
                ),
                _compareRow(
                  title: 'Fasilitas Beasiswa',
                  values: campuses
                      .map((c) => c.tags.map((t) => t.label).join(', '))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _compareRow({
    required String title,
    required List<String> values,
    bool isHeader = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHeader ? const Color(0xFFD7F0F0) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isHeader ? AppColors.teal : AppColors.brown,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: values.map((val) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    val,
                    style: TextStyle(
                      fontSize: isHeader ? 14 : 13,
                      fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Modal Detail Profil Kampus
class _CampusDetailModal extends StatelessWidget {
  final CampusItem campus;
  final VoidCallback onToggleBookmark;
  final VoidCallback onToggleCompare;
  final ValueChanged<CampusItem>? onOpenMap;

  const _CampusDetailModal({
    required this.campus,
    required this.onToggleBookmark,
    required this.onToggleCompare,
    this.onOpenMap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header image with close button
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(campus.imageUrl),
                      fit: BoxFit.cover,
                      onError: (e, s) {},
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.ink),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'QS Rank ${campus.qsRank}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brown,
                        ),
                      ),
                    ),
                    Text(
                      campus.location,
                      style: const TextStyle(fontSize: 12, color: AppColors.slate),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  campus.name,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  campus.description,
                  style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.ink),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Jurusan Unggulan:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.slate),
                ),
                const SizedBox(height: 4),
                Text(
                  campus.popularMajor,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Estimasi Biaya:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.slate),
                ),
                const SizedBox(height: 4),
                Text(
                  campus.tuition,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 16),
                // Tombol LBS & Peta Kampus
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onOpenMap?.call(campus),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F7),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.teal.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: AppColors.teal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Peta Kampus & LBS',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      '• FR-19',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.teal,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Buka peta OpenStreetMap & kalkulasi jarak geospasial',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.teal,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.teal),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          onToggleCompare();
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          campus.isComparing ? Icons.check : Icons.balance_rounded,
                          color: AppColors.teal,
                          size: 18,
                        ),
                        label: Text(
                          campus.isComparing ? 'Terpilih' : 'Bandingkan',
                          style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          onToggleBookmark();
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          campus.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          size: 18,
                        ),
                        label: Text(
                          campus.isBookmarked ? 'Tersimpan' : 'Simpan',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
