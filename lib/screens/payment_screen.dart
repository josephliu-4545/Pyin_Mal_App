import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';

/// A believable payment flow for the selected method. It does NOT talk to a
/// real payment gateway (that needs merchant credentials + a backend); instead
/// it walks the user through the same steps the real apps use:
///   • Mobile wallets (KBZPay / WavePay / AYA / UAB): enter number → enter PIN
///   • Card: 3-D Secure OTP verification
/// then a short "processing" state, and pops `true` when the payment succeeds
/// (or `null`/`false` if the user backs out).
class PaymentScreen extends StatefulWidget {
  final String label; // e.g. "KBZPay"
  final String amountLabel; // e.g. "24,000 MMK"
  final Color brand;
  final IconData icon;
  final String? logo;
  final bool isCard;

  const PaymentScreen({
    super.key,
    required this.label,
    required this.amountLabel,
    required this.brand,
    required this.icon,
    this.logo,
    this.isCard = false,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // wallet: 0 = enter number, 1 = enter PIN, 2 = processing
  // card:   0 = OTP,          1 = processing
  int _step = 0;
  String? _error;

  final _phoneCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _pinCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  bool get _processing => widget.isCard ? _step == 1 : _step == 2;

  void _startProcessing(int step) {
    setState(() => _step = step);
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  void _next() {
    setState(() => _error = null);
    if (widget.isCard) {
      if (_otpCtrl.text.trim().length < 4) {
        setState(() => _error = 'Enter the 6-digit code sent to your phone.');
        return;
      }
      _startProcessing(1);
      return;
    }
    if (_step == 0) {
      final digits = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 7) {
        setState(() => _error = 'Enter your ${widget.label} account number.');
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (_pinCtrl.text.trim().length < 6) {
        setState(() => _error = 'Enter your 6-digit PIN.');
        return;
      }
      _startProcessing(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final ink = isDark ? Colors.white : AppColors.inkBlack;

    return PopScope(
      canPop: !_processing,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            children: [
              _brandHeader(isDark),
              Expanded(
                child: _processing
                    ? _processingView(ink)
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        child: widget.isCard
                            ? _otpStep(isDark, ink)
                            : (_step == 0
                                ? _phoneStep(isDark, ink)
                                : _pinStep(isDark, ink)),
                      ),
              ),
              if (!_processing) _bottomBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ── Brand header with amount ────────────────────────────────────────────────
  Widget _brandHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.brand, Color.lerp(widget.brand, Colors.black, 0.3)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _processing ? null : () => Navigator.pop(context, false),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const Spacer(),
              const Icon(Icons.lock_rounded, color: Colors.white70, size: 15),
              const SizedBox(width: 5),
              Text('Secure payment',
                  style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.logo != null
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(widget.logo!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                Icon(widget.icon, color: widget.brand, size: 26)),
                      )
                    : Icon(widget.icon, color: widget.brand, size: 26),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label,
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800)),
                  Text('Ta Chat Nhate · Pyin Mal',
                      style: GoogleFonts.outfit(
                          color: Colors.white70, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Amount to pay',
              style:
                  GoogleFonts.outfit(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          Text(widget.amountLabel,
              style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ── Wallet: enter number ────────────────────────────────────────────────────
  Widget _phoneStep(bool isDark, Color ink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pay with ${widget.label}',
            style: GoogleFonts.rufina(
                fontSize: 22, fontWeight: FontWeight.bold, color: ink)),
        const SizedBox(height: 6),
        Text('Enter the phone number linked to your ${widget.label} wallet.',
            style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppColors.paleText : AppColors.inkGrey)),
        const SizedBox(height: 24),
        _inputField(
          isDark,
          ctrl: _phoneCtrl,
          hint: '09xxxxxxxxx',
          icon: Icons.phone_iphone_rounded,
          keyboard: TextInputType.phone,
          formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
        ),
        if (_error != null) _errorText(),
      ],
    );
  }

  // ── Wallet: enter PIN ───────────────────────────────────────────────────────
  Widget _pinStep(bool isDark, Color ink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter your ${widget.label} PIN',
            style: GoogleFonts.rufina(
                fontSize: 22, fontWeight: FontWeight.bold, color: ink)),
        const SizedBox(height: 6),
        Text('Confirm the payment with your 6-digit wallet PIN.',
            style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppColors.paleText : AppColors.inkGrey)),
        const SizedBox(height: 24),
        _codeField(isDark, ctrl: _pinCtrl, obscure: true),
        if (_error != null) _errorText(),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.verified_user_rounded, size: 15, color: widget.brand),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                  'Your PIN is encrypted and never stored by Pyin Mal.',
                  style: GoogleFonts.outfit(
                      fontSize: 11.5,
                      color: isDark ? AppColors.paleText : AppColors.inkGrey)),
            ),
          ],
        ),
      ],
    );
  }

  // ── Card: OTP ───────────────────────────────────────────────────────────────
  Widget _otpStep(bool isDark, Color ink) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('3-D Secure verification',
            style: GoogleFonts.rufina(
                fontSize: 22, fontWeight: FontWeight.bold, color: ink)),
        const SizedBox(height: 6),
        Text('We sent a one-time code to the phone number registered with '
            'your bank. Enter it to authorise this payment.',
            style: GoogleFonts.outfit(
                fontSize: 13,
                height: 1.4,
                color: isDark ? AppColors.paleText : AppColors.inkGrey)),
        const SizedBox(height: 24),
        _codeField(isDark, ctrl: _otpCtrl, obscure: false),
        if (_error != null) _errorText(),
        const SizedBox(height: 16),
        Center(
          child: Text('Didn\'t get a code?  Resend',
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.brand)),
        ),
      ],
    );
  }

  // ── Processing ──────────────────────────────────────────────────────────────
  Widget _processingView(Color ink) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: CircularProgressIndicator(
                strokeWidth: 3, color: widget.brand),
          ),
          const SizedBox(height: 22),
          Text('Confirming your payment…',
              style: GoogleFonts.outfit(
                  fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 6),
          Text('Please don\'t close this screen.',
              style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Bottom action ───────────────────────────────────────────────────────────
  Widget _bottomBar(bool isDark) {
    final String label;
    if (widget.isCard) {
      label = 'Verify & pay ${widget.amountLabel}';
    } else if (_step == 0) {
      label = 'Continue';
    } else {
      label = 'Pay ${widget.amountLabel}';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _next,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.brand,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(label,
              style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700, fontSize: 15.5)),
        ),
      ),
    );
  }

  // ── Shared widgets ──────────────────────────────────────────────────────────
  Widget _inputField(bool isDark,
      {required TextEditingController ctrl,
      required String hint,
      required IconData icon,
      TextInputType? keyboard,
      List<TextInputFormatter>? formatters}) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final fill = isDark ? AppColors.darkWarm : Colors.white;
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: GoogleFonts.outfit(color: ink, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(color: muted, fontSize: 14),
        prefixIcon: Icon(icon, color: muted, size: 20),
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: widget.brand, width: 1.6),
        ),
      ),
    );
  }

  Widget _codeField(bool isDark,
      {required TextEditingController ctrl, required bool obscure}) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final fill = isDark ? AppColors.darkWarm : Colors.white;
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      obscureText: obscure,
      maxLength: 6,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.outfit(
          color: ink,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 14),
      decoration: InputDecoration(
        counterText: '',
        hintText: '••••••',
        hintStyle: GoogleFonts.outfit(
            color: Colors.grey, fontSize: 26, letterSpacing: 14),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: widget.brand, width: 1.6),
        ),
      ),
    );
  }

  Widget _errorText() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 14, color: Color(0xFFE53935)),
          const SizedBox(width: 5),
          Text(_error!,
              style: GoogleFonts.outfit(
                  fontSize: 12, color: const Color(0xFFE53935))),
        ],
      ),
    );
  }
}
