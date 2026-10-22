import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

/// Penyimpanan lokal (SQLite). Setiap perubahan menaikkan [version]
/// sehingga layar yang mendengarkan (mis. Beranda) otomatis memuat ulang.
class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();
  static final ValueNotifier<int> version = ValueNotifier<int>(0);
  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = kIsWeb ? 'studytrip.db' : join(await getDatabasesPath(), 'studytrip.db');
    return openDatabase(path, version: 1, onCreate: (d, v) async {
      await d.execute('''CREATE TABLE checklist(
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL,
        category TEXT NOT NULL, deadline TEXT, done INTEGER NOT NULL DEFAULT 0)''');
      await d.execute('''CREATE TABLE itinerary(
        id INTEGER PRIMARY KEY AUTOINCREMENT, day TEXT NOT NULL, time TEXT NOT NULL,
        title TEXT NOT NULL, location TEXT, note TEXT)''');
      await d.execute('''CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, content TEXT,
        kind TEXT NOT NULL, updated_at TEXT)''');
      await d.execute('''CREATE TABLE quiz_scores(
        id INTEGER PRIMARY KEY AUTOINCREMENT, score INTEGER NOT NULL,
        total INTEGER NOT NULL, played_at TEXT NOT NULL)''');
      await d.execute('CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)');

      // Data awal contoh; pengguna bebas mengubah/menghapus.
      final now = DateTime.now();
      DateTime plus(int days) => DateTime(now.year, now.month, now.day).add(Duration(days: days));
      final seed = <ChecklistItem>[
        ChecklistItem(title: 'Perpanjang/buat paspor', category: 'Dokumen', deadline: plus(14)),
        ChecklistItem(title: 'Tes bahasa Inggris (IELTS)', category: 'Akademik', deadline: plus(45)),
        ChecklistItem(title: 'Unggah bukti keuangan (CAS)', category: 'Keuangan', deadline: plus(30)),
        ChecklistItem(title: 'Ajukan visa pelajar', category: 'Dokumen', deadline: plus(75)),
        ChecklistItem(title: 'Pesan akomodasi', category: 'Akomodasi', deadline: plus(60)),
        ChecklistItem(title: 'Beli asuransi perjalanan', category: 'Kesehatan', deadline: plus(90)),
      ];
      final b = d.batch();
      for (final s in seed) {
        b.insert('checklist', s.toMap());
      }
      b.insert('settings', {'key': 'destination', 'value': 'Edinburgh, Britania Raya'});
      b.insert('settings', {'key': 'departure', 'value': '2027-09-15'});
      await b.commit(noResult: true);
    });
  }

  void _bump() => version.value++;

  Future<List<Map<String, Object?>>> query(String table, {String? orderBy}) async =>
      (await db).query(table, orderBy: orderBy);

  Future<int> insert(String table, Map<String, Object?> values) async {
    final id = await (await db).insert(table, values);
    _bump();
    return id;
  }

  Future<void> update(String table, int id, Map<String, Object?> values) async {
    await (await db).update(table, values, where: 'id = ?', whereArgs: [id]);
    _bump();
  }

  Future<void> delete(String table, int id) async {
    await (await db).delete(table, where: 'id = ?', whereArgs: [id]);
    _bump();
  }

  Future<String?> getSetting(String key) async {
    final r = await (await db).query('settings', where: 'key = ?', whereArgs: [key]);
    return r.isEmpty ? null : r.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    await (await db).insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
    _bump();
  }

  Future<List<ChecklistItem>> checklist() async => (await query('checklist',
          orderBy: 'done ASC, deadline IS NULL, deadline ASC'))
      .map(ChecklistItem.fromMap)
      .toList();
}
