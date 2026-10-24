import '../models/budget.dart';
import '../models/budget_summary.dart';
import '../models/expense.dart';
import 'app_database.dart';

/// Semua operasi database untuk anggaran dan pengeluaran (FR-11 s.d. FR-13).
class BudgetRepository {
  BudgetRepository({AppDatabase? db}) : _db = db ?? AppDatabase.instance;

  final AppDatabase _db;

  // ---------- Anggaran ----------

  Future<int> createBudget(Budget b) async {
    final db = await _db.database;
    return db.insert('budgets', b.toMap());
  }

  Future<void> updateBudget(Budget b) async {
    final db = await _db.database;
    await db.update(
      'budgets',
      {'name': b.name, 'total_amount': b.totalAmount},
      where: 'id = ? AND user_id = ?',
      whereArgs: [b.id, b.userId],
    );
  }

  /// Hanya anggaran milik [userId] (data tiap akun terpisah).
  Future<List<Budget>> getBudgets(int userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'budgets',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(Budget.fromMap).toList();
  }

  Future<void> deleteBudget(int budgetId, int userId) async {
    final db = await _db.database;
    await db.delete('budgets',
        where: 'id = ? AND user_id = ?', whereArgs: [budgetId, userId]);
  }

  // ---------- Pengeluaran (CRUD) ----------

  Future<int> addExpense(Expense e) async {
    final db = await _db.database;
    return db.insert('expenses', e.toMap());
  }

  Future<void> updateExpense(Expense e) async {
    final db = await _db.database;
    await db.update('expenses', e.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [e.id]);
  }

  Future<void> deleteExpense(int id) async {
    final db = await _db.database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Expense>> getExpenses(int budgetId) async {
    final db = await _db.database;
    final rows = await db.query(
      'expenses',
      where: 'budget_id = ?',
      whereArgs: [budgetId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  // ---------- Ringkasan ----------

  Future<BudgetSummary> getSummary(Budget budget) async {
    final db = await _db.database;
    final rows = await db.rawQuery(
      'SELECT category, SUM(amount) AS total FROM expenses '
      'WHERE budget_id = ? GROUP BY category',
      [budget.id],
    );
    final byCategory = <String, int>{};
    var spent = 0;
    for (final r in rows) {
      final t = (r['total'] as int?) ?? 0;
      byCategory[r['category'] as String] = t;
      spent += t;
    }
    return BudgetSummary(
      total: budget.totalAmount,
      spent: spent,
      byCategory: byCategory,
    );
  }
}
