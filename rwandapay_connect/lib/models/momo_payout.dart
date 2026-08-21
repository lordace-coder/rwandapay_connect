class MomoPayout {
  final String id;
  final String transactionId;
  final String momoNumber;
  final double amountRwf;
  final String simulatedStatus;
  final DateTime processedAt;

  MomoPayout({
    required this.id,
    required this.transactionId,
    required this.momoNumber,
    required this.amountRwf,
    this.simulatedStatus = 'completed',
    DateTime? processedAt,
  }) : processedAt = processedAt ?? DateTime.now();
}
