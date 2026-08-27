import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../models/payment_qr.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_theme.dart';
import 'send_money_screen.dart';

/// Points the camera at a RwandaPay QR code and, once one resolves to a
/// receiver, hands off to [SendMoneyScreen] with that receiver (and any
/// requested amount) already filled in.
class ScanToPayScreen extends StatefulWidget {
  const ScanToPayScreen({super.key});

  @override
  State<ScanToPayScreen> createState() => _ScanToPayScreenState();
}

class _ScanToPayScreenState extends State<ScanToPayScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Guards against the detection stream firing again while we are already
  /// looking a code up or navigating away.
  bool _handling = false;
  String? _message;
  bool _cameraFailed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;

    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.trim().isNotEmpty, orElse: () => null);
    if (raw == null) return;

    await _handlePayload(raw);
  }

  /// Shared by the camera and the manual-entry sheet, so a typed code behaves
  /// exactly like a scanned one.
  Future<void> _handlePayload(String raw) async {
    if (_handling) return;
    setState(() {
      _handling = true;
      _message = null;
    });

    final code = PaymentQr.tryParse(raw);
    if (code == null) {
      _rejectWith('That is not a RwandaPay payment code.');
      return;
    }

    final auth = context.read<AuthProvider>();
    final txn = context.read<TransactionProvider>();
    final receiver = await txn.resolveScannedCode(
      code,
      scanningUserId: auth.currentUser!.id,
    );
    if (!mounted) return;

    if (receiver == null) {
      _rejectWith(txn.error ?? 'That code could not be used.');
      return;
    }

    await _controller.stop();
    if (!mounted) return;
    await _showConfirmSheet(receiver, code.amountUsd);
  }

  /// Shows why a code was refused and re-arms the scanner after a beat, so
  /// the camera keeps running instead of dead-ending on the error.
  void _rejectWith(String message) {
    if (!mounted) return;
    setState(() => _message = message);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _handling = false);
    });
  }

  Future<void> _showConfirmSheet(AppUser receiver, double? requestedAmount) async {
    final proceed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MatchedSheet(
        receiver: receiver,
        requestedAmount: requestedAmount,
      ),
    );
    if (!mounted) return;

    if (proceed == true) {
      await Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => SendMoneyScreen(
          presetReceiver: receiver,
          presetAmount: requestedAmount,
        ),
      ));
      return;
    }

    // Dismissed — start scanning again.
    setState(() => _handling = false);
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkText,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (!_cameraFailed)
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                // Rebuild into the fallback on the next frame; setState is
                // not allowed during a build.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_cameraFailed) {
                    setState(() => _cameraFailed = true);
                  }
                });
                return const ColoredBox(color: AppColors.darkText);
              },
            )
          else
            const ColoredBox(color: AppColors.darkText),

          // Dim everything outside the cut-out.
          if (!_cameraFailed) const _ScannerScrim(),
          if (!_cameraFailed) const _ScanFrame(),
          if (_cameraFailed) _buildCameraError(),

          _buildTopBar(),
          _buildBottomBar(),
          if (_handling && _message == null) _buildResolving(),
          if (_message != null) _buildMessage(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 20, 0),
        child: Row(
          children: [
            _circleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                'Scan to Pay',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (!_cameraFailed)
              _circleButton(
                icon: Icons.flip_camera_ios_rounded,
                onTap: () => _controller.switchCamera(),
              )
            else
              const SizedBox(width: 44),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_cameraFailed)
                Text(
                  'Point your camera at a RwandaPay QR code',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _handling ? null : _openManualEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.06),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.keyboard_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text('Enter code manually',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(Icons.videocam_off_rounded,
                  color: Colors.white54, size: 38),
            ),
            const SizedBox(height: 24),
            Text(
              'Camera unavailable',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'RwandaPay could not open the camera. Allow camera access in '
              'your browser, or enter the payment code by hand below.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.white54, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolving() {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                  strokeWidth: 3, color: AppColors.gold),
            ),
            const SizedBox(height: 18),
            Text('Looking up account…',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                _message!,
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Future<void> _openManualEntry() async {
    final entered = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ManualEntrySheet(),
    );
    if (!mounted || entered == null) return;
    await _handlePayload(entered);
  }
}

