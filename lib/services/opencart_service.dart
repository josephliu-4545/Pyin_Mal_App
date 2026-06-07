import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pyin_mal_app/models/product.dart';

// OpenCart REST API service.
//
// HOW TO SET UP OPENCART:
// 1. Install OpenCart on XAMPP: download from opencart.com, extract to htdocs/opencart
// 2. Run the installer at http://localhost/opencart/install/
// 3. In OpenCart admin: Extensions → APIs → Add → create an API user, note the key
// 4. Change _baseUrl below to your server URL (use your PC's IP for Android emulator,
//    e.g. http://10.0.2.2/opencart for Android emulator, http://localhost/opencart for web)
//
// The OpenCart built-in API is at /index.php?route=api/...
// For a cleaner REST API, install the free "OpenCart REST API" extension from the marketplace.

class OpenCartService {
  // ── CONFIGURATION ──────────────────────────────────────────────────────────
  // Change this to your OpenCart installation URL.
  // Android emulator → use 10.0.2.2 instead of localhost
  // Real device on same WiFi → use your PC's local IP (e.g. 192.168.1.5)
  static const String _baseUrl = 'http://10.0.2.2/opencart';

  // Your OpenCart API key (from admin → Extensions → APIs)
  static const String _apiKey = '2oF2plC7VDcPqALSJYDeyH0UCB0YrCXxgnIZHeVx6CKTBpFqsXG8M6VXjgVW3DhNzJ1RMqRC8aRVAu1l2MvvZA3cioLGU0OJaWqlXnHDMAGpeU0RLC7ucUjze2EUbzyPjkcohKxtWZRllTG8O1NloM0Nlh7i1bqdVqmlautvDtd128ed3N7bKzRDfJFYhLzxNXLrqG8fThfn6NXdBdENlbuSxtITj1ddm4TOBFcsxoGCu7N6g8orq4a0lyqaoDvf';

  // Session token — obtained once via login and reused
  static String? _apiToken;

  // ── SESSION / AUTH ─────────────────────────────────────────────────────────

  // Authenticate with the OpenCart API to get a session token.
  // Call this once before making any other API calls.
  static Future<bool> authenticate() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/index.php?route=api/login'),
        body: {'key': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _apiToken = data['api_token'];
        debugPrint('OpenCart auth success, token: $_apiToken');
        return _apiToken != null;
      }
    } catch (e) {
      debugPrint('OpenCart auth error: $e');
    }
    return false;
  }

  // ── PRODUCTS ───────────────────────────────────────────────────────────────

  // Fetch all products (paginated — limit 100 per page).
  static Future<List<Product>> fetchProducts({
    int page = 1,
    int limit = 100,
    String? category,
  }) async {
    await _ensureAuthenticated();

    try {
      final params = {
        'route': 'catalog/product',
        'api_token': _apiToken ?? '',
        'page': '$page',
        'limit': '$limit',
        if (category != null) 'filter_category_id': category,
      };

      final uri = Uri.parse('$_baseUrl/index.php').replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List products = data['products'] ?? [];
        return products.map((p) => Product.fromOpenCart(p)).toList();
      }
    } catch (e) {
      debugPrint('OpenCart fetchProducts error: $e');
    }
    return [];
  }

  // Fetch a single product by ID.
  static Future<Product?> fetchProductById(String productId) async {
    await _ensureAuthenticated();

    try {
      final uri = Uri.parse('$_baseUrl/index.php').replace(queryParameters: {
        'route': 'catalog/product/info',
        'api_token': _apiToken ?? '',
        'product_id': productId,
      });

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['product'] != null) {
          return Product.fromOpenCart(data['product']);
        }
      }
    } catch (e) {
      debugPrint('OpenCart fetchProductById error: $e');
    }
    return null;
  }

  // ── CART ───────────────────────────────────────────────────────────────────

  // Add a product to the OpenCart server-side cart.
  static Future<bool> addToCart({
    required String productId,
    required int quantity,
    Map<String, String>? options, // e.g. {'17': 'L'} for size option id → value
  }) async {
    await _ensureAuthenticated();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/index.php?route=api/cart/add'),
        body: {
          'api_token': _apiToken ?? '',
          'product_id': productId,
          'quantity': '$quantity',
          if (options != null)
            ...options.map((k, v) => MapEntry('option[$k]', v)),
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] != null;
      }
    } catch (e) {
      debugPrint('OpenCart addToCart error: $e');
    }
    return false;
  }

  // ── CHECKOUT / ORDER ───────────────────────────────────────────────────────

  // Set the shipping address before placing an order.
  static Future<bool> setShippingAddress({
    required String firstname,
    required String lastname,
    required String address1,
    required String city,
    required String countryId, // e.g. '147' for Myanmar
    required String zoneId,
  }) async {
    await _ensureAuthenticated();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/index.php?route=api/shipping/address'),
        body: {
          'api_token': _apiToken ?? '',
          'firstname': firstname,
          'lastname': lastname,
          'address_1': address1,
          'city': city,
          'country_id': countryId,
          'zone_id': zoneId,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('OpenCart setShippingAddress error: $e');
      return false;
    }
  }

  // Place an order (Cash on Delivery payment method).
  static Future<String?> placeOrder() async {
    await _ensureAuthenticated();

    try {
      // 1. Set payment method to COD
      await http.post(
        Uri.parse('$_baseUrl/index.php?route=api/payment/method'),
        body: {
          'api_token': _apiToken ?? '',
          'payment_method': 'cod',
        },
      );

      // 2. Set shipping method to flat rate
      await http.post(
        Uri.parse('$_baseUrl/index.php?route=api/shipping/method'),
        body: {
          'api_token': _apiToken ?? '',
          'shipping_method': 'flat.flat',
        },
      );

      // 3. Place the order
      final response = await http.post(
        Uri.parse('$_baseUrl/index.php?route=api/order/add'),
        body: {'api_token': _apiToken ?? ''},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['order_id']?.toString();
      }
    } catch (e) {
      debugPrint('OpenCart placeOrder error: $e');
    }
    return null;
  }

  // ── INTERNAL ───────────────────────────────────────────────────────────────

  static Future<void> _ensureAuthenticated() async {
    if (_apiToken == null) {
      await authenticate();
    }
  }
}
