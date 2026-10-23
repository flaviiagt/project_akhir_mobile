import 'package:flutter/material.dart';
import '../data/universities.dart';

/// Bottom sheet pilih kampus (dengan pencarian).
/// Mengembalikan kampus terpilih, atau null jika ditutup tanpa memilih.
Future<University?> pickUniversity(BuildContext context, {String? selected}) {
  return showModalBottomSheet<University>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (ctx) => _UniversityPicker(selected: selected),
  );
}

class _UniversityPicker extends StatefulWidget {
  final String? selected;
  const _UniversityPicker({this.selected});
  @override
  State<_UniversityPicker> createState() => _UniversityPickerState();
}

class _UniversityPickerState extends State<_UniversityPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final list = kUniversities
        .where((u) =>
            _q.isEmpty || u.name.toLowerCase().contains(_q) || u.place.toLowerCase().contains(_q))
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Pilih kampus tujuan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Cari kampus atau negara',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('Kampus tidak ditemukan'))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final u = list[i];
                        final sel = u.name == widget.selected;
                        return Material(
                          color: sel ? cs.primary.withValues(alpha: 0.10) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.pop(context, u),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: sel ? cs.primary : const Color(0x1A0F2537), width: 1.5),
                              ),
                              child: Row(children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(colors: [u.c1, u.c2]),
                                  ),
                                  child: Icon(u.icon, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(u.name,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                    Text(u.place,
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7B8A))),
                                  ]),
                                ),
                                if (sel) Icon(Icons.check_circle, color: cs.primary),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}