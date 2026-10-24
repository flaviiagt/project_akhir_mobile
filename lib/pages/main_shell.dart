import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'budget_page.dart';
import 'exploration_page.dart';
import 'tools_page.dart';

const _teal = AppColors.teal;
const _navy = AppColors.navy;
const _cream = AppColors.cream;

/// Kerangka utama aplikasi dengan bottom navigation (FR-30).
/// Pasang di main.dart:  home: const MainShell()
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 1; // mulai dari Anggaran karena itu yang sudah jadi

  // IndexedStack menjaga state tiap tab (input tidak hilang saat pindah tab).
  late final List<Widget> _pages = const [
    _Placeholder('Beranda'),
    BudgetPage(),
    ToolsPage(),
    ExplorationPage(),
    _Placeholder('Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: _cream,
          indicatorColor: _teal.withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return GoogleFonts.beVietnamPro(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? _teal : _navy.withValues(alpha: 0.6),
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
                color: selected ? _teal : _navy.withValues(alpha: 0.6));
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Beranda'),
            NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: 'Anggaran'),
            NavigationDestination(
                icon: Icon(Icons.handyman_outlined),
                selectedIcon: Icon(Icons.handyman),
                label: 'Alat'),
            NavigationDestination(
                icon: Icon(Icons.travel_explore_outlined),
                selectedIcon: Icon(Icons.travel_explore),
                label: 'Eksplorasi'),
            NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil'),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  const _Placeholder(this.title);

  @override
  Widget build(BuildContext context) => Center(
        child: Text('$title — segera hadir',
            style: GoogleFonts.beVietnamPro(fontSize: 16)),
      );
}