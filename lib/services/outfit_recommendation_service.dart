import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/data/product_repository.dart';

/// Groups clothing categories into outfit "slots" so a recommendation never
/// suggests another item from the same slot as the product being viewed —
/// e.g. viewing a shirt won't recommend another shirt, but pants, jackets,
/// shoes, etc. (different slots) are all fair game.
enum OutfitSlot { tops, bottoms, outerwear, fullOutfit, footwear, accessories, other }

class OutfitRecommendationService {
  static const Map<String, OutfitSlot> _slotByCategory = {
    // tops
    'shirt': OutfitSlot.tops,
    't-shirt': OutfitSlot.tops,
    'tshirt': OutfitSlot.tops,
    'hoodie': OutfitSlot.tops,
    'sweater': OutfitSlot.tops,
    'top': OutfitSlot.tops,
    'jersey': OutfitSlot.tops,
    'blouse': OutfitSlot.tops,
    // bottoms
    'pants': OutfitSlot.bottoms,
    'pant': OutfitSlot.bottoms,
    'jeans': OutfitSlot.bottoms,
    'shorts': OutfitSlot.bottoms,
    'trousers': OutfitSlot.bottoms,
    'skirt': OutfitSlot.bottoms,
    // outerwear
    'jacket': OutfitSlot.outerwear,
    'coat': OutfitSlot.outerwear,
    'blazer': OutfitSlot.outerwear,
    // full outfit — already a complete look on its own
    'dress': OutfitSlot.fullOutfit,
    'set': OutfitSlot.fullOutfit,
    'jumpsuit': OutfitSlot.fullOutfit,
    // footwear
    'shoes': OutfitSlot.footwear,
    'shoe': OutfitSlot.footwear,
    'sneakers': OutfitSlot.footwear,
    'sandals': OutfitSlot.footwear,
    // accessories
    'bag': OutfitSlot.accessories,
    'accessory': OutfitSlot.accessories,
    'accessories': OutfitSlot.accessories,
    'hat': OutfitSlot.accessories,
    'jewelry': OutfitSlot.accessories,
  };

  static OutfitSlot _slotOf(String category) =>
      _slotByCategory[category.toLowerCase().trim()] ?? OutfitSlot.other;

  /// Products that would "complete the look" of [product] — same gender,
  /// a different outfit slot, ranked so same-shop items (closer in style)
  /// come first.
  static List<Product> recommendationsFor(Product product, {int limit = 10}) {
    final slot = _slotOf(product.category);

    final candidates = ProductRepository.allProducts.where((p) {
      if (p.id == product.id) return false;
      final genderMatches = p.gender == product.gender ||
          p.gender == 'Unisex' ||
          product.gender == 'Unisex';
      if (!genderMatches) return false;

      // Categories outside our known slots are too ambiguous to bucket
      // reliably, so just avoid recommending the exact same category.
      if (slot == OutfitSlot.other) {
        return p.category.toLowerCase() != product.category.toLowerCase();
      }
      return _slotOf(p.category) != slot;
    }).toList();

    candidates.sort((a, b) {
      final aSameShop = a.shopName == product.shopName ? 0 : 1;
      final bSameShop = b.shopName == product.shopName ? 0 : 1;
      return aSameShop.compareTo(bSameShop);
    });

    return candidates.take(limit).toList();
  }
}
