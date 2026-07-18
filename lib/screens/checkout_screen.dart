import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/screens/shop_screen.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/services/opencart_service.dart';
import 'package:pyin_mal_app/services/database_service.dart';
import 'package:pyin_mal_app/services/wardrobe_service.dart';
import 'package:pyin_mal_app/data/product_repository.dart';
import 'package:pyin_mal_app/core/guide_keys.dart';
import 'package:pyin_mal_app/widgets/mmqr_payment_sheet.dart';

// ── Payment option model ──────────────────────────────────────────────────────
enum _PayKind { wallet, card, cod }

class _PayOption {
  final String id;
  final String label;
  final String sub;
  final IconData icon;
  final Color color;
  final _PayKind kind;
  /// Optional brand logo asset. Falls back to [icon] if the file is missing.
  final String? logo;
  const _PayOption(this.id, this.label, this.sub, this.icon, this.color, this.kind,
      {this.logo});
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();

  // Card fields (only validated when a card is selected)
  final _cardNumberCtrl = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _cardExpiryCtrl = TextEditingController();
  final _cardCvvCtrl = TextEditingController();

  bool _placing = false;

  // Mobile wallets + card + cash on delivery
  static const _payOptions = <_PayOption>[
    _PayOption('kpay', 'KBZPay', 'MMQR mobile wallet', Icons.account_balance_wallet_rounded,
        Color(0xFF1565C0), _PayKind.wallet, logo: 'assets/images/pay_kbzpay.png'),
    _PayOption('wave', 'WavePay', 'MMQR mobile wallet', Icons.waves_rounded,
        Color(0xFFFFB300), _PayKind.wallet, logo: 'assets/images/pay_wavepay.png'),
    _PayOption('aya', 'AYA Pay', 'MMQR mobile wallet', Icons.payments_rounded,
        Color(0xFFE53935), _PayKind.wallet, logo: 'assets/images/pay_ayapay.png'),
    _PayOption('uab', 'UAB Pay', 'MMQR mobile wallet', Icons.account_balance_rounded,
        Color(0xFF00897B), _PayKind.wallet, logo: 'assets/images/pay_uabpay.png'),
    _PayOption('card', 'Credit / Debit Card', 'Visa, Mastercard', Icons.credit_card_rounded,
        Color(0xFF6A1B9A), _PayKind.card, logo: 'assets/images/pay_card.png'),
    _PayOption('cod', 'Cash on Delivery', 'Pay when it arrives', Icons.local_shipping_rounded,
        Color(0xFF455A64), _PayKind.cod),
  ];

  String _selectedPay = 'kpay';

  _PayOption get _selectedOption =>
      _payOptions.firstWhere((o) => o.id == _selectedPay);

