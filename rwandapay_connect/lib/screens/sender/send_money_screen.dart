import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/user.dart';
import '../../theme/app_theme.dart';
import 'sender_dashboard.dart';

class SendMoneyScreen extends StatefulWidget {
  /// Receiver chosen ahead of time — set when arriving from Scan to Pay, so
  /// the sender does not have to pick them from the list again.
  final AppUser? presetReceiver;

  /// Amount the receiver's QR code requested, prefilled into the field. The
  /// sender can still edit it before confirming.
  final double? presetAmount;

  const SendMoneyScreen({
    super.key,
    this.presetReceiver,
    this.presetAmount,
  });

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final _amountController = TextEditingController();
  AppUser? _selectedReceiver;
  bool _showSuccess = false;
  double? _sentAmount;
  double? _sentFee;
  double? _sentRwf;
  String? _receiverName;

  @override
  void initState() {
    super.initState();
    _selectedReceiver = widget.presetReceiver;
    if (widget.presetAmount != null) {
      _amountController.text = widget.presetAmount!.toStringAsFixed(2);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final txnProvider = context.read<TransactionProvider>();
      txnProvider.fetchExchangeRate();
      txnProvider.loadReceivers();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) return _buildSuccess(context);

    final auth = context.watch<AuthProvider>();
    final txn = context.watch<TransactionProvider>();
    // A receiver arrived at by QR scan is shown immediately, even if the
    // full receiver list is still loading.
    final receivers = [
      ...txn.receivers,
      if (_selectedReceiver != null &&
          !txn.receivers.any((r) => r.id == _selectedReceiver!.id))
        _selectedReceiver!,
    ];
    final account = auth.currentAccount;
    final curr = NumberFormat.currency(symbol: '\$');
    final rwf = NumberFormat('#,##0', 'en_US');

    final fee = txn.calculateFee(_amount);
    final total = _amount + fee;
    final rwfAmt = txn.calculateRwfAmount(_amount);
    final canSend = _selectedReceiver != null &&
        _amount > 0 &&
        account != null &&
        total <= account.balance;

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
                    child: Text('Send Money',
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Confirms to the sender that this screen was reached
                        // by scanning, and who the code belonged to.
                        if (widget.presetReceiver != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.greenCard,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: AppColors.successDark,
                                      size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Scanned QR code',
                                          style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.darkText)),
                                      Text(
                                          'Paying ${widget.presetReceiver!.fullName}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: AppColors.darkText
                                                  .withValues(alpha: 0.6))),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 400.ms),
                          const SizedBox(height: 16),
                        ],
                        // Rate pill
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.yellowCard,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.currency_exchange_rounded,
                                    color: AppColors.gold, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: txn.loadingRate
                                    ? Text('Fetching rate...',
                                        style: GoogleFonts.poppins(
                                            color: AppColors.mutedGrey))
                                    : Text(
                                        '1 USD = ${NumberFormat('#,##0.00').format(txn.currentRate)} RWF',
                                        style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.darkText,
                                            fontSize: 15)),
                              ),
                              GestureDetector(
                                onTap: () => txn.fetchExchangeRate(),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.refresh_rounded,
                                      size: 16, color: AppColors.darkText),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 20),

                        // Receiver Selection
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Send to',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.mutedGrey)),
                              const SizedBox(height: 14),
                              ...receivers.map((r) {
                                final sel = _selectedReceiver?.id == r.id;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedReceiver = r),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: sel
                                          ? AppColors.blueCard
                                          : AppColors.pageBg,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: sel
                                                ? AppColors.info
                                                : AppColors.cardBorder,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Center(
                                            child: Text(r.fullName[0],
                                                style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    color: sel
                                                        ? AppColors.white
                                                        : AppColors.darkText)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(r.fullName,
                                                  style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14)),
                                              Text('${r.country} • ${r.phone}',
                                                  style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color: AppColors
                                                          .mutedGrey)),
                                            ],
                                          ),
                                        ),
                                        if (sel)
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: const BoxDecoration(
                                              color: AppColors.info,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                                Icons.check_rounded,
                                                color: AppColors.white,
                                                size: 16),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                        const SizedBox(height: 16),

                        // Amount
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Amount (USD)',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.mutedGrey)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                style: GoogleFonts.poppins(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkText),
                                decoration: InputDecoration(
                                  prefixText: '\$ ',
                                  prefixStyle: GoogleFonts.poppins(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkText),
                                  hintText: '0.00',
                                  hintStyle: GoogleFonts.poppins(
                                      color: AppColors.mutedGrey
                                          .withValues(alpha: 0.3)),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              if (account != null)
                                Text('Balance: ${curr.format(account.balance)}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.mutedGrey)),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                        const SizedBox(height: 16),

                        // Preview
                        if (_amount > 0)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              children: [
                                _row('Amount', curr.format(_amount)),
                                _div(),
                                _row('Fee (1.5%)', curr.format(fee)),
                                _div(),
                                _row('Total Deducted', curr.format(total),
                                    bold: true),
                                _div(),
                                _row(
                                  'Receiver Gets',
                                  '${rwf.format(rwfAmt)} RWF',
                                  bold: true,
                                  color: AppColors.success,
                                ),
                                if (account != null && total > account.balance)
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
                                        Text('Insufficient balance',
                                            style: GoogleFonts.poppins(
                                                color: AppColors.error,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms),
                        const SizedBox(height: 24),

                        // Confirm
                        SizedBox(
                          height: 58,
                          child: ElevatedButton(
                            onPressed:
                                canSend && !txn.processing ? () => _send() : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkText,
                              disabledBackgroundColor:
                                  AppColors.darkText.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            child: txn.processing
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5, color: Colors.white))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('Confirm & Send',
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
                        const SizedBox(height: 20),
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

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  color: AppColors.mutedGrey, fontSize: 14)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                  color: color ?? AppColors.darkText,
                  fontSize: bold ? 17 : 14)),
        ],
      ),
    );
  }

  Widget _div() => Divider(height: 20, color: AppColors.cardBorder);

  Future<void> _send() async {
    final auth = context.read<AuthProvider>();
    final txnProvider = context.read<TransactionProvider>();
    final result = await txnProvider.sendMoney(
      senderId: auth.currentUser!.id,
      receiverId: _selectedReceiver!.id,
      amountUsd: _amount,
      momoNumber: _selectedReceiver!.phone,
    );
    if (!mounted) return;

    if (result == null) {
      final message = txnProvider.error ?? 'Transfer failed. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
      return;
    }

    await auth.refreshAccount();
    if (!mounted) return;
    setState(() {
      _showSuccess = true;
      _sentAmount = result.amountUsd;
      _sentFee = result.feeUsd;
      _sentRwf = result.amountRwf;
      _receiverName = _selectedReceiver!.fullName;
    });
  }

  Widget _buildSuccess(BuildContext context) {
    final curr = NumberFormat.currency(symbol: '\$');
    final rwf = NumberFormat('#,##0', 'en_US');

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.greenCard,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.success, size: 50),
                  )
                      .animate()
                      .scale(
                          begin: const Offset(0.5, 0.5),
                          duration: 500.ms,
                          curve: Curves.elasticOut)
                      .fadeIn(),
                  const SizedBox(height: 28),
                  Text('Transfer Successful!',
                          style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkText))
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: 8),
                  Text('Money sent to $_receiverName',
                          style: GoogleFonts.poppins(
                              color: AppColors.mutedGrey, fontSize: 14))
                      .animate()
                      .fadeIn(delay: 300.ms),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        _row('Sent to', _receiverName ?? ''),
                        _div(),
                        _row('Amount', curr.format(_sentAmount ?? 0)),
                        _div(),
                        _row('Fee', curr.format(_sentFee ?? 0)),
                        _div(),
                        _row('Receiver Gets',
                            '${rwf.format(_sentRwf ?? 0)} RWF',
                            bold: true, color: AppColors.success),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const SenderDashboard())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkText,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      child: Text('Back to Dashboard',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
