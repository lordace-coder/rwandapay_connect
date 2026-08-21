class AppTransaction {
  final String id;
  final String senderId;
  final String receiverId;
  final double amountUsd;
  final double feeUsd;
  final double exchangeRateUsed;
  final double amountRwf;
  String status; // "sent" | "received" | "sent_to_momo"
  final String? momoNumberUsed;
  final DateTime createdAt;
  DateTime updatedAt;

  AppTransaction({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amountUsd,
    required this.feeUsd,
    required this.exchangeRateUsed,
    required this.amountRwf,
    this.status = 'sent',
    this.momoNumberUsed,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}
