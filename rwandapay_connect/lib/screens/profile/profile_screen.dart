import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final isSender = user.role == 'sender';

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.darkText, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Text('Profile & KYC',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText)),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        // Profile Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isSender
                                  ? [const Color(0xFF1B2A4A), const Color(0xFF2D4470)]
                                  : [const Color(0xFF00856F), const Color(0xFF00C9A7)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.gold,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Center(
                                  child: Text(user.fullName[0],
                                      style: GoogleFonts.poppins(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.darkText)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(user.fullName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              Text(
                                '${user.role[0].toUpperCase()}${user.role.substring(1)} • ${user.country}',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: Colors.white54),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.greenCard,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_rounded,
                                        color: AppColors.success, size: 16),
                                    const SizedBox(width: 6),
                                    Text('Verified',
                                        style: GoogleFonts.poppins(
                                            color: AppColors.successDark,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05),
                        const SizedBox(height: 18),

                        // Personal Info
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Personal Information',
                                  style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkText)),
                              const SizedBox(height: 18),
                              _info(Icons.person_rounded, 'Name',
                                  user.fullName),
                              _info(Icons.mail_rounded, 'Email', user.email),
                              _info(Icons.phone_rounded, 'Phone', user.phone),
                              _info(Icons.flag_rounded, 'Country',
                                  user.country),
                              if (user.address != null &&
                                  user.address!.isNotEmpty)
                                _info(Icons.location_on_rounded, 'Address',
                                    user.address!),
                              _info(Icons.account_balance_rounded, 'Account',
                                  user.accountNumber),
                              if (user.momoProvider != null)
                                _info(Icons.phone_android_rounded, 'MoMo',
                                    user.momoProvider!),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                        const SizedBox(height: 14),

                        // ID Verification
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('Identity Verification',
                                      style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.darkText)),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.greenCard,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('Verified',
                                        style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.success)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              _info(Icons.badge_rounded, 'ID Type',
                                  user.idType),
                              _info(Icons.numbers_rounded, 'ID Number',
                                  user.idNumber),
                              const SizedBox(height: 10),
                              Divider(color: AppColors.cardBorder),
                              const SizedBox(height: 14),
                              Text('ID Document',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.mutedGrey)),
                              const SizedBox(height: 14),

                              // Mock ID card
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: user.country == 'Rwanda'
                                      ? AppColors.blueCard
                                      : AppColors.orangeCard,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    children: [
                                      // ID header
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: user.country == 'Rwanda'
                                              ? const Color(0xFF00A1DE)
                                              : AppColors.navy,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          user.country == 'Rwanda'
                                              ? 'REPUBLIC OF RWANDA  •  NATIONAL ID'
                                              : 'UNITED STATES  •  DRIVER\'S LICENSE',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 65,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              color: AppColors.pageBg,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.person_rounded,
                                                    size: 30,
                                                    color: AppColors.mutedGrey
                                                        .withValues(
                                                            alpha: 0.4)),
                                                Text('PHOTO',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 7,
                                                        color: AppColors
                                                            .mutedGrey,
                                                        fontWeight:
                                                            FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                _idLine(
                                                    'NAME', user.fullName),
                                                _idLine(
                                                    'ID NO.', user.idNumber),
                                                _idLine(
                                                    'COUNTRY', user.country),
                                                if (user.phone.isNotEmpty)
                                                  _idLine(
                                                      'PHONE', user.phone),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Verification stamp
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.greenCard,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_rounded,
                                          color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('Identity Verified',
                                              style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      AppColors.successDark,
                                                  fontSize: 13)),
                                          Text(
                                            DateFormat('MMMM d, y')
                                                .format(user.createdAt),
                                            style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color:
                                                    AppColors.successDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.pageBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.mutedGrey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.mutedGrey)),
                Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _idLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 8,
                  color: AppColors.mutedGrey,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
