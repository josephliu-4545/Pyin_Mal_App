import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/clothing_item.dart';

/// Horizontal scrollable carousel of clothing items.
/// Tapping an item notifies [onSelected].
class ClothingSelector extends StatelessWidget {
  final List<ClothingItem> items;
  final String selectedId;
  final ValueChanged<ClothingItem> onSelected;

  const ClothingSelector({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected = item.id == selectedId;
          return _ClothingCard(
            item: item,
            isSelected: isSelected,
            onTap: () => onSelected(item),
          );
        },
      ),
    );
  }
}

class _ClothingCard extends StatelessWidget {
  final ClothingItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClothingCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 68,
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.22)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.25),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.18),
                    blurRadius: 12,
                    spreadRadius: 0,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clothing thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Image.asset(
                  item.assetPath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white.withOpacity(0.1),
                    child: Icon(
                      Icons.checkroom_rounded,
                      color: isSelected ? Colors.white : Colors.white54,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // Item name (truncated)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
