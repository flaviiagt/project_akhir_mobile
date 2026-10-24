import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/shell_events.dart';
import '../../pages/budget_page.dart';
import '../../pages/exploration_page.dart';
import '../../pages/tools_page.dart';
import '../../screens/home_screen.dart';
import '../profile/profile_page.dart';
import '../../core/app_routes.dart';
import '../../screens/notification_screen.dart';
import '../../services/notification_service.dart';

class MainShell extends StatefulWidget {
  /// Tab awal (0 Beranda, 1 Anggaran, 2 Alat, 3 Eksplorasi, 4 Profil).
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    shellTabRequest.addListener(_onTabRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Notifikasi di dalam app: ringkasan tugas yang mendekati deadline
      await showDueReminderBanner(context);
      // Aplikasi dibuka dengan mengetuk notifikasi di HP -> langsung ke halamannya
      if (await NotificationService.instance.launchedFromNotification()) {
        navigatorKey.currentState
            ?.push(MaterialPageRoute(builder: (_) => const NotificationScreen()));
      }
    });
  }

  @override
  void dispose() {
    shellTabRequest.removeListener(_onTabRequest);
    super.dispose();
  }

  // Widget mana pun bisa meminta pindah tab (mis. foto profil -> tab Profil).
  void _onTabRequest() {
    final i = shellTabRequest.value;
    if (i == null) return;
    shellTabRequest.value = null;
    if (mounted) setState(() => _index = i);
  }

  // FR-30: Beranda, Anggaran, Alat, Eksplorasi, Profil
  // Anggaran memakai id akun yang login, jadi daftar dibuat saat build.
  List<Widget> _buildPages() => [
    const HomeScreen(), // Anggota 2
    BudgetPage(userId: currentBudgetUserId()), // Anggota 3
    const ToolsPage(), // Anggota 3
    const ExplorationPage(), // Anggota 3
    const ProfilePage(), // Anggota 1
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _buildPages()),
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
