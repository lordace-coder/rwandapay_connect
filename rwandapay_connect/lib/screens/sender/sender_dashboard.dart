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
import 'send_money_screen.dart';
import 'scan_to_pay_screen.dart';

class SenderDashboard extends StatefulWidget {
  const SenderDashboard({super.key});

  @override
  State<SenderDashboard> createState() => _SenderDashboardState();
}

class _SenderDashboardState extends State<SenderDashboard> {
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
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final rwfFormat = NumberFormat('#,##0', 'en_US');

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
                  // Greeting row
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.orangeCard,
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
                            Text(user.accountNumber,
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

                  // Balance Card — BIG gradient
                  Container(
                    width: double.infinity,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Available Balance',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.white60)),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          account != null
                              ? currencyFormat.format(account.balance)
                              : '\$0.00',
                          style: GoogleFonts.poppins(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('United States Dollar',
                            style: GoogleFonts.poppins(
                                fontSize: 13, color: Colors.white38)),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const SendMoneyScreen()));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.gold,
                                    foregroundColor: AppColors.darkText,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send_rounded, size: 20),
                                      const SizedBox(width: 10),
                                      Text('Send Money',
                                          style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const ScanToPayScreen()));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.15),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                          Icons.qr_code_scanner_rounded,
                                          size: 20),
                                      const SizedBox(width: 8),
                                      Text('Scan',
                                          style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.08),
                  const SizedBox(height: 20),

                  // Two colored stat cards side by side (like the reference)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.orangeCard,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.receipt_long_rounded,
                                    color: AppColors.orange, size: 18),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                transactions.length.toString(),
                                style: GoogleFonts.poppins(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText),
                              ),
                              Text('Transactions',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.darkText
                                          .withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.blueCard,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.trending_up_rounded,
                                    color: AppColors.info, size: 18),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                currencyFormat.format(
                                  transactions.fold(
                                      0.0, (s, t) => s + t.amountUsd),
                                ),
                                style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text('Total Sent',
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppColors.darkText
                                          .withValues(alpha: 0.6))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                  const SizedBox(height: 28),

                  // Recent Transfers
                  Text('Recent Transfers',
                      style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText)),
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
                              color: AppColors.pageBg,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(Icons.send_rounded,
                                size: 26, color: AppColors.mutedGrey),
                          ),
                          const SizedBox(height: 14),
                          Text('No transfers yet',
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkText)),
                          const SizedBox(height: 4),
                          Text('Send money to get started',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: AppColors.mutedGrey)),
                        ],
                      ),
                    )
                  else
                    ...transactions.asMap().entries.map((entry) {
                      final txn = entry.value;
                      final receiver = txnProvider.getUserById(txn.receiverId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                                    color: AppColors.blueCard,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(Icons.arrow_upward_rounded,
                                      color: AppColors.info, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(receiver?.fullName ?? 'Unknown',
                                          style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: AppColors.darkText)),
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
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '-${currencyFormat.format(txn.amountUsd + txn.feeUsd)}',
                                      style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: AppColors.darkText),
                                    ),
                                    const SizedBox(height: 4),
                                    StatusBadge(status: txn.status),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
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
                                  _miniStat('Fee',
                                      currencyFormat.format(txn.feeUsd)),
                                  Container(
                                      width: 1,
                                      height: 24,
                                      color: AppColors.cardBorder),
                                  _miniStat('Rate',
                                      NumberFormat('#,##0').format(txn.exchangeRateUsed)),
                                  Container(
                                      width: 1,
                                      height: 24,
                                      color: AppColors.cardBorder),
                                  _miniStat('Received',
                                      '${rwfFormat.format(txn.amountRwf)} RWF'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(
                          duration: 300.ms, delay: (250 + entry.key * 80).ms);
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
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
}
