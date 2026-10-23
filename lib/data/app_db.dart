import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/current_user.dart';
import 'models.dart';

/// Penyimpanan lokal (SQLite), terpisah per akun lewat kolom user_id.
/// Setiap perubahan menaikkan [version] supaya layar yang mendengarkan
/// (mis. Beranda) otomatis memuat ulang.
class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();
  static final ValueNotifier<int> version = ValueNotifier<int>(0);
  Database? _db;
  final Map<String, Future<void>> _seeding = {};

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = kIsWeb ? 'studytrip.db' : join(await getDatabasesPath(), 'studytrip.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (d, v) => _createTables(d),
      // v1 -> v2: kolom user_id ditambahkan. Data lama (data uji) dibuang.
      onUpgrade: (d, oldV, newV) async {
        await _dropTables(d);
        await _createTables(d);
      },
    );
  }

  Future<void> _dropTables(Database d) async {
    for (final t in ['checklist', 'itinerary', 'notes', 'quiz_scores', 'settings']) {
      await d.execute('DROP TABLE IF EXISTS $t');
    }
  }

  Future<void> _createTables(Database d) async {
    await d.execute('''CREATE TABLE checklist(
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL,
      title TEXT NOT NULL, category TEXT NOT NULL, deadline TEXT,
      done INTEGER NOT NULL DEFAULT 0)''');
    await d.execute('''CREATE TABLE itinerary(
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL,
      day TEXT NOT NULL, time TEXT NOT NULL, title TEXT NOT NULL,
      location TEXT, note TEXT)''');
    await d.execute('''CREATE TABLE notes(
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL,
      title TEXT NOT NULL, content TEXT, kind TEXT NOT NULL, updated_at TEXT)''');
    await d.execute('''CREATE TABLE quiz_scores(
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL,
      score INTEGER NOT NULL, total INTEGER NOT NULL, played_at TEXT NOT NULL)''');
    await d.execute('''CREATE TABLE settings(
      user_id TEXT NOT NULL, key TEXT NOT NULL, value TEXT,
      PRIMARY KEY (user_id, key))''');
  }

  void _bump() => version.value++;

  // ---------- Pemilik data ----------

  /// User id aktif, setelah memastikan data contoh akun itu sudah ada.
  /// Null jika belum login.
  Future<String?> _uidReady() async {
    final uid = CurrentUser.id;
    if (uid == null) return null;
    await _ensureSeed(uid);
    return uid;
  }

  Future<String> _uidOrThrow() async {
    final uid = await _uidReady();
    if (uid == null) throw StateError('Tidak ada akun yang login');
    return uid;
  }

  Future<void> _ensureSeed(String uid) async {
    final f = _seeding.putIfAbsent(uid, () => _seed(uid));
    try {
      await f;
    } catch (_) {
      _seeding.remove(uid);
      rethrow;
    }
  }

  /// Data contoh, dibuat sekali per akun (ditandai oleh setting 'seeded').
  Future<void> _seed(String uid) async {
    final d = await db;
    final done = await d.query('settings',
        where: 'user_id = ? AND key = ?', whereArgs: [uid, 'seeded']);
    if (done.isNotEmpty) return;

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
    await d.transaction((txn) async {
      final b = txn.batch();
      for (final s in seed) {
        b.insert('checklist', {...s.toMap(), 'user_id': uid});
      }
      b.insert('settings', {'user_id': uid, 'key': 'destination', 'value': 'Edinburgh, Britania Raya'});
      b.insert('settings', {'user_id': uid, 'key': 'departure', 'value': '2027-09-15'});
      b.insert('settings', {'user_id': uid, 'key': 'seeded', 'value': '1'});
      await b.commit(noResult: true);
    });
  }

  // ---------- Operasi data (selalu dibatasi ke akun aktif) ----------

  Future<List<Map<String, Object?>>> query(String table, {String? orderBy}) async {
    final uid = await _uidReady();
    if (uid == null) return [];
    return (await db).query(table, where: 'user_id = ?', whereArgs: [uid], orderBy: orderBy);
  }

  Future<int> insert(String table, Map<String, Object?> values) async {
    final uid = await _uidOrThrow();
    final id = await (await db).insert(table, {...values, 'user_id': uid});
    _bump();
    return id;
  }

  Future<void> update(String table, int id, Map<String, Object?> values) async {
    final uid = await _uidOrThrow();
    await (await db).update(table, values, where: 'id = ? AND user_id = ?', whereArgs: [id, uid]);
    _bump();
  }

  Future<void> delete(String table, int id) async {
    final uid = await _uidOrThrow();
    await (await db).delete(table, where: 'id = ? AND user_id = ?', whereArgs: [id, uid]);
    _bump();
  }

  Future<String?> getSetting(String key) async {
    final uid = await _uidReady();
    if (uid == null) return null;
    final r = await (await db).query('settings',
        where: 'user_id = ? AND key = ?', whereArgs: [uid, key]);
    return r.isEmpty ? null : r.first['value'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final uid = await _uidOrThrow();
    await (await db).insert('settings', {'user_id': uid, 'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
    _bump();
  }

  Future<List<ChecklistItem>> checklist() async => (await query('checklist',
          orderBy: 'done ASC, deadline IS NULL, deadline ASC'))
      .map(ChecklistItem.fromMap)
      .toList();
}
