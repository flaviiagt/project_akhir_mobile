import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:studytrip/data/app_database.dart';
import 'package:studytrip/data/budget_repository.dart';
import 'package:studytrip/logic/validators.dart';
import 'package:studytrip/models/budget.dart';
import 'package:studytrip/models/budget_summary.dart';
import 'package:studytrip/models/expense.dart';

void main() {
  group('Validators.amount', () {
    test('menolak kosong, nol, negatif, dan tidak valid', () {
      expect(Validators.amount(null), isNotNull);
      expect(Validators.amount(''), isNotNull);
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-5000'), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount('12.5'), isNotNull);
    });
    test('menerima nominal valid', () {
      expect(Validators.amount('15000000'), isNull);
      expect(Validators.parseAmount(' 2500 '), 2500);
    });
  });

  group('BudgetSummary', () {
    test('hitung sisa, persen, dan kondisi melebihi anggaran', () {
      const ok = BudgetSummary(total: 1000, spent: 380, byCategory: {});
      expect(ok.remaining, 620);
      expect(ok.usedPercent, 38);
      expect(ok.isOverBudget, false);

      const over = BudgetSummary(total: 1000, spent: 1200, byCategory: {});
      expect(over.remaining, -200);
      expect(over.isOverBudget, true);
    });
  });

  group('BudgetRepository (SQLite)', () {
    late AppDatabase db;
    late BudgetRepository repo;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      db = AppDatabase.inMemory();
      repo = BudgetRepository(db: db);
    });

    tearDown(() => db.close());

    Future<Budget> makeBudget({int userId = 1, int total = 30000000}) async {
      final id = await repo.createBudget(Budget(
        userId: userId,
        name: 'Studi Edinburgh',
        totalAmount: total,
        createdAt: DateTime(2026, 10, 22),
      ));
      return (await repo.getBudgets(userId)).firstWhere((b) => b.id == id);
    }

    Expense exp(int budgetId, int amount, String cat) => Expense(
          budgetId: budgetId,
          name: 'Item $amount',
          amount: amount,
          category: cat,
          date: DateTime(2026, 10, 22),
        );

    test('tambah, ringkasan, edit, hapus memperbarui perhitungan', () async {
      final b = await makeBudget(total: 30000000);
      await repo.addExpense(exp(b.id!, 15000000, 'Akomodasi'));
      await repo.addExpense(exp(b.id!, 8200000, 'Visa & Paspor'));

      var s = await repo.getSummary(b);
      expect(s.spent, 23200000);
      expect(s.remaining, 6800000);
      expect(s.byCategory['Akomodasi'], 15000000);

      final list = await repo.getExpenses(b.id!);
      expect(list.length, 2);

      final first = list.first;
      await repo.updateExpense(Expense(
        id: first.id,
        budgetId: first.budgetId,
        name: first.name,
        amount: 1000,
        category: first.category,
        date: first.date,
      ));
      s = await repo.getSummary(b);
      expect(s.spent, lessThan(23200000));

      for (final e in await repo.getExpenses(b.id!)) {
        await repo.deleteExpense(e.id!);
      }
      s = await repo.getSummary(b);
      expect(s.spent, 0);
      expect(await repo.getExpenses(b.id!), isEmpty);
    });

    test('anggaran terlampaui ditandai', () async {
      final b = await makeBudget(total: 1000);
      await repo.addExpense(exp(b.id!, 1500, 'Lainnya'));
      final s = await repo.getSummary(b);
      expect(s.isOverBudget, true);
    });

    test('data tiap akun terpisah', () async {
      await makeBudget(userId: 1);
      await makeBudget(userId: 2);
      expect((await repo.getBudgets(1)).length, 1);
      expect((await repo.getBudgets(2)).length, 1);
      expect(await repo.getBudgets(3), isEmpty);
    });

    test('hapus anggaran ikut menghapus pengeluarannya', () async {
      final b = await makeBudget();
      await repo.addExpense(exp(b.id!, 5000, 'Lainnya'));
      await repo.deleteBudget(b.id!, 1);
      expect(await repo.getExpenses(b.id!), isEmpty);
    });
  });
}
