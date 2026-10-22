import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/st_widgets.dart';
import '../profile/profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  // FR-30: Beranda, Anggaran, Alat, Eksplorasi, Profil
  final _pages = const [
    _Placeholder('Beranda', Icons.home_outlined), // Anggota 2
    _Placeholder(
      'Anggaran',
      Icons.account_balance_wallet_outlined,
    ), // Anggota 3
    _Placeholder('Alat', Icons.construction), // Anggota 3
    _Placeholder('Eksplorasi', Icons.travel_explore), // Anggota 3
    ProfilePage(), // Anggota 1
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Anggaran',
          ),
          NavigationDestination(
            icon: Icon(Icons.construction_outlined),
            selectedIcon: Icon(Icons.construction),
            label: 'Alat',
          ),
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore),
            label: 'Eksplorasi',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  final IconData icon;
  const _Placeholder(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StAppBar(title: title),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.teal),
            const SizedBox(height: 12),
            Text('Halaman $title', style: AppText.headline(20)),
            const SizedBox(height: 4),
            const Text(
              'Dikerjakan anggota lain',
              style: TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
