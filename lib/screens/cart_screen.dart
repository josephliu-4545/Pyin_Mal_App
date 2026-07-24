import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/widgets/cdn_image.dart';
import 'package:pyin_mal_app/screens/checkout_screen.dart';
import 'package:pyin_mal_app/screens/login_screen.dart';
import 'package:pyin_mal_app/services/fitting_session.dart';
import 'package:pyin_mal_app/services/size_advisor.dart';
import 'package:pyin_mal_app/widgets/size_fit_banner.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _handleCheckout(BuildContext context, CartService cart) async {
    if (cart.items.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Not signed in → take them to the Login screen first. If they sign in,
      // come back and continue straight to checkout.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('cart.login_prompt'.tr())),
      );
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (!context.mounted) return;
      // Only proceed if they actually signed in.
      if (FirebaseAuth.instance.currentUser == null) return;
    }

    // Navigate to OpenCart checkout screen for shipping address + order placement.
    // Points are recorded in Firebase after the order succeeds (inside CheckoutScreen).
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;

    return Scaffold(
      backgroundColor: isDark ? AppColors.charcoal : AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.inkBlack),
        title: Text(
          'cart.title'.tr(),
          style: GoogleFonts.rufina(
            color: isDark ? Colors.white : AppColors.inkBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: CartService.instance,
        builder: (context, _) {
          final cart = CartService.instance;
          
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: isDark ? AppColors.darkBorder : AppColors.inkGrey.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'cart.empty'.tr(),
                    style: GoogleFonts.outfit(fontSize: 18, color: isDark ? AppColors.paleText : AppColors.inkGrey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _CartItemTile(item: item, isDark: isDark, accent: accent);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkWarm : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.charcoal.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    )
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('cart.total'.tr(), style: GoogleFonts.outfit(fontSize: 18, color: isDark ? AppColors.paleText : AppColors.inkGrey)),
                          Text(
                            '${cart.totalPrice.toStringAsFixed(0)} MMK',
                            style: GoogleFonts.rufina(fontSize: 24, fontWeight: FontWeight.bold, color: accent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _handleCheckout(context, cart),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: isDark ? AppColors.charcoal : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'cart.checkout'.tr(),
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatefulWidget {
  final CartItem item;
  final bool isDark;
  final Color accent;

  const _CartItemTile({required this.item, required this.isDark, required this.accent});

  @override
  State<_CartItemTile> createState() => _CartItemTileState();
}

class _CartItemTileState extends State<_CartItemTile> {
  /// Size-fit notice for this line item against the active wearer, or null.
  String? _warning;

  @override
  void initState() {
    super.initState();
    FittingSession.instance.addListener(_check);
    _check();
  }

  @override
  void didUpdateWidget(covariant _CartItemTile old) {
    super.didUpdateWidget(old);
    if (old.item.size != widget.item.size ||
        old.item.productId != widget.item.productId) {
      _check();
    }
  }

  @override
  void dispose() {
    FittingSession.instance.removeListener(_check);
    super.dispose();
  }

  Future<void> _check() async {
    final c = await SizeAdvisor.checkGarment(
      productId: widget.item.productId,
      size: widget.item.size,
      garment: 'item',
    );
    if (mounted) setState(() => _warning = c.message);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isDark = widget.isDark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkWarm : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.charcoal.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isDark ? AppColors.darkBorder : AppColors.creamAlt,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CdnImage(
                item.image,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColors.inkBlack),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.color.isNotEmpty ? '${item.color} • ' : ''}Size: ${item.size} • ${item.price}',
                  style: GoogleFonts.outfit(fontSize: 13, color: isDark ? AppColors.paleText : AppColors.inkGrey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => CartService.instance.updateQuantity(item, item.quantity - 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.inkGrey.withOpacity(0.3)),
                        ),
                        child: Icon(Icons.remove, size: 14, color: isDark ? Colors.white : AppColors.inkBlack),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${item.quantity}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => CartService.instance.updateQuantity(item, item.quantity + 1),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.inkGrey.withOpacity(0.3)),
                        ),
                        child: Icon(Icons.add, size: 14, color: isDark ? Colors.white : AppColors.inkBlack),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => CartService.instance.removeFromCart(item),
          ),
            ],
          ),
          // Non-blocking size notice for this line item.
          if (_warning != null) ...[
            const SizedBox(height: 10),
            SizeFitBanner(message: _warning!, isDark: isDark),
          ],
        ],
      ),
    );
  }
}
