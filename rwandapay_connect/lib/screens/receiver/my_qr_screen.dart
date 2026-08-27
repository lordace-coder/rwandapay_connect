import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/payment_qr.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// The receiver's own payment code. Shown to a sender, who scans it from the
/// Scan to Pay screen.
///
/// The code can be left open — the sender chooses the amount — or set to
/// request a specific sum, which prefills the sender's amount field.
class MyQrScreen extends StatefulWidget {
  const MyQrScreen({super.key});

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  final _amountController = TextEditingController();
  bool _requestSpecificAmount = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double? get _requestedAmount {
    if (!_requestSpecificAmount) return null;
    final parsed = double.tryParse(_amountController.text.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser!;
    final payload = PaymentQr(
      accountNumber: user.accountNumber,
      name: user.fullName,
      amountUsd: _requestedAmount,
    ).encode();

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
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
                    child: Text('My Payment Code',
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
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // The card a sender points their camera at.
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF1B2A4A), Color(0xFF2D4470)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Column(
                            children: [
                              Text(user.fullName,
                                  style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                              const SizedBox(height: 2),
                              Text(user.accountNumber,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13, color: Colors.white54)),
                              const SizedBox(height: 22),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: QrImageView(
                                  data: payload,
                                  version: QrVersions.auto,
                                  size: 220,
                                  gapless: true,
                                  backgroundColor: Colors.white,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: AppColors.navy,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: AppColors.darkText,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (_requestedAmount != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Requesting \$${_requestedAmount!.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkText),
                                  ),
                                )
                              else
                                Text('Sender chooses the amount',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13, color: Colors.white54)),
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 500.ms)
                            .slideY(begin: 0.06),
                        const SizedBox(height: 20),

                        // Optional amount request
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Request a specific amount',
                                            style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.darkText)),
                                        Text(
                                            'Prefills the amount for whoever scans',
                                            style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: AppColors.mutedGrey)),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _requestSpecificAmount,
                                    activeThumbColor: AppColors.gold,
                                    onChanged: (v) => setState(
                                        () => _requestSpecificAmount = v),
                                  ),
                                ],
                              ),
                              if (_requestSpecificAmount) ...[
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _amountController,
                                  autofocus: true,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  style: GoogleFonts.poppins(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkText),
                                  decoration: InputDecoration(
                                    prefixText: '\$ ',
                                    prefixStyle: GoogleFonts.poppins(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkText),
                                    hintText: '0.00',
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                        const SizedBox(height: 16),

                        // The raw payload, for the manual-entry fallback.
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment code',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.mutedGrey)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      payload,
                                      style: GoogleFonts.robotoMono(
                                          fontSize: 11,
                                          color: AppColors.darkText),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () async {
                                      await Clipboard.setData(
                                          ClipboardData(text: payload));
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                        content: const Text(
                                            'Payment code copied'),
                                        backgroundColor: AppColors.successDark,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14)),
                                      ));
                                    },
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: AppColors.pageBg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.copy_rounded,
                                          size: 17, color: AppColors.darkText),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
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
}
