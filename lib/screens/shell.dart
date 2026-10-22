import 'package:flutter/material.dart';
import 'home_screen.dart';

/// Bottom navigation: Beranda | Anggaran | Alat | Eksplorasi | Profil.
/// Hanya Beranda yang menjadi bagian Member 2; tab lain adalah placeholder
/// untuk diganti saat integrasi dengan Member 1 dan Member 3.
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const _Placeholder('Anggaran', 'Budget & Expense Manager (Member 3)'),
      const _Placeholder('Alat & Utilitas', 'Konversi kurs, zona waktu, sensor (Member 3)'),
      const _Placeholder('Eksplorasi Kota', 'Pencarian destinasi, cuaca, peta (Member 3)'),
      const _Placeholder('Profil', 'Profil, biometrik, Saran & Kesan, logout (Member 1)'),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Beranda'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Anggaran'),
          NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Alat'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Eksplorasi'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  final String note;
  const _Placeholder(this.title, this.note);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text('Halaman ini belum diimplementasikan.\n$note', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
