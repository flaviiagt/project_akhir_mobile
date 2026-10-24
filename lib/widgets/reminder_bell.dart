import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../data/app_db.dart';
import '../data/models.dart';
import '../screens/checklist_screen.dart';
import 'common.dart';

/// Lonceng pengingat: badge = tugas checklist yang terlambat atau jatuh tempo
/// dalam 3 hari. Diketuk -> daftar pengingat.
class ReminderBell extends StatefulWidget {
  const ReminderBell({super.key});

  @override
  State<ReminderBell> createState() => _ReminderBellState();
}

class _ReminderBellState extends State<ReminderBell> {
  List<ChecklistItem> _due = [];

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
    final due = items
        .where((e) => !e.done && e.deadline != null && daysUntil(e.deadline!) <= 3)
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
    if (!mounted) return;
    setState(() => _due = due);
  }

  String _when(DateTime d) {
    final n = daysUntil(d);
    if (n < 0) return 'Terlambat ${-n} hari';
    if (n == 0) return 'Hari ini';
    return '$n hari lagi';
  }

  Future<void> _show() async {
    final nav = Navigator.of(context);
    await showFormSheet<void>(context, (c) {
      void openChecklist() {
        Navigator.pop(c);
        nav.push(MaterialPageRoute(builder: (_) => const ChecklistScreen()));
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pengingat', style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_due.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Tidak ada tugas yang jatuh tempo dalam 3 hari ke depan.'),
            )
          else
            for (final it in _due)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.alarm, color: daysUntil(it.deadline!) < 0 ? kDanger : kPrimary),
                title: Text(it.title),
                subtitle: Text('${_when(it.deadline!)} • ${dateFmt.format(it.deadline!)}'),
                onTap: openChecklist,
              ),
          const SizedBox(height: 8),
          TextButton(onPressed: openChecklist, child: const Text('Buka Checklist')),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Pengingat',
      onPressed: _show,
      icon: Badge(
        isLabelVisible: _due.isNotEmpty,
        label: Text('${_due.length}'),
        child: const Icon(Icons.notifications_none, color: kSecondary),
      ),
    );
  }
}