/// Dims the camera feed everywhere except the square cut-out.
class _ScannerScrim extends StatelessWidget {
  const _ScannerScrim();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = _frameSide(constraints);
        return ColorFiltered(
          colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.6), BlendMode.srcOut),
          child: Stack(
            children: [
              // srcOut punches the child below out of this layer.
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: side,
                  height: side,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The four corner brackets plus the sweeping laser line.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = _frameSide(constraints);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              children: [
                for (final corner in const [
                  Alignment.topLeft,
                  Alignment.topRight,
                  Alignment.bottomLeft,
                  Alignment.bottomRight,
                ])
                  Align(alignment: corner, child: _Corner(alignment: corner)),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        AppColors.gold.withValues(alpha: 0),
                        AppColors.gold,
                        AppColors.gold.withValues(alpha: 0),
                      ]),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: 10, end: side - 13, duration: 2200.ms,
                          curve: Curves.easeInOut),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One L-shaped bracket, rotated to whichever corner it sits in.
class _Corner extends StatelessWidget {
  final Alignment alignment;
  const _Corner({required this.alignment});

  @override
  Widget build(BuildContext context) {
    const thickness = 4.0;
    const length = 34.0;
    const color = AppColors.gold;

    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return SizedBox(
      width: length,
      height: length,
      child: Stack(
        children: [
          Align(
            alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
            child: Container(
              height: thickness,
              width: length,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(thickness),
              ),
            ),
          ),
          Align(
            alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: thickness,
              height: length,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(thickness),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps the scrim cut-out and the bracket frame exactly the same size.
double _frameSide(BoxConstraints constraints) {
  final shortest = constraints.biggest.shortestSide;
  return (shortest * 0.68).clamp(200.0, 300.0);
}

/// Shown once a scanned code resolves to a real receiver.
class _MatchedSheet extends StatelessWidget {
  final AppUser receiver;
  final double? requestedAmount;

  const _MatchedSheet({required this.receiver, this.requestedAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 26),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.greenCard,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  receiver.fullName.isNotEmpty ? receiver.fullName[0] : '?',
                  style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.successDark),
                ),
              ),
            )
                .animate()
                .scale(
                    begin: const Offset(0.6, 0.6),
                    duration: 420.ms,
                    curve: Curves.elasticOut)
                .fadeIn(),
            const SizedBox(height: 18),
            Text('Code matched',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success)),
            const SizedBox(height: 4),
            Text(receiver.fullName,
                style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText)),
            const SizedBox(height: 4),
            Text('${receiver.accountNumber} • ${receiver.country}',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.mutedGrey)),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: requestedAmount != null
                    ? AppColors.yellowCard
                    : AppColors.pageBg,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Text(
                    requestedAmount != null
                        ? 'They are requesting'
                        : 'No amount requested',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.mutedGrey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    requestedAmount != null
                        ? '\$${requestedAmount!.toStringAsFixed(2)}'
                        : 'You choose the amount',
                    style: GoogleFonts.poppins(
                      fontSize: requestedAmount != null ? 28 : 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.mutedGrey,
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Scan again',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkText,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('Continue',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fallback for when the camera cannot be used: paste or type the payload.
class _ManualEntrySheet extends StatefulWidget {
  const _ManualEntrySheet();

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text('Enter payment code',
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText)),
              const SizedBox(height: 6),
              Text(
                'Paste the code shown under the receiver’s QR image.',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.mutedGrey),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 3,
                minLines: 2,
                style: GoogleFonts.robotoMono(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'rwandapay://pay?acct=…',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : () => Navigator.pop(context, _controller.text.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkText,
                    disabledBackgroundColor:
                        AppColors.darkText.withValues(alpha: 0.25),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Use this code',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
