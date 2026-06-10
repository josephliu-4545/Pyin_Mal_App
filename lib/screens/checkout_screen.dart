import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/services/opencart_service.dart';
import 'package:pyin_mal_app/services/database_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _placing = true);

    // 1. Push each cart item to OpenCart server-side cart
    for (final item in CartService.instance.items) {
      await OpenCartService.addToCart(
        productId: item.productId,
        quantity: item.quantity,
        options: {'size': item.size}, // adjust option key to match your OpenCart setup
      );
    }

    // 2. Set shipping address (147 = Myanmar country ID in OpenCart)
    await OpenCartService.setShippingAddress(
      firstname: _firstNameCtrl.text.trim(),
      lastname: _lastNameCtrl.text.trim(),
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
      // Record purchase in Firebase for loyalty points
      final db = DatabaseService();
      for (final item in CartService.instance.items) {
        final itemTotal = item.parsedPrice * item.quantity;
        await db.addPurchase(item.productId, itemTotal);
      }
      CartService.instance.clearCart();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('checkout.success_title'.tr()),
          content: Text('checkout.success_desc'.tr(args: [orderId.toString()])),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // back to cart
                Navigator.of(context).pop(); // back to shop
              },
              child: Text('checkout.ok'.tr()),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('checkout.error'.tr())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text('checkout.title'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('checkout.shipping_details'.tr(),
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _field(_firstNameCtrl, 'checkout.first_name'.tr())),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_lastNameCtrl, 'checkout.last_name'.tr())),
                ],
              ),
              const SizedBox(height: 12),
              _field(_addressCtrl, 'checkout.address'.tr()),
              const SizedBox(height: 12),
              _field(_cityCtrl, 'checkout.city'.tr()),
              const SizedBox(height: 24),
              Text('checkout.order_summary'.tr(),
                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...cart.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${item.name} × ${item.quantity} (${item.size})',
                              style: GoogleFonts.outfit(fontSize: 13)),
                        ),
                        Text(item.price, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('checkout.total'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text(
                    '${cart.totalPrice.toStringAsFixed(0)} MMK',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('checkout.payment_method'.tr(),
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _placing ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _placing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('checkout.place_order'.tr(),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: (v) => (v == null || v.trim().isEmpty) ? 'checkout.required'.tr() : null,
    );
  }
}
