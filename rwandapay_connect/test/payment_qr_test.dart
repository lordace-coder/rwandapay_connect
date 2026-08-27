import 'package:flutter_test/flutter_test.dart';
import 'package:rwandapay_connect/models/payment_qr.dart';

void main() {
  group('PaymentQr.encode', () {
    test('includes the amount when one is requested', () {
      final encoded = const PaymentQr(
        accountNumber: 'RWC-RW-0001',
        name: 'Uwase Aline',
        amountUsd: 25,
      ).encode();

      expect(encoded, startsWith('rwandapay://pay?'));
      expect(encoded, contains('acct=RWC-RW-0001'));
      expect(encoded, contains('amount=25.00'));
    });

    test('omits the amount for an open code', () {
      final encoded = const PaymentQr(
        accountNumber: 'RWC-RW-0002',
        name: 'Niyonzima Eric',
      ).encode();

      expect(encoded, isNot(contains('amount=')));
    });

    test('escapes characters that would break the query string', () {
      final encoded = const PaymentQr(
        accountNumber: 'RWC-RW-0001',
        name: 'Uwase Aline & Co',
      ).encode();

      // The ampersand must not survive as a parameter separator.
      expect(PaymentQr.tryParse(encoded)!.name, 'Uwase Aline & Co');
    });
  });

  group('PaymentQr.tryParse', () {
    test('round-trips a code with an amount', () {
      const original = PaymentQr(
        accountNumber: 'RWC-RW-0001',
        name: 'Uwase Aline',
        amountUsd: 49.5,
      );
      final parsed = PaymentQr.tryParse(original.encode())!;

      expect(parsed.accountNumber, 'RWC-RW-0001');
      expect(parsed.name, 'Uwase Aline');
      expect(parsed.amountUsd, 49.5);
    });

    test('round-trips an open code', () {
      final parsed = PaymentQr.tryParse(
          const PaymentQr(accountNumber: 'RWC-RW-0002', name: 'Eric').encode())!;

      expect(parsed.accountNumber, 'RWC-RW-0002');
      expect(parsed.amountUsd, isNull);
    });

    test('tolerates surrounding whitespace from a scan', () {
      final parsed =
          PaymentQr.tryParse('  rwandapay://pay?acct=RWC-RW-0001  ');
      expect(parsed?.accountNumber, 'RWC-RW-0001');
    });

    test('accepts a code with no name', () {
      final parsed = PaymentQr.tryParse('rwandapay://pay?acct=RWC-RW-0001');
      expect(parsed, isNotNull);
      expect(parsed!.name, '');
    });

    test('treats a non-positive amount as an open code', () {
      expect(
        PaymentQr.tryParse('rwandapay://pay?acct=RWC-RW-0001&amount=0')
            ?.amountUsd,
        isNull,
      );
      expect(
        PaymentQr.tryParse('rwandapay://pay?acct=RWC-RW-0001&amount=-10')
            ?.amountUsd,
        isNull,
      );
    });

    test('ignores an unparseable amount rather than failing the scan', () {
      final parsed =
          PaymentQr.tryParse('rwandapay://pay?acct=RWC-RW-0001&amount=abc');
      expect(parsed, isNotNull);
      expect(parsed!.amountUsd, isNull);
    });

    test('rejects codes that are not RwandaPay codes', () {
      for (final bad in <String>[
        '',
        '   ',
        'just some text',
        'https://example.com/pay?acct=RWC-RW-0001', // wrong scheme
        'rwandapay://transfer?acct=RWC-RW-0001', // wrong host
        'rwandapay://pay', // no account number
        'rwandapay://pay?acct=', // empty account number
      ]) {
        expect(PaymentQr.tryParse(bad), isNull, reason: 'should reject "$bad"');
      }
    });
  });
}
