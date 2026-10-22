const kCategories = ['Dokumen', 'Keuangan', 'Akademik', 'Akomodasi', 'Kesehatan', 'Lainnya'];

DateTime? parseDate(Object? v) => v == null ? null : DateTime.tryParse(v as String);
String? fmtDate(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class ChecklistItem {
  final int? id;
  final String title;
  final String category;
  final DateTime? deadline;
  final bool done;
  const ChecklistItem({this.id, required this.title, required this.category, this.deadline, this.done = false});

  factory ChecklistItem.fromMap(Map<String, Object?> m) => ChecklistItem(
        id: m['id'] as int,
        title: m['title'] as String,
        category: m['category'] as String,
        deadline: parseDate(m['deadline']),
        done: (m['done'] as int) == 1,
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'category': category,
        'deadline': fmtDate(deadline),
        'done': done ? 1 : 0,
      };
}

class ItineraryItem {
  final int? id;
  final DateTime day;
  final String time; // "HH:mm"
  final String title;
  final String location;
  final String note;
  const ItineraryItem({this.id, required this.day, required this.time, required this.title, this.location = '', this.note = ''});

  factory ItineraryItem.fromMap(Map<String, Object?> m) => ItineraryItem(
        id: m['id'] as int,
        day: DateTime.parse(m['day'] as String),
        time: m['time'] as String,
        title: m['title'] as String,
        location: (m['location'] as String?) ?? '',
        note: (m['note'] as String?) ?? '',
      );

  Map<String, Object?> toMap() => {
        'day': fmtDate(day),
        'time': time,
        'title': title,
        'location': location,
        'note': note,
      };
}

class NoteItem {
  final int? id;
  final String title;
  final String content;
  final String kind; // 'catatan' | 'program'
  const NoteItem({this.id, required this.title, required this.content, required this.kind});

  factory NoteItem.fromMap(Map<String, Object?> m) => NoteItem(
        id: m['id'] as int,
        title: m['title'] as String,
        content: (m['content'] as String?) ?? '',
        kind: m['kind'] as String,
      );

  Map<String, Object?> toMap() => {
        'title': title,
        'content': content,
        'kind': kind,
        'updated_at': DateTime.now().toIso8601String(),
      };
}
