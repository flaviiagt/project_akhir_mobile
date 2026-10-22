import 'package:flutter/material.dart';
import '../data/app_db.dart';
import '../data/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key});
  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  List<ItineraryItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await AppDb.instance.query('itinerary', orderBy: 'day ASC, time ASC');
    if (!mounted) return;
    setState(() {
      _items = rows.map(ItineraryItem.fromMap).toList();
      _loading = false;
    });
  }

  Future<void> _form([ItineraryItem? existing]) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final loc = TextEditingController(text: existing?.location ?? '');
    final note = TextEditingController(text: existing?.note ?? '');
    DateTime day = existing?.day ?? DateTime.now();
    TimeOfDay time = existing == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : TimeOfDay(
            hour: int.parse(existing.time.split(':')[0]),
            minute: int.parse(existing.time.split(':')[1]));
    String? error;

    await showFormSheet<void>(context, (c) => StatefulBuilder(builder: (c, setS) {
          return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(existing == null ? 'Tambah Agenda' : 'Ubah Agenda', style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(controller: title, decoration: InputDecoration(labelText: 'Kegiatan', errorText: error)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event),
                  label: Text(dateFmt.format(day)),
                  onPressed: () async {
                    final p = await showDatePicker(
                      context: c,
                      initialDate: day,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 6)),
                    );
                    if (p != null) setS(() => day = p);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule),
                  label: Text(time.format(c)),
                  onPressed: () async {
                    final p = await showTimePicker(context: c, initialTime: time);
                    if (p != null) setS(() => time = p);
                  },
                ),
              ),
            ]),
            const SizedBox(height: 12),
            TextField(controller: loc, decoration: const InputDecoration(labelText: 'Lokasi (opsional)')),
            const SizedBox(height: 12),
            TextField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'Catatan (opsional)')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) {
                  setS(() => error = 'Nama kegiatan wajib diisi');
                  return;
                }
                final item = ItineraryItem(
                  id: existing?.id,
                  day: day,
                  time: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  title: title.text.trim(),
                  location: loc.text.trim(),
                  note: note.text.trim(),
                );
                if (existing == null) {
                  await AppDb.instance.insert('itinerary', item.toMap());
                } else {
                  await AppDb.instance.update('itinerary', existing.id!, item.toMap());
                }
                await _load();
                if (c.mounted) Navigator.pop(c);
              },
              child: const Text('Simpan'),
            ),
          ]);
        }));
  }

  Future<void> _delete(ItineraryItem it) async {
    await AppDb.instance.delete('itinerary', it.id!);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    DateTime? lastDay;
    for (final it in _items) {
      if (lastDay == null || lastDay != it.day) {
        children.add(SectionTitle(dateLongFmt.format(it.day)));
        lastDay = it.day;
      }
      children.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Dismissible(
          key: ValueKey('it-${it.id}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => confirmDelete(context, it.title),
          onDismissed: (_) => _delete(it),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: kDanger, borderRadius: BorderRadius.circular(kCardRadius)),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: SoftCard(
            onTap: () => _form(it),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: kTealTint, borderRadius: BorderRadius.circular(12)),
                child: Text(it.time, style: const TextStyle(fontWeight: FontWeight.w700, color: kPrimary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (it.location.isNotEmpty)
                    Row(children: [
                      const Icon(Icons.place_outlined, size: 14),
                      const SizedBox(width: 4),
                      Expanded(child: Text(it.location, style: const TextStyle(fontSize: 12))),
                    ]),
                  if (it.note.isNotEmpty) Text(it.note, style: const TextStyle(fontSize: 12)),
                ]),
              ),
            ]),
          ),
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Itinerary')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Agenda'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const EmptyState(icon: Icons.map_outlined, message: 'Belum ada agenda perjalanan.\nTambahkan agenda pertamamu.')
              : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 96), children: children),
    );
  }
}
