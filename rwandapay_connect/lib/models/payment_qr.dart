/// The payload encoded in a RwandaPay QR code.
///
/// Format: `rwandapay://pay?acct=RWC-RW-0001&name=Uwase%20Aline&amount=25.00`
///
/// The account number is the only field the sender's app trusts — the name is
/// carried along so the scan sheet can show who is being paid before the
/// receiver record has been looked up, and the amount is optional so a
/// receiver can generate either a plain "pay me" code or a request for a
/// specific sum.
class PaymentQr {
  static const String scheme = 'rwandapay';
  static const String host = 'pay';

  final String accountNumber;
  final String name;

  /// The amount in USD the receiver is requesting, or null for an open code
  /// where the sender types the amount themselves.
  final double? amountUsd;

  const PaymentQr({
    required this.accountNumber,
    required this.name,
    this.amountUsd,
  });

  /// Builds the string that gets drawn into the QR image.
  String encode() {
    final params = <String, String>{
      'acct': accountNumber,
      'name': name,
      if (amountUsd != null) 'amount': amountUsd!.toStringAsFixed(2),
    };
    final query = params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '$scheme://$host?$query';
  }

  /// Parses a scanned string, returning null if it isn't a RwandaPay code.
  ///
  /// Anything malformed — a URL from another app, a plain block of text, a
  /// code missing its account number — comes back as null so the scanner can
  /// show "not a RwandaPay code" rather than throwing mid-scan.
  static PaymentQr? tryParse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final uri = Uri.tryParse(text);
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != scheme) return null;
    if (uri.host.toLowerCase() != host) return null;

    final acct = uri.queryParameters['acct']?.trim();
    if (acct == null || acct.isEmpty) return null;

    final rawAmount = uri.queryParameters['amount'];
    double? amount;
    if (rawAmount != null && rawAmount.trim().isNotEmpty) {
      final parsed = double.tryParse(rawAmount.trim());
      // A negative or zero request is meaningless; treat it as an open code.
      if (parsed != null && parsed > 0) amount = parsed;
    }

    return PaymentQr(
      accountNumber: acct,
      name: uri.queryParameters['name']?.trim() ?? '',
      amountUsd: amount,
    );
  }
}
