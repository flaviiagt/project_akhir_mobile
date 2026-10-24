import 'package:flutter/material.dart';

import '../config.dart';
import '../data/budget_repository.dart';
import '../models/budget.dart';
import '../models/budget_summary.dart';
import '../models/expense.dart';
import '../theme/app_theme.dart';
import '../utils/category_style.dart';
import '../utils/format.dart';
import '../widgets/studytrip_app_bar.dart';
import 'budget_form_page.dart';
import 'expense_form_page.dart';

/// Layar "Anggaran": ringkasan, kategori, dan daftar transaksi.
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key, this.userId = kTempUserId});

  final int userId;

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  final _repo = BudgetRepository();

  Budget? _budget;
  List<Expense> _expenses = [];
  BudgetSummary? _summary;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final budgets = await _repo.getBudgets(widget.userId);
      if (budgets.isEmpty) {
        _budget = null;
        _expenses = [];
        _summary = null;
      } else {
        _budget = budgets.firstWhere(
          (b) => b.id == _budget?.id,
          orElse: () => budgets.first,
        );
        _expenses = await _repo.getExpenses(_budget!.id!);
        _summary = await _repo.getSummary(_budget!);
      }
    } catch (e, st) {
      debugPrint('LOAD ERROR: $e\n$st');
      _error = 'Gagal memuat data anggaran. Coba lagi.';
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _openBudgetForm({Budget? budget}) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetFormPage(userId: widget.userId, budget: budget),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _openExpenseForm({Expense? expense}) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ExpenseFormPage(budgetId: _budget!.id!, expense: expense),
      ),
    );
    if (ok == true) _load();
  }

  Future<void> _confirmDelete(Expense e) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pengeluaran?'),
        content: Text('"${e.name}" (${formatRupiah(e.amount)}) akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await _repo.deleteExpense(e.id!);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus pengeluaran.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StudyTripAppBar(
        title: 'Anggaran',
        actions: [
          if (_budget != null)
            IconButton(
              tooltip: 'Ubah anggaran',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _openBudgetForm(budget: _budget),
            ),
        ],
      ),
      floatingActionButton: _budget == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openExpenseForm(),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Tambah Pengeluaran'),
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        title: _error!,
        action: FilledButton(onPressed: _load, child: const Text('Coba lagi')),
      );
    }

    if (_budget == null) {
      return _Message(
        icon: Icons.savings_outlined,
        title: 'Belum ada anggaran',
        subtitle: 'Buat anggaran perjalanan studimu untuk mulai mencatat.',
        action: FilledButton.icon(
          onPressed: () => _openBudgetForm(),
          icon: const Icon(Icons.add),
          label: const Text('Buat Anggaran'),
        ),
      );
    }

    final s = _summary!;
    final categories = s.byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
        children: [
          _SummaryCard(budget: _budget!, summary: s),
          if (categories.isNotEmpty) ...[
            const _SectionTitle('Per Kategori'),
            ...categories.map(
              (e) => _CategoryTile(
                category: e.key,
                amount: e.value,
                share: s.spent <= 0 ? 0 : e.value / s.spent,
              ),
            ),
          ],
          const _SectionTitle('Transaksi Terbaru'),
          if (_expenses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('Belum ada pengeluaran. ✈️')),
            )
          else
            ..._expenses.map(
              (e) => _ExpenseTile(
                expense: e,
                onEdit: () => _openExpenseForm(expense: e),
                onDelete: () => _confirmDelete(e),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widget kecil
// ---------------------------------------------------------------------------

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: Color(0xFFD7F0F0),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: ToolColors.teal),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.budget, required this.summary});

  final Budget budget;
  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    final over = summary.isOverBudget;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: over
              ? const [Color(0xFF7A1F1F), Color(0xFFB23A3A)]
              : const [ToolColors.navy, ToolColors.navyLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x2EFFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flight_takeoff, size: 16, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    budget.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            over ? 'Melebihi anggaran' : 'Sisa Anggaran',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 2),
          Text(
            formatRupiah(over ? -summary.remaining : summary.remaining),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: summary.usedFraction.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: const Color(0x33FFFFFF),
              color: over ? const Color(0xFFFFB4A8) : ToolColors.mint,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total ${formatRupiah(summary.total)}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                '${summary.usedPercent}% terpakai',
                style: TextStyle(
                  color: over ? const Color(0xFFFFB4A8) : ToolColors.mint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Terpakai ${formatRupiah(summary.spent)}',
            style: const TextStyle(color: Colors.white70),
          ),
          if (over) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD27A)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pengeluaranmu sudah melewati total anggaran.',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.amount,
    required this.share,
  });

  final String category;
  final int amount;
  final double share;

  @override
  Widget build(BuildContext context) {
    final st = categoryStyle(category);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: st.bg, shape: BoxShape.circle),
            child: Icon(st.icon, color: st.fg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        category,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      formatRupiah(amount),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: share.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: st.bg,
                    color: st.fg,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.onEdit,
    required this.onDelete,
  });

  final Expense expense;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final st = categoryStyle(expense.category);
    final hasNote = (expense.note ?? '').isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: st.bg, shape: BoxShape.circle),
            child: Icon(st.icon, color: st.fg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatDate(expense.date)} • ${expense.category}',
                  style: const TextStyle(fontSize: 12, color: ToolColors.slate),
                ),
                if (hasNote)
                  Text(
                    expense.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: ToolColors.slate,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '-${formatRupiah(expense.amount)}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: ToolColors.brown,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'hapus') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'hapus', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }
}
