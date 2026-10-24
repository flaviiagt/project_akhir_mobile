import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/current_user.dart';
import '../../pages/budget_page.dart';
import '../../pages/exploration_page.dart';
import '../../pages/tools_page.dart';
import '../../screens/home_screen.dart';
import '../profile/profile_page.dart';

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final userId = int.tryParse(CurrentUser.id ?? '') ?? kTempUserId;
    final pages = [
      HomeScreen(onProfileTap: () => setState(() => _index = 4)), // Beranda (Anggota 2)
      BudgetPage(userId: userId),                                  // Anggaran (Anggota 3)
      const ToolsPage(),                                          // Alat & Utilitas (Anggota 3)
      const ExplorationPage(),                                    // Eksplorasi (Anggota 3)
      const ProfilePage(),                                        // Profil (Anggota 1)
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
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
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman),
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
