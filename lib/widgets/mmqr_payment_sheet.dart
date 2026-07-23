import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pyin_mal_app/main.dart';

/// ── MMQR (MyanmarPay national QR) payment sheet ──────────────────────────────
///
/// DEMO / SANDBOX ONLY. Ta Chat Nhate has no live payment gateway yet, so this
/// screen simulates what a real customer-to-merchant MMQR payment would look
/// like. It renders a genuine EMVCo-format MMQR payload (the same TLV structure
/// KBZPay / WavePay / AYA Pay / CB Pay actually scan), then fakes the "waiting →
/// paid" confirmation instead of talking to a real acquirer.
///
/// Returns `true` from the sheet when the (simulated) payment succeeds, `false`
/// (or `null`) if the user backs out.
class MmqrPaymentSheet extends StatefulWidget {
  final double amount;
  final String orderRef;

  const MmqrPaymentSheet({
    super.key,
    required this.amount,
    required this.orderRef,
  });

  /// Convenience launcher. Resolves to `true` when the demo payment "succeeds".
  static Future<bool> show(
    BuildContext context, {
    required double amount,
    required String orderRef,
  }) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => MmqrPaymentSheet(
        amount: amount,
        orderRef: orderRef,
      ),
    );
    return ok ?? false;
  }

  @override
  State<MmqrPaymentSheet> createState() => _MmqrPaymentSheetState();
}

enum _PayStatus { waiting, processing, success }

/// Brand name shown as the MMQR merchant.
const String _merchantName = 'Ta Chat Nhate';

class _MmqrPaymentSheetState extends State<MmqrPaymentSheet> {
  _PayStatus _status = _PayStatus.waiting;
  late final String _payload;
  Timer? _countdown;
  int _secondsLeft = 300; // 5-minute QR validity, like a real dynamic MMQR

  // The wallets that participate in the MyanmarPay MMQR switch.
  static const _networks = <String>[
    'KBZPay',
    'WavePay',
    'AYA Pay',
    'CB Pay',
    'UAB Pay',
    'OK\$',
    'A+ Wallet',
  ];

