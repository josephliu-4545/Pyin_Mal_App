import 'package:pyin_mal_app/models/product.dart';
import 'package:pyin_mal_app/services/opencart_service.dart';

class ProductRepository {
  // Cached products fetched from OpenCart.
  // Falls back to _localProducts if OpenCart is unreachable.
  static List<Product> _cachedProducts = [];
  static bool _loaded = false;

  static List<Product> get allProducts =>
      _loaded && _cachedProducts.isNotEmpty ? _cachedProducts : _localProducts;

  // Fetch from OpenCart and cache. Call this once at app startup or on shop open.
  static Future<void> loadFromOpenCart() async {
    try {
      final products = await OpenCartService.fetchProducts();
      if (products.isNotEmpty) {
        _cachedProducts = products;
        _loaded = true;
      }
    } catch (_) {
      // Falls back to local data below
    }
  }

  static Product? getProductById(String id) {
    try {
      return allProducts.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // ── Local fallback data (used when OpenCart is not yet set up) ─────────────
  static final List<Product> _localProducts = [
    // 3D Test Product
    Product(
      id: 'hoodie_cotton_3d',
      name: 'Cotton Sweatshirt',
      price: '50,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/NRF Deathwish hoodie0.jpg',
      category: 'Hoodie',
      gender: 'Male',
      brand: 'Fartech',
      shopName: 'Pyin Mal Official',
      description: 'Black pullover sweatshirt made from 100% soft premium cotton. Clean minimal design, no front graphics.',
      tags: ['black', 'sweatshirt', 'hoodie', 'pullover', 'cotton', 'minimal', 'no-graphic', 'plain', 'male'],
    ),
    Product(
      id: 'hoodie_deathwish',
      name: 'NRF Deathwish Hoodie',
      price: '45,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/NRF Deathwish hoodie0.jpg',
      category: 'Hoodie',
      gender: 'Male',
      brand: 'NRF',
      shopName: 'Pyin Mal Official',
      description: 'Black heavyweight pullover hoodie with bold gothic skull and dark graphic print on the front. Streetwear style with brushed fleece interior.',
      tags: ['black', 'hoodie', 'pullover', 'gothic', 'skull', 'dark graphic', 'heavyweight', 'streetwear', 'front print', 'male'],
    ),
    Product(
      id: 'hoodie_ajohn',
      name: 'AJOHN V2 Hoodie',
      price: '38,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/AJOHN V2 HOODIE.jpg',
      category: 'Hoodie',
      gender: 'Male',
      brand: 'AJOHN',
      shopName: 'Pyin Mal Official',
      description: 'Pullover hoodie with embroidered AJOHN logo on chest. Refined silhouette, cotton-polyester blend, subtle branding only.',
      tags: ['hoodie', 'pullover', 'embroidered logo', 'subtle branding', 'minimal graphic', 'cotton', 'male'],
    ),
    Product(
      id: 'hoodie_abcd',
      name: 'ABCD 2XL Zip Up Hoodie',
      price: '35,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/ABCD 2XL ZIP UP HOODIE0.jpg',
      category: 'Hoodie',
      gender: 'Male',
      brand: 'ABCD',
      shopName: 'Pyin Mal Official',
      description: 'Oversized zip-up hoodie with full front zipper and kangaroo pocket. ABCD lettering on front. Relaxed baggy fit.',
      tags: ['hoodie', 'zip-up', 'zipper', 'oversized', 'baggy', 'kangaroo pocket', 'lettering', 'front print', 'male'],
    ),
    Product(
      id: 'hoodie_v1',
      name: 'V1 Introduction Hoodie',
      price: '32,000 MMK',
      image: 'assets/images/Male/Nrf/Hoodie/V1 INTRODUCTION Hoodie .jpg',
      category: 'Hoodie',
      gender: 'Male',
      brand: 'NRF',
      shopName: 'Pyin Mal Official',
      description: 'Clean minimal pullover hoodie with small NRF wordmark logo. No large graphics, simple and understated design.',
      tags: ['hoodie', 'pullover', 'minimal', 'clean', 'wordmark', 'small logo', 'no large graphic', 'male'],
    ),
    Product(
      id: 'tee_abcd',
      name: 'ABCD Tee',
      price: '15,000 MMK',
      image: 'assets/images/Male/Nrf/Tee/ABCD TEE.jpg',
      category: 'T-Shirt',
      gender: 'Male',
      brand: 'ABCD',
      shopName: 'Pyin Mal Official',
      description: 'Lightweight everyday t-shirt with ABCD lettering graphic on the chest. 100% combed cotton, crew neck, regular fit.',
      tags: ['t-shirt', 'tee', 'crew neck', 'lettering', 'text graphic', 'cotton', 'lightweight', 'casual', 'male'],
    ),
    Product(
      id: 'tee_acid',
      name: 'ACID T-Shirt',
      price: '18,000 MMK',
      image: 'assets/images/Male/Nrf/Tee/ACID TSHIRT 0.jpg',
      category: 'T-Shirt',
      gender: 'Male',
      brand: 'NRF',
      shopName: 'Pyin Mal Official',
      description: 'Streetwear t-shirt with bold ACID text and distressed or wash-effect print. Relaxed fit with dropped shoulders.',
      tags: ['t-shirt', 'tee', 'acid', 'bold text', 'distressed print', 'washed', 'streetwear', 'relaxed fit', 'dropped shoulder', 'male'],
    ),
    Product(
      id: 'tee_nrfc',
      name: 'NRFC Jersey',
      price: '22,000 MMK',
      image: 'assets/images/Male/Nrf/Tee/NRFC Jersey0.jpg',
      category: 'T-Shirt',
      gender: 'Male',
      brand: 'NRF',
      shopName: 'Pyin Mal Official',
      description: 'Sports-style jersey with NRFC crest badge on the chest. Mesh or moisture-wicking fabric, sporty streetwear design.',
      tags: ['jersey', 't-shirt', 'sport', 'crest', 'badge', 'mesh fabric', 'moisture-wicking', 'sporty', 'streetwear', 'male'],
    ),
    Product(
      id: 'tee_lapses',
      name: 'LAPSES Tee Oatmeal',
      price: '19,000 MMK',
      image: 'assets/images/Male/Nrf/Tee/LAPSES TSHIRT OATMEAL0.jpg',
      category: 'T-Shirt',
      gender: 'Male',
      brand: 'LAPSES',
      shopName: 'Pyin Mal Official',
      description: 'Neutral oatmeal / cream / beige coloured t-shirt with subtle LAPSES tonal logo. Plain relaxed everyday tee, no bold graphics.',
      tags: ['t-shirt', 'tee', 'oatmeal', 'beige', 'cream', 'neutral', 'subtle logo', 'tonal', 'plain', 'minimal', 'male'],
    ),
    Product(
      id: 'set_luna_1',
      name: 'Luna Set 1',
      price: '55,000 MMK',
      image: 'assets/images/Female/dress.set/Luna/luna set1.jpg',
      category: 'Set',
      gender: 'Female',
      brand: 'Luna',
      shopName: 'Luna Boutique',
      description: 'Elegant coordinated two-piece set for women. Feminine cut with soft fabric, suitable for casual or evening wear.',
      tags: ['set', 'two-piece', 'coordinated', 'feminine', 'elegant', 'women', 'female', 'soft fabric', 'casual', 'evening'],
    ),
    Product(
      id: 'set_luna_2',
      name: 'Luna Set 2',
      price: '55,000 MMK',
      image: 'assets/images/Female/dress.set/Luna/luna set2.jpg',
      category: 'Set',
      gender: 'Female',
      brand: 'Luna',
      shopName: 'Luna Boutique',
      description: 'Flowing women\'s co-ord set with relaxed top and wide-leg matching trousers. Lightweight summer fabric.',
      tags: ['set', 'co-ord', 'flowing', 'wide-leg', 'trousers', 'summer', 'lightweight', 'relaxed', 'women', 'female'],
    ),
    Product(
      id: 'set_luna_3',
      name: 'Luna Set 3',
      price: '55,000 MMK',
      image: 'assets/images/Female/dress.set/Luna/luna set3.jpg',
      category: 'Set',
      gender: 'Female',
      brand: 'Luna',
      shopName: 'Luna Boutique',
      description: 'Monochrome women\'s set with structured blazer-style top and tailored shorts. Polished and smart look.',
      tags: ['set', 'monochrome', 'blazer', 'structured', 'tailored', 'shorts', 'smart', 'polished', 'women', 'female'],
    ),
    Product(
      id: 'set_luna_4',
      name: 'Luna Set 4',
      price: '55,000 MMK',
      image: 'assets/images/Female/dress.set/Luna/luna set4.jpg',
      category: 'Set',
      gender: 'Female',
      brand: 'Luna',
      shopName: 'Luna Boutique',
      description: 'Wrap-style women\'s set with adjustable ties and draped silhouette. Flattering feminine design.',
      tags: ['set', 'wrap', 'draped', 'adjustable ties', 'feminine', 'flattering', 'silhouette', 'women', 'female'],
    ),
  ];
}
