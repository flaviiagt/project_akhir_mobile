import 'package:flutter/material.dart';
import '../data/app_db.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<NoteItem> _all = [];
  String _filter = 'semua'; // semua | catatan | program
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await AppDb.instance.query('notes', orderBy: 'updated_at DESC');
    if (!mounted) return;
    setState(() {
      _all = rows.map(NoteItem.fromMap).toList();
      _loading = false;
    });
  }

  Future<void> _form([NoteItem? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final content = TextEditingController(text: existing?.content ?? '');
    String kind = existing?.kind ?? (_filter == 'program' ? 'program' : 'catatan');
    String? error;

    await showFormSheet<void>(context, (c) => StatefulBuilder(builder: (c, setS) {
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(existing == null ? 'Tambah Catatan' : 'Ubah Catatan', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'catatan', label: Text('Catatan')),
                ButtonSegment(value: 'program', label: Text('Info Program')),
              ],
              selected: {kind},
              onSelectionChanged: (s) => setS(() => kind = s.first),
            ),
            const SizedBox(height: 12),
            TextField(controller: title, decoration: InputDecoration(labelText: 'Judul', errorText: error)),
            const SizedBox(height: 12),
            TextField(controller: content, maxLines: 6, decoration: const InputDecoration(labelText: 'Isi')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) {
                  setS(() => error = 'Judul wajib diisi');
                  return;
                }
                final n = NoteItem(id: existing?.id, title: title.text.trim(), content: content.text.trim(), kind: kind);
                if (existing == null) {
                  await AppDb.instance.insert('notes', n.toMap());
                } else {
                  await AppDb.instance.update('notes', existing.id!, n.toMap());
                }
                await _load();
                if (c.mounted) Navigator.pop(c);
              },
              child: const Text('Simpan'),
            ),
          ]);
        }));
  }

  Future<void> _delete(NoteItem n) async {
    await AppDb.instance.delete('notes', n.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filter == 'semua' ? _all : _all.where((n) => n.kind == _filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan & Info Program')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Catatan'),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            for (final f in const [('semua', 'Semua'), ('catatan', 'Catatan'), ('program', 'Info Program')])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f.$2),
                  selected: _filter == f.$1,
                  onSelected: (_) => setState(() => _filter = f.$1),
                ),
              ),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : shown.isEmpty
                  ? const EmptyState(icon: Icons.sticky_note_2_outlined, message: 'Belum ada catatan.')
                  : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), children: [
                      for (final n in shown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Dismissible(
                            key: ValueKey('nt-${n.id}'),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (_) => confirmDelete(context, n.title),
                            onDismissed: (_) => _delete(n),
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              decoration: BoxDecoration(color: kDanger, borderRadius: BorderRadius.circular(kCardRadius)),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            child: SoftCard(
                              onTap: () => _form(n),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: n.kind == 'program' ? kBlueTint : kAmberTint,
                                        borderRadius: BorderRadius.circular(10)),
                                    child: Text(n.kind == 'program' ? 'Program' : 'Catatan', style: const TextStyle(fontSize: 11)),
                                  ),
                                ]),
                                if (n.content.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(n.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                                ],
                              ]),
                            ),
                          ),
                        ),
                    ]),
        ),
      ]),
    );
  }
}
