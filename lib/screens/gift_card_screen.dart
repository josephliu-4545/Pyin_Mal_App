import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';

/// "Gift Card" quick-access — buy a Ta Chat Nhate gift card for someone, or
/// redeem a code onto your own balance. Demo flow (no real payment/wallet).
class GiftCardScreen extends StatefulWidget {
  const GiftCardScreen({super.key});

  @override
  State<GiftCardScreen> createState() => _GiftCardScreenState();
}

class _GiftCardScreenState extends State<GiftCardScreen> {
  int _tab = 0; // 0 = Buy, 1 = Redeem
  int _amount = 25000;
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  static const _amounts = [10000, 25000, 50000, 100000, 200000];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  String _money(int v) =>
      '${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')} MMK';

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(behavior: SnackBarBehavior.floating, content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final bg = isDark ? AppColors.charcoal : const Color(0xFFF5F2EE);
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: ink),
        title: Text('Gift Cards',
            style: GoogleFonts.rufina(
                fontWeight: FontWeight.bold, color: ink, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Text('Give the gift of style — or redeem a card you received.',
              style: GoogleFonts.outfit(fontSize: 13, color: muted)),
          const SizedBox(height: 16),

          // ── Gift card visual ──
          _giftCardVisual(),
          const SizedBox(height: 20),

          // ── Buy / Redeem toggle ──
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
            ),
            child: Row(
              children: [
                _tabBtn(0, 'Buy a card', Icons.card_giftcard_rounded, accent,
                    ink, muted, isDark),
                _tabBtn(1, 'Redeem code', Icons.redeem_rounded, accent, ink,
                    muted, isDark),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (_tab == 0)
            _buySection(isDark, accent, ink, muted)
          else
            _redeemSection(isDark, accent, ink, muted),
        ],
      ),
    );
  }

  // ── The card graphic ────────────────────────────────────────────────────────
  Widget _giftCardVisual() {
    return AspectRatio(
      aspectRatio: 1.6,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B1A2F), Color(0xFF3E0D18)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B1A2F).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withOpacity(0.10),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: -40,
                child: Icon(Icons.card_giftcard_rounded,
                    size: 150, color: Colors.white.withOpacity(0.08)),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            color: AppColors.gold, size: 18),
                        const SizedBox(width: 8),
                        Text('TA CHAT NHATE',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: Colors.white)),
                        const Spacer(),
                        Text('GIFT CARD',
                            style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: AppColors.gold)),
                      ],
                    ),
                    const Spacer(),
                    Text('Value',
                        style: GoogleFonts.outfit(
                            fontSize: 11, color: Colors.white60)),
                    Text(_money(_amount),
                        style: GoogleFonts.rufina(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('•••• •••• •••• 2048',
                        style: GoogleFonts.outfit(
                            fontSize: 13,
                            letterSpacing: 2,
                            color: Colors.white54)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBtn(int idx, String label, IconData icon, Color accent, Color ink,
      Color muted, bool isDark) {
    final sel = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: sel ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: sel
                      ? (isDark ? AppColors.charcoal : Colors.white)
                      : muted),
              const SizedBox(width: 7),
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: sel
                          ? (isDark ? AppColors.charcoal : Colors.white)
                          : ink)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Buy ─────────────────────────────────────────────────────────────────────
  Widget _buySection(bool isDark, Color accent, Color ink, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose an amount',
            style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _amounts.map((a) {
            final sel = _amount == a;
            return GestureDetector(
              onTap: () => setState(() => _amount = a),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                decoration: BoxDecoration(
                  color: sel
                      ? accent.withOpacity(0.14)
                      : (isDark ? Colors.white10 : Colors.white),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: sel
                          ? accent
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.creamAlt),
                      width: sel ? 1.6 : 1),
                ),
                child: Text(_money(a),
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sel ? accent : ink)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        _field(_nameCtrl, "Recipient's name", Icons.person_outline_rounded,
            isDark, accent),
        const SizedBox(height: 12),
        _field(_msgCtrl, 'Personal message (optional)',
            Icons.edit_note_rounded, isDark, accent,
            maxLines: 2),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_nameCtrl.text.trim().isEmpty) {
                _toast("Please enter the recipient's name");
                return;
              }
              _toast(
                  '${_money(_amount)} gift card sent to ${_nameCtrl.text.trim()}! 🎁');
              _nameCtrl.clear();
              _msgCtrl.clear();
            },
            icon: const Icon(Icons.card_giftcard_rounded, size: 18),
            label: Text('Buy & send · ${_money(_amount)}',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: isDark ? AppColors.charcoal : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _infoNote(
            'Gift cards never expire and can be used on anything in the app.',
            isDark,
            accent,
            muted),
      ],
    );
  }

  // ── Redeem ──────────────────────────────────────────────────────────────────
  Widget _redeemSection(bool isDark, Color accent, Color ink, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Enter your gift card code',
            style: GoogleFonts.outfit(
                fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
        const SizedBox(height: 10),
        _field(_codeCtrl, 'XXXX - XXXX - XXXX', Icons.confirmation_number_outlined,
            isDark, accent,
            formatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 -]')),
            ]),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_codeCtrl.text.trim().length < 6) {
                _toast('Enter a valid gift card code');
                return;
              }
              _toast('Gift card redeemed! Balance added to your account. 🎉');
              _codeCtrl.clear();
            },
            icon: const Icon(Icons.redeem_rounded, size: 18),
            label: Text('Redeem to my balance',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: isDark ? AppColors.charcoal : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _infoNote(
            'Your code is on the card or in the email you received. It adds instantly to your balance.',
            isDark,
            accent,
            muted),
      ],
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      bool isDark, Color accent,
      {int maxLines = 1, List<TextInputFormatter>? formatters}) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final fill = isDark ? AppColors.darkWarm : Colors.white;
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      inputFormatters: formatters,
      style: GoogleFonts.outfit(fontSize: 14, color: ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.outfit(fontSize: 13, color: muted),
        prefixIcon: Icon(icon, size: 19, color: accent),
        filled: true,
        fillColor: fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
      ),
    );
  }

  Widget _infoNote(String text, bool isDark, Color accent, Color muted) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.outfit(
                    fontSize: 11.5, height: 1.4, color: muted)),
          ),
        ],
      ),
    );
  }
}