  static const double _shippingFee = 3000; // flat-rate delivery

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _cardNumberCtrl.dispose();
    _cardNameCtrl.dispose();
    _cardExpiryCtrl.dispose();
    _cardCvvCtrl.dispose();
    super.dispose();
  }

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$s MMK';
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // MMQR flow: mobile wallets pay via the MyanmarPay national QR standard.
    // We show the (demo) MMQR payment sheet first and only place the order once
    // the payment is confirmed. Card / cash-on-delivery skip this step.
    if (_selectedOption.kind == _PayKind.wallet) {
      final cart = CartService.instance;
      final total = cart.totalPrice + (cart.items.isEmpty ? 0 : _shippingFee);
      final orderRef =
          'PM${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      final paid = await MmqrPaymentSheet.show(
        context,
        amount: total.toDouble(),
        walletLabel: _selectedOption.label,
        walletColor: _selectedOption.color,
        walletIcon: _selectedOption.icon,
        walletLogo: _selectedOption.logo,
        orderRef: orderRef,
      );
      if (!mounted || !paid) return;
    }

    setState(() => _placing = true);

    // Split the single "Your Name" into first / last for OpenCart.
    final fullName = _nameCtrl.text.trim();
    final parts = fullName.split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : parts.first;

    // 1. Push each cart item to OpenCart server-side cart
    for (final item in CartService.instance.items) {
      await OpenCartService.addToCart(
        productId: item.productId,
        quantity: item.quantity,
        options: {'size': item.size},
      );
    }

    // 2. Set shipping address (147 = Myanmar country ID in OpenCart)
    await OpenCartService.setShippingAddress(
      firstname: firstName,
      lastname: lastName,
      address1: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      countryId: '147',
      zoneId: '0',
    );

    // 3. Place the order
    final orderId = await OpenCartService.placeOrder();

    setState(() => _placing = false);

    if (!mounted) return;

    if (orderId != null) {
      final db = DatabaseService();
      for (final item in CartService.instance.items) {
        final itemTotal = item.parsedPrice * item.quantity;
        await db.addPurchase(item.productId, itemTotal);

        // Auto-add the purchased item to the user's digital wardrobe — the
        // product's own image/category/brand are already known, so this
        // skips the AI classification round-trip entirely. Never let a
        // wardrobe write failure block order completion.
        try {
          final product = ProductRepository.getProductById(item.productId);
          await WardrobeService.addFromCatalog(
            imageUrl: item.image,
            category: product?.category ?? 'other',
            brand: item.brand,
            productId: item.productId,
          );
        } catch (e) {
          debugPrint('Wardrobe auto-add failed for ${item.productId}: $e');
        }
      }
      CartService.instance.clearCart();
      _showSuccessDialog(orderId.toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('checkout.error'.tr())),
      );
    }
  }

  void _showSuccessDialog(String orderId) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: isDark ? AppColors.charcoal : Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 18),
              Text('checkout.success_title'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rufina(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.inkBlack,
                  )),
              const SizedBox(height: 10),
              Text('checkout.success_desc'.tr(args: [orderId]),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? AppColors.paleText : AppColors.inkGrey,
                  )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.inkBlack,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('checkout.ok'.tr(),
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = CartService.instance;
    final bg = isDark ? AppColors.charcoal : AppColors.cream;
    final ink = isDark ? Colors.white : AppColors.inkBlack;

    final subtotal = cart.totalPrice;
    final total = subtotal + (cart.items.isEmpty ? 0 : _shippingFee);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('checkout.title'.tr(),
            style: GoogleFonts.rufina(fontWeight: FontWeight.bold, color: ink, fontSize: 22)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Order Summary ─────────────────────────────────────────────
              _sectionCard(
                isDark,
                icon: Icons.receipt_long_rounded,
                title: 'checkout.order_summary'.tr(),
                child: Column(
                  children: [
                    ...cart.items.map((item) => _summaryItem(isDark, item)),
                    const SizedBox(height: 4),
                    // Add items → back to shopping
                    _addItemsButton(isDark),
                    const SizedBox(height: 8),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
                    _totalRow(isDark, 'Subtotal', _money(subtotal), bold: false),
                    const SizedBox(height: 8),
                    _totalRow(isDark, 'Delivery',
                        cart.items.isEmpty ? '—' : _money(_shippingFee), bold: false),
                    const SizedBox(height: 10),
                    Divider(color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
                    _totalRow(isDark, 'checkout.total'.tr(), _money(total.toDouble()),
                        bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Shipping Details ──────────────────────────────────────────
              _sectionCard(
                isDark,
                icon: Icons.local_shipping_outlined,
                title: 'checkout.shipping_details'.tr(),
                child: Column(
                  children: [
                    _field(isDark, _nameCtrl, 'Your Name', Icons.person_outline_rounded,
                        keyboard: TextInputType.name),
                    const SizedBox(height: 14),
                    _field(isDark, _phoneCtrl, 'Phone Number', Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'checkout.required'.tr();
                          final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
                          if (digits.length < 7) return 'Enter a valid phone number';
                          return null;
                        }),
                    const SizedBox(height: 14),
                    _field(isDark, _addressCtrl, 'checkout.address'.tr(),
                        Icons.home_outlined),
                    const SizedBox(height: 14),
                    _field(isDark, _cityCtrl, 'checkout.city'.tr(),
                        Icons.location_city_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Payment Method ────────────────────────────────────────────
              _sectionCard(
                isDark,
                icon: Icons.payment_rounded,
                title: 'checkout.payment_method'.tr(),
                child: Column(
                  children: [
                    ..._payOptions.map((o) => _payTile(isDark, o)),
                    if (_selectedOption.kind == _PayKind.card) ...[
                      const SizedBox(height: 8),
                      _buildCardForm(isDark),
                    ],
                    if (_selectedOption.kind == _PayKind.wallet) ...[
                      const SizedBox(height: 12),
                      _walletNote(isDark),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // ── Sticky Place Order bar ──────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkWarm : Colors.white,
            border: Border(
              top: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    key: GuideKeys.checkoutPlaceOrder,
                    onPressed: (_placing || cart.items.isEmpty) ? null : _placeOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.inkBlack,
                      disabledBackgroundColor:
                          (isDark ? AppColors.darkBorder : AppColors.creamAlt),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _placing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.inkBlack),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text('checkout.place_order'.tr(),
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Reusable section card ─────────────────────────────────────────────────
  Widget _sectionCard(bool isDark,
      {required IconData icon, required String title, required Widget child}) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : AppColors.creamCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: GoogleFonts.rufina(
                      fontSize: 17, fontWeight: FontWeight.bold, color: ink)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Text field ────────────────────────────────────────────────────────────
  Widget _field(bool isDark, TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboard,
      List<TextInputFormatter>? formatters,
      String? Function(String?)? validator}) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final fill = isDark ? AppColors.charcoal : AppColors.cream;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      inputFormatters: formatters,
      style: GoogleFonts.outfit(color: ink, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: muted),
        prefixIcon: Icon(icon, color: muted, size: 20),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.6),
        ),
      ),
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty) ? 'checkout.required'.tr() : null,
    );
  }

  // ── Payment option tile ─────────────────────────────────────────────────────
  Widget _payTile(bool isDark, _PayOption o) {
    final selected = _selectedPay == o.id;
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return GestureDetector(
      onTap: () => setState(() => _selectedPay = o.id),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? accent.withOpacity(0.10)
              : (isDark ? AppColors.charcoal : AppColors.cream),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? accent
                : (isDark ? AppColors.darkBorder : AppColors.creamAlt),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: o.logo != null ? Colors.white : o.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              clipBehavior: Clip.antiAlias,
              child: o.logo != null
                  ? Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        o.logo!,
                        fit: BoxFit.contain,
                        // Fall back to the colored icon if the logo isn't added yet.
                        errorBuilder: (_, __, ___) => Icon(o.icon, color: o.color, size: 22),
                      ),
                    )
                  : Icon(o.icon, color: o.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.label,
                      style: GoogleFonts.outfit(
                          fontSize: 14, fontWeight: FontWeight.w600, color: ink)),
                  Text(o.sub,
                      style: GoogleFonts.outfit(fontSize: 11, color: muted)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? accent : muted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Wallet redirect note ────────────────────────────────────────────────────
  Widget _walletNote(bool isDark) {
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.charcoal : AppColors.cream),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.qr_code_2_rounded, size: 16, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'mmqr.note'.tr(namedArgs: {'wallet': _selectedOption.label}),
              style: GoogleFonts.outfit(fontSize: 12, color: muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card details form ───────────────────────────────────────────────────────
  Widget _buildCardForm(bool isDark) {
    return Column(
      children: [
        _field(isDark, _cardNumberCtrl, 'Card Number', Icons.credit_card_rounded,
            keyboard: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
            ],
            validator: (v) {
              if (_selectedOption.kind != _PayKind.card) return null;
              final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
              if (d.length < 15) return 'Enter a valid card number';
              return null;
            }),
        const SizedBox(height: 14),
        _field(isDark, _cardNameCtrl, 'Name on Card', Icons.badge_outlined,
            validator: (v) {
          if (_selectedOption.kind != _PayKind.card) return null;
          return (v == null || v.trim().isEmpty) ? 'checkout.required'.tr() : null;
        }),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _field(isDark, _cardExpiryCtrl, 'MM/YY', Icons.calendar_today_outlined,
                  keyboard: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9/]')),
                    LengthLimitingTextInputFormatter(5),
                  ],
                  validator: (v) {
                    if (_selectedOption.kind != _PayKind.card) return null;
                    return (v == null || v.trim().length < 4)
                        ? 'Invalid'
                        : null;
                  }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _field(isDark, _cardCvvCtrl, 'CVV', Icons.lock_outline_rounded,
                  keyboard: TextInputType.number,
                  formatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                  ],
                  validator: (v) {
                    if (_selectedOption.kind != _PayKind.card) return null;
                    return (v == null || v.trim().length < 3) ? 'Invalid' : null;
                  }),
            ),
          ],
        ),
      ],
    );
  }

  // ── Order summary item with image ───────────────────────────────────────────
  Widget _summaryItem(bool isDark, CartItem item) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final lineTotal = item.parsedPrice * item.quantity;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56,
              height: 56,
              child: CdnImage(
                item.image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark ? AppColors.charcoal : AppColors.cream,
                  child: Icon(Icons.checkroom_rounded, color: muted, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w600, color: ink)),
                const SizedBox(height: 3),
                Text(
                    '${item.color.isNotEmpty ? '${item.color}  ·  ' : ''}Size ${item.size}  ·  Qty ${item.quantity}',
                    style: GoogleFonts.outfit(fontSize: 11, color: muted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(_money(lineTotal),
              style: GoogleFonts.outfit(
                  fontSize: 13, fontWeight: FontWeight.w700, color: accent)),
        ],
      ),
    );
  }

  // ── "Add items" button → back to the Shop screen ────────────────────────────
  Widget _addItemsButton(bool isDark) {
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShopScreen()),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: accent),
            const SizedBox(width: 6),
            Text('Add items',
                style: GoogleFonts.outfit(
                    fontSize: 14, fontWeight: FontWeight.w700, color: accent)),
          ],
        ),
      ),
    );
  }

  // ── Total / subtotal row ────────────────────────────────────────────────────
  Widget _totalRow(bool isDark, String label, String value, {required bool bold}) {
    final ink = isDark ? Colors.white : AppColors.inkBlack;
    final muted = isDark ? AppColors.paleText : AppColors.inkGrey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: bold ? 16 : 13,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  color: bold ? ink : muted)),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: bold ? 17 : 13,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: ink)),
        ],
      ),
    );
  }
}
