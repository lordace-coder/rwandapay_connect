import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';
import '../screens/sender/sender_dashboard.dart';
import '../screens/sender/send_money_screen.dart';
import '../screens/receiver/receiver_dashboard.dart';
import '../screens/receiver/my_qr_screen.dart';
import '../screens/sender/scan_to_pay_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/profile/profile_screen.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final String role;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: AppColors.darkText,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkText.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: _buildItems(context),
        ),
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    switch (role) {
      case 'sender':
        return [
          _navItem(context, Icons.home_rounded, 'Home', 0, () {
            if (currentIndex != 0) _nav(context, const SenderDashboard());
          }),
          _navItem(context, Icons.send_rounded, 'Send', 1, () {
            _nav(context, const SendMoneyScreen());
          }),
          _navItem(context, Icons.qr_code_scanner_rounded, 'Scan', 2, () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScanToPayScreen()));
          }),
          _navItem(context, Icons.person_rounded, 'Profile', 3, () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
          _navItem(context, Icons.logout_rounded, 'Exit', -1, () {
            _logout(context);
          }),
        ];
      case 'receiver':
        return [
          _navItem(context, Icons.home_rounded, 'Home', 0, () {
            if (currentIndex != 0) _nav(context, const ReceiverDashboard());
          }),
          _navItem(context, Icons.qr_code_rounded, 'My Code', 1, () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MyQrScreen()));
          }),
          _navItem(context, Icons.person_rounded, 'Profile', 2, () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
          _navItem(context, Icons.logout_rounded, 'Exit', -1, () {
            _logout(context);
          }),
        ];
      case 'admin':
        return [
          _navItem(context, Icons.dashboard_rounded, 'Dashboard', 0, () {
            if (currentIndex != 0) _nav(context, const AdminDashboard());
          }),
          _navItem(context, Icons.logout_rounded, 'Exit', -1, () {
            _logout(context);
          }),
        ];
      default:
        return [];
    }
  }

  Widget _navItem(BuildContext context, IconData icon, String label, int index,
      VoidCallback onTap) {
    final isSelected = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppColors.gold.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 22, color: isSelected ? AppColors.gold : Colors.white38),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.gold : Colors.white38)),
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context, Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (c, a, s) => page,
        transitionsBuilder: (c, a, s, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  void _logout(BuildContext context) {
    context.read<AuthProvider>().logout();
    context.read<TransactionProvider>().clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}