  @override
  void initState() {
    super.initState();
    _payload = _buildMmqrPayload();
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 0) {
        t.cancel();
      } else if (_status == _PayStatus.waiting) {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  String get _timerText {
    final m = (_secondsLeft ~/ 60).toString();
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$s MMK';
  }

  // ── Simulated payment confirmation ──────────────────────────────────────────
  Future<void> _simulatePayment() async {
    if (_status != _PayStatus.waiting) return;
    setState(() => _status = _PayStatus.processing);
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    setState(() => _status = _PayStatus.success);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.charcoal : AppColors.cream;
    final ink = isDark ? Colors.white : AppColors.inkBlack;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.6,
      maxChildSize: 0.96,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _grabber(isDark),
            _mmqrHeader(isDark),
            Expanded(
              child: _status == _PayStatus.success
                  ? _successView(isDark, ink)
                  : SingleChildScrollView(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _qrCard(isDark, ink),
                          const SizedBox(height: 18),
                          _networksRow(isDark),
                          const SizedBox(height: 18),
                          _howToNote(isDark),
                          const SizedBox(height: 18),
                          _demoBadge(isDark),
                        ],
                      ),
                    ),
            ),
            if (_status != _PayStatus.success) _bottomBar(isDark, ink),
          ],
        ),
      ),
    );
  }

  Widget _grabber(bool isDark) => Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: (isDark ? AppColors.paleText : AppColors.inkGrey).withOpacity(0.4),
          borderRadius: BorderRadius.circular(2),
        ),
      );

  // ── MyanmarPay-style branded header band ────────────────────────────────────
  Widget _mmqrHeader(bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF00695C), Color(0xFF00897B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.qr_code_2_rounded,
                color: Color(0xFF00695C), size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('mmqr.brand'.tr(),
                    style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                Text('mmqr.standard'.tr(),
                    style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.85), fontSize: 11)),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Color(0xFFE53935), shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Color(0xFFFFC107), shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  // ── The scannable QR card ───────────────────────────────────────────────────
  Widget _qrCard(bool isDark, Color ink) {
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
      ),
      child: Column(
        children: [
          // Merchant + amount
          Text(_merchantName.toUpperCase(),
              style: GoogleFonts.rufina(
                  fontSize: 18, fontWeight: FontWeight.bold, color: ink)),
          const SizedBox(height: 2),
          Text('mmqr.merchant_sub'.tr(),
              style: GoogleFonts.outfit(fontSize: 11, color: muted)),
          const SizedBox(height: 12),
          Text(_money(widget.amount),
              style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.gold : AppColors.burgundy)),
          const SizedBox(height: 16),

          // QR with a centered brand chip
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFEDE7DC)),
                ),
                child: QrImageView(
                  data: _payload,
                  version: QrVersions.auto,
                  size: 208,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1A1210),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1A1210),
                  ),
                ),
              ),
              // Center merchant chip (like MMQR logo overlay)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00695C), width: 2),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Color(0xFF00695C), size: 24),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Expiry countdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined, size: 15, color: muted),
              const SizedBox(width: 6),
              Text('mmqr.expires_in'.tr(namedArgs: {'time': _timerText}),
                  style: GoogleFonts.outfit(fontSize: 12, color: muted)),
            ],
          ),
          const SizedBox(height: 4),
          Text('mmqr.ref'.tr(namedArgs: {'ref': widget.orderRef}),
              style: GoogleFonts.outfit(
                  fontSize: 10.5, color: muted.withOpacity(0.7))),
        ],
      ),
    );
  }

  // ── Participating wallets ───────────────────────────────────────────────────
  Widget _networksRow(bool isDark) {
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    return Column(
      children: [
        Text('mmqr.scan_prompt'.tr(),
            style: GoogleFonts.outfit(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: muted)),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          // A "works with" strip — MMQR is interoperable, so every listed app
          // can scan the same code. None is pre-selected; the customer picks
          // inside their own banking app.
          children: _networks.map((n) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkWarm : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
                ),
              ),
              child: Text(n,
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.inkBlack)),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── How-to steps ────────────────────────────────────────────────────────────
  Widget _howToNote(bool isDark) {
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    Widget step(String n, String t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 20,
                height: 20,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.gold : AppColors.burgundy)
                      .withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(n,
                    style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.gold : AppColors.burgundy)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(t,
                    style: GoogleFonts.outfit(
                        fontSize: 12.5, height: 1.4, color: muted)),
              ),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('mmqr.how_to'.tr(),
              style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 12),
          step('1', 'mmqr.step1'.tr()),
          step('2', 'mmqr.step2'.tr()),
          step(
              '3',
              'mmqr.step3'.tr(namedArgs: {
                'amount': _money(widget.amount),
                'merchant': _merchantName,
              })),
        ],
      ),
    );
  }

  // ── Honest "this is a demo" badge ───────────────────────────────────────────
  Widget _demoBadge(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withOpacity(isDark ? 0.12 : 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: Color(0xFFB8860B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'mmqr.demo_note'.tr(),
              style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  height: 1.4,
                  color: isDark ? AppColors.paleText : const Color(0xFF7A5C00)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom action bar ───────────────────────────────────────────────────────
  Widget _bottomBar(bool isDark, Color ink) {
    final processing = _status == _PayStatus.processing;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkWarm : Colors.white,
          border: Border(
            top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
          ),
        ),
        child: Row(
          children: [
            OutlinedButton(
              onPressed: processing ? null : () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.paleText : AppColors.inkGrey,
                side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('mmqr.cancel'.tr(),
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: processing ? null : _simulatePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF00897B).withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: processing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Text('mmqr.confirming'.tr(),
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text('mmqr.pay_preview'.tr(),
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Success state ───────────────────────────────────────────────────────────
  Widget _successView(bool isDark, Color ink) {
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
                color: Color(0xFF2E7D32), shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 20),
          Text('mmqr.success_title'.tr(),
              style: GoogleFonts.rufina(
                  fontSize: 22, fontWeight: FontWeight.bold, color: ink)),
          const SizedBox(height: 8),
          Text(
              'mmqr.success_desc'.tr(namedArgs: {
                'amount': _money(widget.amount),
                'merchant': _merchantName,
              }),
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13.5, color: muted, height: 1.4)),
          const SizedBox(height: 6),
          Text('mmqr.placing_order'.tr(),
              style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: isDark ? AppColors.gold : AppColors.burgundy,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── EMVCo MMQR payload builder ──────────────────────────────────────────────
  // Produces a real EMVCo-format TLV string (the same layout MMQR uses), so the
  // rendered QR is structurally authentic even though the merchant IDs are
  // placeholders. Format: id(2) + length(2) + value.
  String _buildMmqrPayload() {
    String tlv(String id, String value) =>
        id + value.length.toString().padLeft(2, '0') + value;

    final amount = widget.amount.toStringAsFixed(0);

    // Merchant account information template (id 30) — GUID + merchant/acquirer.
    final merchantAccount = tlv('00', 'mm.com.myanmarpay') + // GUID
        tlv('01', '99900${Random(widget.orderRef.hashCode).nextInt(9999999).toString().padLeft(7, '0')}');

    final buffer = StringBuffer()
      ..write(tlv('00', '01')) // Payload format indicator
      ..write(tlv('01', '12')) // Point of initiation — 12 = dynamic
      ..write(tlv('30', merchantAccount)) // Merchant account info
      ..write(tlv('52', '5651')) // MCC — clothing stores
      ..write(tlv('53', '104')) // Currency — 104 = MMK
      ..write(tlv('54', amount)) // Transaction amount
      ..write(tlv('58', 'MM')) // Country
      ..write(tlv('59', 'TA CHAT NHATE')) // Merchant name
      ..write(tlv('60', 'YANGON')) // Merchant city
      ..write(tlv('62', tlv('01', widget.orderRef))); // Additional data — ref

    // CRC (id 63, length 04) is computed over everything including "6304".
    final toCrc = '${buffer.toString()}6304';
    final crc = _crc16(toCrc).toRadixString(16).toUpperCase().padLeft(4, '0');
    return '$toCrc$crc';
  }

  // CRC-16/CCITT-FALSE, per the EMVCo QR spec.
  int _crc16(String data) {
    int crc = 0xFFFF;
    for (final code in data.codeUnits) {
      crc ^= code << 8;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc;
  }
}
