import 'package:flutter/material.dart';
import '../data/app_db.dart';
import '../data/models.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'progress_proof_screen.dart';

class ChecklistScreen extends StatefulWidget {
  const ChecklistScreen({super.key});
  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  List<ChecklistItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppDb.instance.checklist();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _save(ChecklistItem item) async {
    if (item.id == null) {
      await AppDb.instance.insert('checklist', item.toMap());
    } else {
      await AppDb.instance.update('checklist', item.id!, item.toMap());
    }
    await NotificationService.instance.rescheduleAll();
    await _load();
  }

  void _openProof() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => const ProgressProofScreen()));

  Future<void> _toggle(ChecklistItem it) async {
    await AppDb.instance.update('checklist', it.id!, {'done': it.done ? 0 : 1});
    await NotificationService.instance.rescheduleAll();
    await _load();
  }

  Future<void> _delete(ChecklistItem it) async {
    await AppDb.instance.delete('checklist', it.id!);
    await NotificationService.instance.rescheduleAll();
    await _load();
  }

  Future<void> _form([ChecklistItem? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    String category = existing?.category ?? kCategories.first;
    DateTime? deadline = existing?.deadline;
    String? error;

    await showFormSheet<void>(context, (c) => StatefulBuilder(builder: (c, setS) {
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(existing == null ? 'Tambah Tugas' : 'Ubah Tugas', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: title, decoration: InputDecoration(labelText: 'Nama tugas', errorText: error)),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [for (final k in kCategories) DropdownMenuItem(value: k, child: Text(k))],
              onChanged: (v) => setS(() => category = v ?? category),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(deadline == null ? 'Tanpa deadline' : dateFmt.format(deadline!)),
                  onPressed: () async {
                    final p = await showDatePicker(
                      context: c,
                      initialDate: deadline ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 6)),
                    );
                    if (p != null) setS(() => deadline = p);
                  },
                ),
              ),
              if (deadline != null)
                IconButton(onPressed: () => setS(() => deadline = null), icon: const Icon(Icons.clear)),
            ]),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) {
                  setS(() => error = 'Nama tugas wajib diisi');
                  return;
                }
                await _save(ChecklistItem(
                  id: existing?.id,
                  title: title.text.trim(),
                  category: category,
                  deadline: deadline,
                  done: existing?.done ?? false,
                ));
                if (c.mounted) Navigator.pop(c);
              },
              child: const Text('Simpan'),
            ),
          ]);
        }));
  }

  IconData _icon(String c) => switch (c) {
        'Dokumen' => Icons.description_outlined,
        'Keuangan' => Icons.payments_outlined,
        'Akademik' => Icons.school_outlined,
        'Akomodasi' => Icons.home_work_outlined,
        'Kesehatan' => Icons.health_and_safety_outlined,
        _ => Icons.label_outline,
      };

  @override
  Widget build(BuildContext context) {
    final done = _items.where((e) => e.done).length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist Persiapan'),
        actions: [
          IconButton(
            tooltip: 'Bukti progres',
            icon: const Icon(Icons.verified_outlined),
            onPressed: _openProof,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(icon: Icons.checklist, message: 'Belum ada tugas persiapan.\nKetuk "Tambah" untuk memulai.')
              : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 96), children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 4),
                    child: Text('$done dari ${_items.length} selesai'),
                  ),
                  if (done == _items.length)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SoftCard(
                        color: kTealTint,
                        shadow: false,
                        onTap: _openProof,
                        child: Row(children: [
                          const Icon(Icons.verified_user_outlined, color: kPrimary),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Semua tugas selesai! Segel progresmu sebagai bukti.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: kSecondary),
                        ]),
                      ),
                    ),
                  for (final it in _items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey('cl-${it.id}'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => confirmDelete(context, it.title),
                        onDismissed: (_) => _delete(it),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(color: kDanger, borderRadius: BorderRadius.circular(kCardRadius)),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: _tile(it),
                      ),
                    ),
                ]),
    );
  }

  Widget _tile(ChecklistItem it) {
    final d = it.deadline == null ? null : daysUntil(it.deadline!);
    final late = !it.done && d != null && d < 0;
    return SoftCard(
      onTap: () => _form(it),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(children: [
        Checkbox(value: it.done, activeColor: kPrimary, onChanged: (_) => _toggle(it)),
        Icon(_icon(it.category), color: kSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(it.title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  decoration: it.done ? TextDecoration.lineThrough : null,
                )),
            Text(
              it.deadline == null
                  ? it.category
                  : '${it.category} • ${dateFmt.format(it.deadline!)}${late ? ' • terlambat' : ''}',
              style: TextStyle(fontSize: 12, color: late ? kDanger : null),
            ),
          ]),
        ),
      ]),
    );
  }
}
