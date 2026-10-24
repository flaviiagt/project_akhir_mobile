import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'app_db.dart';

/// Pembuka database SQLite lokal.
///
/// CATATAN TIM: idealnya satu file database dipakai bersama. Anggota lain
/// cukup menambah tabelnya sendiri di [_onCreate] (dan naikkan [_dbVersion]
/// + isi [_onUpgrade] jika sudah ada yang menginstal aplikasinya).
class AppDatabase {
  AppDatabase._(this._pathOverride);

  static final AppDatabase instance = AppDatabase._(null);

  /// Database di memori, khusus untuk pengujian.
  factory AppDatabase.inMemory() => AppDatabase._(inMemoryDatabasePath);

  static const _dbName = 'studytrip.db';
  static const _dbVersion = 1;

  final String? _pathOverride;
  Database? _db;

  Future<Database> get database async {
    if (_pathOverride != null) {
      return _db ??= await _open();
    }
    return AppDb.instance.db;
  }

  Future<Database> _open() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String path;
    if (_pathOverride != null) {
      path = _pathOverride;
    } else if (kIsWeb) {
      path = _dbName;
    } else {
      path = join(await getDatabasesPath(), _dbName);
    }

    return openDatabase(
      path,
      version: _dbVersion,
      singleInstance: _pathOverride == null,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // ---- Tabel milik Anggota 3 (Budget & Expense) ----
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        total_amount INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        budget_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        amount INTEGER NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (budget_id) REFERENCES budgets(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_budgets_user ON budgets(user_id)');
    await db.execute('CREATE INDEX idx_expenses_budget ON expenses(budget_id)');
    // ---- Tabel anggota lain ditambahkan di bawah sini ----
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
