import 'package:sqflite/sqflite.dart';

/// Tabel Anggaran & Pengeluaran (Anggota 3). Dibuat oleh AppDb (satu file
/// database untuk seluruh aplikasi) dan oleh pengujian.
Future<void> createBudgetTables(Database d) async {
  await d.execute('''
    CREATE TABLE IF NOT EXISTS budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      total_amount INTEGER NOT NULL,
      created_at TEXT NOT NULL
    )
  ''');
  await d.execute('''
    CREATE TABLE IF NOT EXISTS expenses (
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
  await d.execute('CREATE INDEX IF NOT EXISTS idx_budgets_user ON budgets(user_id)');
  await d.execute('CREATE INDEX IF NOT EXISTS idx_expenses_budget ON expenses(budget_id)');
}
