import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/bottom_nav.dart';
import 'my_qr_screen.dart';

class ReceiverDashboard extends StatefulWidget {
  const ReceiverDashboard({super.key});

  @override
  State<ReceiverDashboard> createState() => _ReceiverDashboardState();
}

class _ReceiverDashboardState extends State<ReceiverDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final txnProvider = context.read<TransactionProvider>();
    final user = auth.currentUser;
    if (user == null) return;
    await Future.wait([
      auth.refreshAccount(),
      txnProvider.loadTransactionsForUser(user.id),
      txnProvider.loadNonAdminUsers(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final txnProvider = context.watch<TransactionProvider>();
    final user = auth.currentUser!;
    final account = auth.currentAccount;
    final transactions = txnProvider.transactions;
    final rwfFormat = NumberFormat('#,##0', 'en_US');
    final currencyFormat = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      bottomNavigationBar: AppBottomNav(currentIndex: 0, role: user.role),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.greenCard,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Text(user.fullName[0],
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user.fullName.split(' ').first}',
                              style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText),
                            ),
                            Text('${user.accountNumber} • Rwanda',
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: AppColors.mutedGrey)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _refresh,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.refresh_rounded,
                              color: AppColors.darkText, size: 20),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 28),

                  // Balance Card — green gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00856F), Color(0xFF00C9A7)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Available Balance',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.white70)),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          account != null
                              ? '${rwfFormat.format(account.balance)} RWF'
                              : '0 RWF',
                          style: GoogleFonts.poppins(
                            fontSize: 38,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Rwandan Franc',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.white38)),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone_android_rounded,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Text('MTN MoMo: ${user.phone}',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const MyQrScreen())),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.successDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_rounded, size: 20),
                                const SizedBox(width: 10),
                                Text('Show My Payment Code',
                                    style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.08),
                  const SizedBox(height: 28),

                  // Header with refresh
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Incoming Transfers',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText)),
                      GestureDetector(
                        onTap: _refresh,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.greenCard,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.refresh_rounded, size: 14),
                              const SizedBox(width: 6),
                              Text('Refresh',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (transactions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.greenCard,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.inbox_rounded,
                                size: 26, color: AppColors.success),
                          ),
                          const SizedBox(height: 14),
                          Text('No transfers yet',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText)),
                          const SizedBox(height: 4),
                          Text('Transfers appear when someone sends you money',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.mutedGrey),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  else
                    ...transactions.asMap().entries.map((entry) {
                      final txn = entry.value;
                      final sender = txnProvider.getUserById(txn.senderId);
                      final canSendToMomo = txn.status == 'received';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: AppColors.greenCard,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                      Icons.arrow_downward_rounded,
                                      color: AppColors.success,
                                      size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'From ${sender?.fullName ?? 'Unknown'}',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: AppColors.darkText),
                                      ),
                                      Text(
                                        DateFormat('MMM d, y • h:mm a')
                                            .format(txn.createdAt),
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: AppColors.mutedGrey),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '+${rwfFormat.format(txn.amountRwf)} RWF',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: AppColors.success),
                                    ),
                                    const SizedBox(height: 4),
                                    StatusBadge(status: txn.status),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Details
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.pageBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _mini('Original',
                                      currencyFormat.format(txn.amountUsd)),
                                  Container(
                                      width: 1,
                                      height: 24,
                                      color: AppColors.cardBorder),
                                  _mini('Rate',
                                      NumberFormat('#,##0').format(txn.exchangeRateUsed)),
                                  Container(
                                      width: 1,
                                      height: 24,
                                      color: AppColors.cardBorder),
                                  _mini('Fee',
                                      currencyFormat.format(txn.feeUsd)),
                                ],
                              ),
                            ),
                            // MoMo Button
                            if (canSendToMomo) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: txnProvider.processing
                                      ? null
                                      : () => _sendToMomo(txn),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: AppColors.darkText,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.phone_android_rounded,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Text('Send to Mobile Money',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            // MoMo success
                            if (txn.status == 'sent_to_momo') ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
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
                                      child: Text(
                                        'RWF ${rwfFormat.format(txn.amountRwf)} sent to MoMo ending in ${user.phone.length >= 4 ? user.phone.substring(user.phone.length - 4) : user.phone}',
                                        style: GoogleFonts.poppins(
                                            color: AppColors.successDark,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(
                          duration: 300.ms,
                          delay: (200 + entry.key * 80).ms);
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.mutedGrey)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Future<void> _sendToMomo(dynamic txn) async {
    final auth = context.read<AuthProvider>();
    final txnProvider = context.read<TransactionProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.yellowCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.phone_android_rounded,
                    color: AppColors.gold, size: 28),
              ),
              const SizedBox(height: 20),
              Text('Processing...',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.darkText)),
              const SizedBox(height: 8),
              Text('Sending to ${auth.currentUser?.phone ?? 'MoMo'}',
                  style: GoogleFonts.poppins(
                      color: AppColors.mutedGrey, fontSize: 13)),
              const SizedBox(height: 24),
              const LinearProgressIndicator(
                color: AppColors.gold,
                backgroundColor: AppColors.pageBg,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ],
          ),
        ),
      ),
    );

    final ok = await txnProvider.sendToMomo(txn);

    if (!mounted) return;
    Navigator.of(context).pop();

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(txnProvider.error ?? 'MoMo payout failed.',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    await _refresh();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'RWF ${NumberFormat('#,##0').format(txn.amountRwf)} sent to MoMo!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
