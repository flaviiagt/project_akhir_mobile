/// Ringkasan anggaran (FR-13). Murni hitungan, mudah diuji.
class BudgetSummary {
  final int total;
  final int spent;
  final Map<String, int> byCategory;

  const BudgetSummary({
    required this.total,
    required this.spent,
    required this.byCategory,
  });

  int get remaining => total - spent;
  bool get isOverBudget => spent > total;
  double get usedFraction => total <= 0 ? 0 : spent / total;
  int get usedPercent => (usedFraction * 100).round();
}
