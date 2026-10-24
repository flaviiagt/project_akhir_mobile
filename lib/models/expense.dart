class Expense {
  final int? id;
  final int budgetId;
  final String name;
  final int amount; // rupiah, bilangan bulat
  final String category;
  final DateTime date;
  final String? note;

  const Expense({
    this.id,
    required this.budgetId,
    required this.name,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  factory Expense.fromMap(Map<String, Object?> m) => Expense(
        id: m['id'] as int?,
        budgetId: m['budget_id'] as int,
        name: m['name'] as String,
        amount: m['amount'] as int,
        category: m['category'] as String,
        date: DateTime.parse(m['date'] as String),
        note: m['note'] as String?,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'budget_id': budgetId,
        'name': name,
        'amount': amount,
        'category': category,
        // simpan tanggal saja: yyyy-MM-dd
        'date': date.toIso8601String().substring(0, 10),
        'note': note,
      };
}
