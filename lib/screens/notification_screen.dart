import 'package:flutter/material.dart';
import '../core/app_routes.dart';
import '../data/app_db.dart';
import '../data/models.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'checklist_screen.dart';

/// Tugas checklist yang belum selesai dan terlambat / jatuh tempo <= 3 hari.
Future<List<ChecklistItem>> dueReminders() async {
  final items = await AppDb.instance.checklist();
  return items
      .where((e) => !e.done && e.deadline != null && daysUntil(e.deadline!) <= 3)
      .toList()
    ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
}

String _when(int n) {
  if (n < 0) return 'Terlambat ${-n} hari';
  if (n == 0) return 'Hari ini';
  if (n == 1) return 'Besok';
  return '$n hari lagi';
}

/// Notifikasi di dalam aplikasi: dipanggil sekali saat aplikasi dibuka.
Future<void> showDueReminderBanner(BuildContext context) async {
  final due = await dueReminders();
  if (due.isEmpty || !context.mounted) return;
  final first = due.first;
  final text = due.length == 1
      ? '${_when(daysUntil(first.deadline!))}: ${first.title}'
      : '${due.length} tugas mendekati deadline, termasuk "${first.title}"';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 7),
    content: Text(text),
    action: SnackBarAction(
      label: 'Lihat',
      onPressed: () => navigatorKey.currentState
          ?.push(MaterialPageRoute(builder: (_) => const NotificationScreen())),
    ),
  ));
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});
  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<ChecklistItem> _due = [];
  NotifStatus _status = NotifStatus.off;
  int _pending = 0;
  bool _loading = true;

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
    final due = await dueReminders();
    final status = await NotificationService.instance.status();
    final pending = await NotificationService.instance.pendingCount();
    if (!mounted) return;
    setState(() {
      _due = due;
      _status = status;
      _pending = pending;
      _loading = false;
    });
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  void _openChecklist() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChecklistScreen()));

  Future<void> _done(ChecklistItem it) async {
    await AppDb.instance.update('checklist', it.id!, {'done': 1});
    _snack('"${it.title}" ditandai selesai');
  }

  Future<void> _toggle(bool want) async {
    final s = await NotificationService.instance.setReminders(want);
    if (want && s == NotifStatus.denied) {
      _snack('Izin ditolak. Aktifkan lewat Pengaturan HP > Aplikasi > StudyTrip > Notifikasi.');
    }
    await _load();
  }

  Future<void> _testNow() async {
    if (_status == NotifStatus.unsupported) {
      _snack('Notifikasi HP hanya muncul di aplikasi Android/iOS, bukan di browser.');
      return;
    }
    if (_status == NotifStatus.denied) {
      _snack('Izin notifikasi belum diberikan.');
      return;
    }
    await NotificationService.instance.show(
        'Tes notifikasi StudyTrip', 'Jika ini muncul di bar atas HP, notifikasi sudah berfungsi.');
  }

  Future<void> _testScheduled() async {
    final ok = await NotificationService.instance.scheduleTest();
    _snack(ok
        ? 'Terjadwal. Tutup aplikasi dan tunggu sekitar 1 menit.'
        : 'Tidak bisa dijadwalkan (izin belum ada atau tidak didukung di perangkat ini).');
  }

  Widget _permissionCard() {
    final (title, text, icon, tone) = switch (_status) {
      NotifStatus.on => (
          'Pengingat di HP aktif',
          'Kamu diingatkan 3 hari sebelum, 1 hari sebelum, dan pada hari deadline (pukul 09.00, lalu 17.00 bila belum selesai), juga saat aplikasi ditutup.',
          Icons.notifications_active,
          kPrimary,
        ),
      NotifStatus.off => (
          'Pengingat di HP dimatikan',
          'Pengingat di dalam aplikasi tetap tampil. Nyalakan untuk menerimanya di HP.',
          Icons.notifications_off_outlined,
          kSecondary,
        ),
      NotifStatus.denied => (
          'Izin notifikasi belum diberikan',
          'Izinkan notifikasi agar pengingat deadline muncul di HP, juga saat aplikasi ditutup.',
          Icons.notifications_paused_outlined,
          kAmberDark,
        ),
      NotifStatus.unsupported => (
          'Notifikasi HP tidak tersedia di browser',
          'Pengingat di dalam aplikasi tetap tampil. Notifikasi HP hanya berjalan di aplikasi Android/iOS.',
          Icons.desktop_windows_outlined,
          kSecondary,
        ),
    };
    final supported = _status != NotifStatus.unsupported;
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, color: tone),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: headlineStyle(16, weight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontSize: 13, color: kSecondary)),
            ]),
          ),
          if (supported)
            Switch(value: _status == NotifStatus.on, onChanged: _toggle),
        ]),
        if (_status == NotifStatus.on && _pending > 0) ...[
          const SizedBox(height: 10),
          Text('$_pending pengingat terjadwal di HP',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kPrimary)),
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          TextButton.icon(
            onPressed: _testNow,
            icon: const Icon(Icons.send_outlined, size: 18),
            label: const Text('Tes notifikasi'),
          ),
          if (supported)
            TextButton.icon(
              onPressed: _testScheduled,
              icon: const Icon(Icons.schedule, size: 18),
              label: const Text('Tes 1 menit lagi'),
            ),
        ]),
      ]),
    );
  }

  Widget _section(String title, List<ChecklistItem> items, Color tone) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionTitle(title),
      for (final it in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SoftCard(
            onTap: _openChecklist,
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Icon(Icons.alarm, color: tone, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    '${_when(daysUntil(it.deadline!))} • ${dateFmt.format(it.deadline!)} • ${it.category}',
                    style: TextStyle(fontSize: 12, color: tone == kDanger ? kDanger : kSecondary),
                  ),
                ]),
              ),
              IconButton(
                tooltip: 'Tandai selesai',
                onPressed: () => _done(it),
                icon: const Icon(Icons.check_circle_outline, color: kPrimary),
              ),
            ]),
          ),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final overdue = _due.where((e) => daysUntil(e.deadline!) < 0).toList();
    final today = _due.where((e) => daysUntil(e.deadline!) == 0).toList();
    final tomorrow = _due.where((e) => daysUntil(e.deadline!) == 1).toList();
    final soon = _due.where((e) => daysUntil(e.deadline!) >= 2).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
                _permissionCard(),
                if (_due.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyState(
                      icon: Icons.notifications_none,
                      message: 'Tidak ada tugas yang jatuh tempo dalam 3 hari ke depan.',
                    ),
                  )
                else ...[
                  _section('Terlambat', overdue, kDanger),
                  _section('Hari ini', today, kAmberDark),
                  _section('Besok', tomorrow, kPrimary),
                  _section('3 hari ke depan', soon, kSecondary),
                ],
              ]),
            ),
    );
  }
}