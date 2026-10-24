import 'package:flutter/material.dart';
import '../data/app_db.dart';
import '../data/models.dart';
import '../screens/notification_screen.dart';
import '../theme/app_theme.dart';
import 'common.dart';

/// Lonceng notifikasi: badge = tugas checklist yang terlambat atau jatuh tempo
/// dalam 3 hari. Diketuk -> halaman Notifikasi.
class ReminderBell extends StatefulWidget {
  const ReminderBell({super.key});

  @override
  State<ReminderBell> createState() => _ReminderBellState();
}

class _ReminderBellState extends State<ReminderBell> {
  int _count = 0;

  @override
  void initState() {
    super.initState();
    AppDb.version.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppDb.version.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final items = await AppDb.instance.checklist();
    final n = items
        .where((ChecklistItem e) => !e.done && e.deadline != null && daysUntil(e.deadline!) <= 3)
        .length;
    if (!mounted) return;
    setState(() => _count = n);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifikasi',
      onPressed: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const NotificationScreen())),
      icon: Badge(
        isLabelVisible: _count > 0,
        label: Text('$_count'),
        child: const Icon(Icons.notifications_none, color: kSecondary),
      ),
    );
  }
}