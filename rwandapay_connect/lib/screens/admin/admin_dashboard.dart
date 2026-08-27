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

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final txnProvider = context.read<TransactionProvider>();
    await Future.wait([
      txnProvider.loadAllTransactions(),
      txnProvider.loadNonAdminUsers(),
      txnProvider.loadAccounts(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    final txnProvider = context.watch<TransactionProvider>();
    final transactions = txnProvider.transactions;
    final allUsers = txnProvider.allNonAdminUsers;
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final rwfFormat = NumberFormat('#,##0', 'en_US');
    final user = context.read<AuthProvider>().currentUser!;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      bottomNavigationBar: AppBottomNav(currentIndex: 0, role: user.role),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.purpleCard,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.admin_panel_settings_rounded,
                            color: AppColors.purple, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Admin Panel',
                                style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText)),
                            Text('Platform Overview',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.mutedGrey)),
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
                  const SizedBox(height: 24),

                  // 4 colored stat cards in 2x2 grid
                  Row(
                    children: [
                      Expanded(
                          child: _coloredStat(
                        txnProvider.totalTransactions.toString(),
                        'Transactions',
                        Icons.receipt_long_rounded,
                        AppColors.orangeCard,
                        AppColors.orange,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _coloredStat(
                        currencyFormat.format(txnProvider.totalUsdSent),
                        'USD Sent',
                        Icons.trending_up_rounded,
                        AppColors.blueCard,
                        AppColors.info,
                      )),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _coloredStat(
                        rwfFormat.format(txnProvider.totalRwfPaidOut),
                        'RWF Paid Out',
                        Icons.money_rounded,
                        AppColors.greenCard,
                        AppColors.success,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _coloredStat(
                        txnProvider.totalUsers.toString(),
                        'Users',
                        Icons.people_rounded,
                        AppColors.purpleCard,
                        AppColors.purple,
                      )),
                    ],
                  ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
                  const SizedBox(height: 28),

                  // Tab Selector — pill style
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _tab('Transactions', 0),
                        const SizedBox(width: 4),
                        _tab('Users', 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Content
                  if (_tabIndex == 0)
                    _buildTransactions(
                        transactions, txnProvider, currencyFormat, rwfFormat)
                  else
                    _buildUsers(
                        allUsers, txnProvider, currencyFormat, rwfFormat),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(String label, int index) {
    final isSelected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.darkText : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.mutedGrey,
                )),
          ),
        ),
      ),
    );
  }

  Widget _coloredStat(String value, String label, IconData icon,
      Color cardColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText),
              overflow: TextOverflow.ellipsis),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.darkText.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildTransactions(List txns, TransactionProvider txnProvider,
      NumberFormat currency, NumberFormat rwf) {
    if (txns.isEmpty) {
      return Container(
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
                color: AppColors.orangeCard,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  size: 26, color: AppColors.orange),
            ),
            const SizedBox(height: 14),
            Text('No transactions yet',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: AppColors.darkText)),
          ],
        ),
      );
    }

    return Column(
      children: txns.asMap().entries.map((entry) {
        final txn = entry.value;
        final sender = txnProvider.getUserById(txn.senderId);
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.blueCard,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.swap_horiz_rounded,
                        color: AppColors.info, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${sender?.fullName ?? '?'} → ${receiver?.fullName ?? '?'}',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.darkText),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('MMM d, y • h:mm a')
                              .format(txn.createdAt),
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: AppColors.mutedGrey),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: txn.status),
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _col('Amount', currency.format(txn.amountUsd)),
                    Container(
                        width: 1, height: 24, color: AppColors.cardBorder),
                    _col('Fee', currency.format(txn.feeUsd)),
                    Container(
                        width: 1, height: 24, color: AppColors.cardBorder),
                    _col('Rate',
                        NumberFormat('#,##0').format(txn.exchangeRateUsed)),
                    Container(
                        width: 1, height: 24, color: AppColors.cardBorder),
                    _col('RWF', rwf.format(txn.amountRwf)),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (entry.key * 60).ms);
      }).toList(),
    );
  }

  Widget _buildUsers(List users, TransactionProvider txnProvider,
      NumberFormat currency, NumberFormat rwf) {
    return Column(
      children: users.asMap().entries.map((entry) {
        final u = entry.value;
        final account = txnProvider.accountForUser(u.id);
        String bal = 'N/A';
        if (account != null) {
          bal = account.currency == 'USD'
              ? currency.format(account.balance)
              : '${rwf.format(account.balance)} RWF';
        }
        final isSender = u.role == 'sender';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSender ? AppColors.orangeCard : AppColors.greenCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(u.fullName[0],
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.darkText)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.fullName,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppColors.darkText)),
                    Text(u.email,
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.mutedGrey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(bal,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.darkText)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSender
                              ? AppColors.orangeCard
                              : AppColors.greenCard,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          u.role[0].toUpperCase() + u.role.substring(1),
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const StatusBadge(status: 'verified'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms, delay: (entry.key * 60).ms);
      }).toList(),
    );
  }

  Widget _col(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style:
                  GoogleFonts.poppins(fontSize: 10, color: AppColors.mutedGrey)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
