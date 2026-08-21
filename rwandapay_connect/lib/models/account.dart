class Account {
  final String id;
  final String userId;
  final String currency; // "USD" | "RWF"
  double balance;
  DateTime updatedAt;

  Account({
    required this.id,
    required this.userId,
    required this.currency,
    required this.balance,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
}
