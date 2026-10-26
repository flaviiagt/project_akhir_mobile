import 'package:flutter/material.dart';

import '../data/universities.dart';
import '../theme/app_theme.dart';
import '../widgets/studytrip_app_bar.dart';
import 'campus_map_page.dart';
import 'university_detail_page.dart';

class ExplorationPage extends StatefulWidget {
  const ExplorationPage({super.key});

  @override
  State<ExplorationPage> createState() => _ExplorationPageState();
}

class _ExplorationPageState extends State<ExplorationPage> {
  final _searchCtrl = TextEditingController();
  String _selectedCountry = 'Semua';

  List<String> get _countries => [
    'Semua',
    ...kUniversities.map((university) => university.country).toSet().toList()
      ..sort(),
  ];

  List<University> get _filteredUniversities {
    final query = _searchCtrl.text.trim().toLowerCase();
    return kUniversities.where((university) {
      final matchesCountry =
          _selectedCountry == 'Semua' || university.country == _selectedCountry;
      final matchesQuery =
          query.isEmpty ||
          university.name.toLowerCase().contains(query) ||
          university.city.toLowerCase().contains(query) ||
          university.country.toLowerCase().contains(query);
      return matchesCountry && matchesQuery;
    }).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final universities = _filteredUniversities;

    return Scaffold(
      backgroundColor: ToolColors.cream,
      appBar: const StudyTripAppBar(title: 'Eksplorasi'),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: const Color(0xFFE5E2DC)),
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 13,
                          color: ToolColors.ink,
                        ),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: ToolColors.slate,
                          ),
                          hintText: 'Cari kampus, kota, atau negara...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: ToolColors.slate,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                              selectedColor: ToolColors.teal,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : ToolColors.navy,
                              ),
                              shape: const StadiumBorder(),
                              side: BorderSide(
                                color: selected
                                    ? Colors.transparent
                                    : const Color(0xFFE5E2DC),
                              ),
                              onSelected: (_) =>
                                  setState(() => _selectedCountry = country),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'KAMPUS PILIHAN',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w800,
                              color: ToolColors.brown,
                            ),
                          ),
                        ),
                        Text(
                          '${universities.length} kampus',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ToolColors.slate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              Expanded(
                child: universities.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada kampus yang cocok dengan pencarian.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                        itemCount: universities.length,
                        itemBuilder: (context, index) =>
                            _UniversityCard(university: universities[index]),
                      ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              heroTag: 'open_campus_map',
              tooltip: 'Peta Kampus Dunia',
              backgroundColor: ToolColors.teal,
              foregroundColor: Colors.white,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CampusMapPage()),
              ),
              child: const Icon(Icons.public),
            ),
          ),
        ],
      ),
    );
  }
}

class _UniversityCard extends StatelessWidget {
  final University university;

  const _UniversityCard({required this.university});

  @override
  Widget build(BuildContext context) {
    final imagePath = university.asset;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ToolColors.navy.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: imagePath == null
                      ? _imageFallback()
                      : Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _imageFallback(),
                        ),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.68),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      university.place,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        university.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: ToolColors.ink,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        university.country,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ToolColors.slate,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(university.icon, color: ToolColors.teal, size: 22),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        UniversityDetailPage(university: university),
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text('Lihat detail kampus'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ToolColors.teal,
                  side: BorderSide(
                    color: ToolColors.teal.withValues(alpha: 0.35),
                  ),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: university.c2,
      alignment: Alignment.center,
      child: Icon(university.icon, color: Colors.white70, size: 44),
    );
  }
}
