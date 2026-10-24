import 'package:sqflite/sqflite.dart';

import 'app_db.dart';

/// Pintu database untuk fitur Anggaran. Memakai database bersama [AppDb]
/// (satu file studytrip.db untuk seluruh aplikasi). Tabelnya dibuat di
/// AppDb lewat budget_schema.dart.
class AppDatabase {
  AppDatabase._(this._testDb);

  static final AppDatabase instance = AppDatabase._(null);

  /// Khusus pengujian: pakai database yang diberikan (mis. in-memory).
  factory AppDatabase.forTesting(Database db) => AppDatabase._(db);

  final Database? _testDb;

  Future<Database> get database async => _testDb ?? await AppDb.instance.db;

  Future<void> close() async => _testDb?.close();
}
