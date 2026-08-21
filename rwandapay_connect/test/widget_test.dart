import 'package:flutter_test/flutter_test.dart';
import 'package:rwandapay_connect/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const RwandaPayApp());
    expect(find.text('RwandaPay Connect'), findsOneWidget);
  });
}
