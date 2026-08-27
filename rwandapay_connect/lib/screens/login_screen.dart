import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'sender/sender_dashboard.dart';
import 'receiver/receiver_dashboard.dart';
import 'admin/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final success =
        await auth.login(_emailController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success && mounted) {
      final user = auth.currentUser!;
      Widget dashboard;
      switch (user.role) {
        case 'sender': dashboard = const SenderDashboard(); break;
        case 'receiver': dashboard = const ReceiverDashboard(); break;
        case 'admin': dashboard = const AdminDashboard(); break;
        default: dashboard = const SenderDashboard();
      }
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (c, a, s) => dashboard,
          transitionsBuilder: (c, a, s, child) =>
              FadeTransition(opacity: a, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2A4A), Color(0xFF0F1B33)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: w > 500 ? 420 : double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Center(
                        child: Text('RP',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            )),
                      ),
                    ).animate().scale(
                        begin: const Offset(0.6, 0.6),
                        duration: 500.ms,
                        curve: Curves.elasticOut),
                    const SizedBox(height: 24),
                    Text(
                      'RwandaPay',
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    Text(
                      'Connect',
                      style: GoogleFonts.poppins(
                        fontSize: 34,
                        fontWeight: FontWeight.w300,
                        color: AppColors.gold,
                        letterSpacing: -1,
                      ),
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Fast cross-border remittances to Rwanda',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white38,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 40),

                    // Feature pills — wrapped so they reflow instead of
                    // overflowing on narrow screens.
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _featurePill('1.5% Fee', AppColors.orangeCard),
                        _featurePill('Live Rate', AppColors.blueCard),
                        _featurePill('Instant MoMo', AppColors.greenCard),
                        _featurePill('Scan to Pay', AppColors.purpleCard),
                      ],
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                    const SizedBox(height: 40),

                    // Login card
                    Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Sign In',
                              style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText)),
                          const SizedBox(height: 4),
                          Text('Enter your demo credentials',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.mutedGrey)),
                          const SizedBox(height: 28),
                          // Email
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.pageBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.poppins(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Email address',
                                hintStyle: GoogleFonts.poppins(
                                    color: AppColors.mutedGrey, fontSize: 14),
                                prefixIcon: const Icon(Icons.mail_rounded,
                                    size: 20, color: AppColors.mutedGrey),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              onSubmitted: (_) => _login(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Password
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.pageBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.poppins(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: GoogleFonts.poppins(
                                    color: AppColors.mutedGrey, fontSize: 14),
                                prefixIcon: const Icon(Icons.lock_rounded,
                                    size: 20, color: AppColors.mutedGrey),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20,
                                    color: AppColors.mutedGrey,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                              ),
                              onSubmitted: (_) => _login(),
                            ),
                          ),
                          // Error
                          if (auth.loginError != null)
                            Container(
                              margin: const EdgeInsets.only(top: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.pinkCard,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_rounded,
                                      color: AppColors.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(auth.loginError!,
                                        style: GoogleFonts.poppins(
                                            color: AppColors.error,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),
                          // Button
                          SizedBox(
                            height: 58,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkText,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22, height: 22,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5, color: Colors.white))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Let\'s Start',
                                            style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 10),
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 16,
                                              color: Colors.white),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.15),
                    const SizedBox(height: 24),
                    Text(
                      'University of Kigali  •  BBIT Dissertation',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.white30),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featurePill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.darkText)),
    );
  }
}
