class Budget {
  final int? id;
  final int userId;
  final String name;

  /// Disimpan sebagai bilangan bulat rupiah (tanpa desimal) agar tidak ada
  /// error pembulatan.
  final int totalAmount;
  final DateTime createdAt;

  const Budget({
    this.id,
    required this.userId,
    required this.name,
    required this.totalAmount,
    required this.createdAt,
  });

  factory Budget.fromMap(Map<String, Object?> m) => Budget(
        id: m['id'] as int?,
        userId: m['user_id'] as int,
        name: m['name'] as String,
        totalAmount: m['total_amount'] as int,
        createdAt: DateTime.parse(m['created_at'] as String),
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'name': name,
        'total_amount': totalAmount,
        'created_at': createdAt.toIso8601String(),
      };

  Budget copyWith({String? name, int? totalAmount}) => Budget(
        id: id,
        userId: userId,
        name: name ?? this.name,
        totalAmount: totalAmount ?? this.totalAmount,
        createdAt: createdAt,
      );
}
