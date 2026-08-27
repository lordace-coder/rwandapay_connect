import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rwandapay_connect/providers/auth_provider.dart';
import 'package:rwandapay_connect/providers/transaction_provider.dart';
import 'package:rwandapay_connect/screens/login_screen.dart';
import 'package:rwandapay_connect/theme/app_theme.dart';

/// Builds the login screen with the providers it reads from, without booting
/// the real app — `RwandaPayApp` is only ever run after
/// `SupabaseService.initialize()`, which needs a network round-trip that does
/// not belong in a widget test.
Widget _loginUnderTest() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => TransactionProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.theme,
      home: const LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('Login screen shows the app name and sign-in form',
      (WidgetTester tester) async {
    await tester.pumpWidget(_loginUnderTest());
    // The screen staggers its entrance animations; settle them so no timer is
    // left pending when the tree is torn down.
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // The wordmark is split across two Text widgets so the two halves can be
    // styled differently, so each is matched on its own.
    expect(find.text('RwandaPay'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
