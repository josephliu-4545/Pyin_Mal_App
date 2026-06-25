import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pyin_mal_app/main.dart';
import 'package:pyin_mal_app/services/cart_service.dart';
import 'package:pyin_mal_app/screens/cart_screen.dart';

/// A floating footer bar that shows how many items are in the cart and the
/// running total. It listens to [CartService] and hides itself when the cart
/// is empty. Tapping it opens the cart screen.
///
/// Drop it at the bottom of a screen's [Stack] (with `Positioned`/`Align`) or
/// pass it as a `bottomNavigationBar`.
class CartBar extends StatelessWidget {
  /// Adds bottom inset (e.g. to clear a bottom nav bar). Defaults to safe-area.
  final double bottomInset;
  const CartBar({super.key, this.bottomInset = 0});

  String _money(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return '$s MMK';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.gold : AppColors.burgundy;
    final onAccent = isDark ? AppColors.charcoal : Colors.white;

    return AnimatedBuilder(
      animation: CartService.instance,
      builder: (context, _) {
        final cart = CartService.instance;
        final count = cart.itemCount;

        // Hide entirely when the cart is empty.
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) => SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: count == 0
              ? const SizedBox.shrink()
              : Padding(
                  key: const ValueKey('cart-bar'),
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Cart icon with count badge
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(Icons.shopping_cart_rounded,
                                    color: onAccent, size: 24),
                                Positioned(
                                  right: -8,
                                  top: -8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(
                                        minWidth: 18, minHeight: 18),
                                    decoration: BoxDecoration(
                                      color: onAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$count',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Cart',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: onAccent,
                                    ),
                                  ),
                                  Text(
                                    '$count item${count == 1 ? '' : 's'}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11,
                                      color: onAccent.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _money(cart.totalPrice),
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: onAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right_rounded,
                                color: onAccent, size: 22),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
