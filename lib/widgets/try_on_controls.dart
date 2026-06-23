import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clothing_item.dart';

/// Bottom control panel for the AR Fitting Room.
/// Provides size selector, color selector, and Add to Cart button.
class TryOnControls extends StatelessWidget {
  final ClothingItem item;
  final String selectedSize;
  final ClothingColor? selectedColor;
  final ValueChanged<String> onSizeChanged;
  final ValueChanged<ClothingColor> onColorChanged;
  final VoidCallback onAddToCart;

  static const List<String> sizes = ['S', 'M', 'L', 'XL'];

  const TryOnControls({
    super.key,
    required this.item,
    required this.selectedSize,
    required this.selectedColor,
    required this.onSizeChanged,
    required this.onColorChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row: Price + Size selector ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Price
              Text(
                item.price,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              // Size chips
              Row(
                children: sizes.map((size) {
                  final isSelected = selectedSize == size;
                  return GestureDetector(
                    onTap: () => onSizeChanged(size),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(left: 6),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          size,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? const Color(0xFF1C1A1A)
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // ── Color selector ─────────────────────────────────────────────────
        if (item.availableColors.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Text(
                  'Color',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(width: 10),
                ...item.availableColors.map((c) {
                  final isSelected = selectedColor?.name == c.name;
                  return GestureDetector(
                    onTap: () => onColorChanged(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 8),
                      width: isSelected ? 26 : 22,
                      height: isSelected ? 26 : 22,
                      decoration: BoxDecoration(
                        color: c.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.35),
                          width: isSelected ? 2.5 : 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: c.color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                )
                              ]
                            : [],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

        // ── Add to Cart button ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onAddToCart,
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: Text(
                'Add to Cart',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1C1A1A),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
