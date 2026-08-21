import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to Supabase. Demo data is seeded by supabase/schema.sql.
  await SupabaseService.initialize();

  runApp(const RwandaPayApp());
}

class RwandaPayApp extends StatelessWidget {
  const RwandaPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],
      child: MaterialApp(
        title: 'RwandaPay Connect',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: const LoginScreen(),
      ),
    );
  }
}
