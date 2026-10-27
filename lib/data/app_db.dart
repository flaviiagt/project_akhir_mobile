import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/current_user.dart';
import '../services/sync_service.dart';
import 'budget_schema.dart';
import 'models.dart';

/// Penyimpanan lokal (SQLite), terpisah per akun lewat kolom user_id, dan
/// disinkronkan ke Supabase oleh [SyncService].
/// Setiap perubahan menaikkan [version] supaya layar yang mendengarkan
/// (mis. Beranda) otomatis memuat ulang.
class AppDb {
  AppDb._();
  static final AppDb instance = AppDb._();
  static final ValueNotifier<int> version = ValueNotifier<int>(0);
  Database? _db;
  final Map<String, Future<void>> _seeding = {};

  /// Tabel yang disinkronkan (punya kolom rid, mtime, dirty, deleted).
  static const syncedTables = ['checklist', 'itinerary', 'notes', 'quiz_scores'];

  /// Kunci pengaturan yang disinkronkan.
  static const syncedSettings = ['departure'];

  static const _epoch = '1970-01-01T00:00:00.000Z';

  static String _nowIso() =>
      DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch, isUtc: true)
          .toIso8601String();

  static String _newRid() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = kIsWeb ? 'studytrip.db' : join(await getDatabasesPath(), 'studytrip.db');
    return openDatabase(
      path,
      version: 5,
      onConfigure: (d) => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, v) => _createTables(d),
      onUpgrade: (d, oldV, newV) async {
        if (oldV < 2) {
          // v1 -> v2: kolom user_id ditambahkan. Data lama (data uji) dibuang.
          await _dropTables(d);
          await _createTables(d);
          return;
        }
        if (oldV < 3) await _migrateV2toV3(d); // v2 -> v3: kolom sinkronisasi cloud
        if (oldV < 4) await createBudgetTables(d); // v3 -> v4: tabel Anggaran (Anggota 3)
        if (oldV < 5) await _createChainTables(d); // v4 -> v5: catatan blockchain
      },
    );
  }

  Future<void> _dropTables(Database d) async {
    for (final t in ['chain_records', 'expenses', 'budgets', 'checklist', 'itinerary', 'notes', 'quiz_scores', 'settings']) {
      await d.execute('DROP TABLE IF EXISTS $t');
    }
  }

  static const _sync = '''rid TEXT NOT NULL, mtime TEXT NOT NULL,
      dirty INTEGER NOT NULL DEFAULT 0, deleted INTEGER NOT NULL DEFAULT 0''';

  Future<void> _createTables(Database d) async {
    await d.execute('''CREATE TABLE checklist(
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL,
      title TEXT NOT NULL, category TEXT NOT NULL, deadline TEXT,
      done INTEGER NOT NULL DEFAULT 0, $_sync)''');
    await d.execute('''CREATE TABLE itinerary(
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL,
      day TEXT NOT NULL, time TEXT NOT NULL, title TEXT NOT NULL,
      location TEXT, note TEXT, $_sync)''');
    await d.execute('''CREATE TABLE notes(
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL,
      title TEXT NOT NULL, content TEXT, kind TEXT NOT NULL, updated_at TEXT, $_sync)''');
    await d.execute('''CREATE TABLE quiz_scores(
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL,
      score INTEGER NOT NULL, total INTEGER NOT NULL, played_at TEXT NOT NULL, $_sync)''');
    await d.execute('''CREATE TABLE settings(
      user_id TEXT NOT NULL, key TEXT NOT NULL, value TEXT,
      mtime TEXT NOT NULL DEFAULT '$_epoch', dirty INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (user_id, key))''');
    for (final t in syncedTables) {
      await d.execute('CREATE UNIQUE INDEX idx_${t}_rid ON $t(user_id, rid)');
    }
    await createBudgetTables(d); // Anggota 3: Anggaran & Pengeluaran
    await _createChainTables(d); // Catatan blockchain
  }

  /// Catatan blockchain: payload tetap lokal, yang masuk jaringan hanya hash-nya.
  /// Tidak disinkronkan ke Supabase (bukti utamanya ada di blockchain).
  Future<void> _createChainTables(Database d) async {
    await d.execute('''CREATE TABLE IF NOT EXISTS chain_records(
      id INTEGER PRIMARY KEY AUTOINCREMENT, user_id TEXT NOT NULL,
      kind TEXT NOT NULL, title TEXT NOT NULL, payload TEXT NOT NULL, hash TEXT NOT NULL,
      tx_hash TEXT, status TEXT NOT NULL DEFAULT 'draft', block_number INTEGER,
      error TEXT, created_at TEXT NOT NULL)''');
  }

  /// Data lama dipertahankan; semuanya ditandai dirty supaya terkirim ke cloud.
  Future<void> _migrateV2toV3(Database d) async {
    final now = _nowIso();
    for (final t in syncedTables) {
      await d.execute('ALTER TABLE $t ADD COLUMN rid TEXT');
      await d.execute('UPDATE $t SET rid = lower(hex(randomblob(16)))');
      await d.execute("ALTER TABLE $t ADD COLUMN mtime TEXT NOT NULL DEFAULT '$_epoch'");
      await d.execute('ALTER TABLE $t ADD COLUMN dirty INTEGER NOT NULL DEFAULT 0');
      await d.execute('ALTER TABLE $t ADD COLUMN deleted INTEGER NOT NULL DEFAULT 0');
      await d.execute("UPDATE $t SET mtime = '$now', dirty = 1");
      await d.execute('CREATE UNIQUE INDEX idx_${t}_rid ON $t(user_id, rid)');
    }
    await d.execute("ALTER TABLE settings ADD COLUMN mtime TEXT NOT NULL DEFAULT '$_epoch'");
    await d.execute('ALTER TABLE settings ADD COLUMN dirty INTEGER NOT NULL DEFAULT 0');
    await d.execute("UPDATE settings SET mtime = '$now', dirty = 1 WHERE key = 'departure'");
  }

  void _bump() => version.value++;

  /// Dipanggil SyncService setelah data dari cloud masuk.
  void notifyChanged() => _bump();

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

  /// Data contoh, dibuat sekali per akun di tiap perangkat (ditandai 'seeded').
  /// rid-nya tetap (seed-1, seed-2, ...) dan mtime-nya epoch, jadi:
  /// - perangkat lain yang membuat contoh yang sama tidak menghasilkan data dobel,
  /// - perubahan/penghapusan pengguna (mtime baru) selalu mengalahkan data contoh.
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
      for (var i = 0; i < seed.length; i++) {
        b.insert('checklist', {
          ...seed[i].toMap(),
          'user_id': uid,
          'rid': 'seed-${i + 1}',
          'mtime': _epoch,
          'dirty': 0,
          'deleted': 0,
        });
      }
      b.insert('settings',
          {'user_id': uid, 'key': 'departure', 'value': '2027-09-15', 'mtime': _epoch, 'dirty': 0});
      b.insert('settings', {'user_id': uid, 'key': 'seeded', 'value': '1'});
      await b.commit(noResult: true);
    });
  }

  // ---------- Operasi data (selalu dibatasi ke akun aktif) ----------

  Future<List<Map<String, Object?>>> query(String table, {String? orderBy}) async {
    final uid = await _uidReady();
    if (uid == null) return [];
    final notDeleted = syncedTables.contains(table) ? ' AND deleted = 0' : '';
    return (await db).query(table,
        where: 'user_id = ?$notDeleted', whereArgs: [uid], orderBy: orderBy);
  }

  Future<int> insert(String table, Map<String, Object?> values) async {
    final uid = await _uidOrThrow();
    final row = <String, Object?>{...values, 'user_id': uid};
    if (syncedTables.contains(table)) {
      row['rid'] = _newRid();
      row['mtime'] = _nowIso();
      row['dirty'] = 1;
      row['deleted'] = 0;
    }
    final id = await (await db).insert(table, row);
    _bump();
    SyncService.instance.requestSync();
    return id;
  }

  Future<void> update(String table, int id, Map<String, Object?> values) async {
    final uid = await _uidOrThrow();
    final row = <String, Object?>{...values};
    if (syncedTables.contains(table)) {
      row['mtime'] = _nowIso();
      row['dirty'] = 1;
    }
    await (await db).update(table, row, where: 'id = ? AND user_id = ?', whereArgs: [id, uid]);
    _bump();
    SyncService.instance.requestSync();
  }

  /// Hapus lunak: baris ditandai deleted supaya penghapusan ikut tersinkron.
  Future<void> delete(String table, int id) async {
    final uid = await _uidOrThrow();
    if (syncedTables.contains(table)) {
      await (await db).update(table, {'deleted': 1, 'dirty': 1, 'mtime': _nowIso()},
          where: 'id = ? AND user_id = ?', whereArgs: [id, uid]);
    } else {
      await (await db).delete(table, where: 'id = ? AND user_id = ?', whereArgs: [id, uid]);
    }
    _bump();
    SyncService.instance.requestSync();
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
    final synced = syncedSettings.contains(key);
    await (await db).insert(
        'settings',
        {
          'user_id': uid,
          'key': key,
          'value': value,
          if (synced) 'mtime': _nowIso(),
          if (synced) 'dirty': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
    _bump();
    if (synced) SyncService.instance.requestSync();
  }

  Future<List<ChecklistItem>> checklist() async => (await query('checklist',
          orderBy: 'done ASC, deadline IS NULL, deadline ASC'))
      .map(ChecklistItem.fromMap)
      .toList();
}