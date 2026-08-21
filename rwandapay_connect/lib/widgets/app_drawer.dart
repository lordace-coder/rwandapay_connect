import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/sender/sender_dashboard.dart';
import '../screens/receiver/receiver_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) return const SizedBox.shrink();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppColors.navy),
            accountName: Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(user.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.gold,
              child: Text(
                user.fullName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Widget dashboard;
              switch (user.role) {
                case 'sender':
                  dashboard = const SenderDashboard();
                  break;
                case 'receiver':
                  dashboard = const ReceiverDashboard();
                  break;
                case 'admin':
                  dashboard = const AdminDashboard();
                  break;
                default:
                  return;
              }
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => dashboard),
              );
            },
          ),
          if (user.role != 'admin')
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile / KYC'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Sign Out',
                style: TextStyle(color: AppColors.error)),
            onTap: () {
              auth.logout();
              context.read<TransactionProvider>().clear();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
