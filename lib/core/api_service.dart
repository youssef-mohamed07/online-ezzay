import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://demo.onlineezzy.com/wp-json'; 
  static const String stripeBaseUrl = 'https://api.stripe.com/v1';

  // WooCommerce Keys (From Postman)
  static const String consumerKey = 'ck_5ca575dad48fd87c2b7fae55a80096e14f90ff4f';
  static const String consumerSecret = 'cs_5d69ab19a7f8325b4d10e6a8687ed27ea5aa0768';
  static const String stripeSecretKey = 'sk_test_STRIPE_SECRET_KEY_REMOVED';

  // Helper method to get basic auth header
  static String get _basicAuth => 'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}';

  // Headers for typical API requests
  static Future<Map<String, String>> _getHeaders({bool useAuth = false, String? cartToken}) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');
    
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (useAuth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (cartToken != null) {
      headers['Cart-Token'] = cartToken;
    }

    return headers;
  }

  // --- Auth & Users ---

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$baseUrl/jwt-auth/v1/token');
    final response = await http.post(url, body: {
      'username': username,
      'password': password,
    }).timeout(const Duration(seconds: 15));
    
    final Map<String, dynamic> data = jsonDecode(response.body);
    data['status_code'] = response.statusCode; // Store to handle errors easily
    return data;
  }

  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/custom-api/v1/register');
    
    // Some WP apis crash if username has spaces. Using email prefix or stripping spaces
    String safeUsername = username.replaceAll(' ', '_');
    if (safeUsername.isEmpty) safeUsername = email.split('@').first;

    final response = await http.post(
      url, 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': safeUsername,
        'email': email,
        'password': password, 
        'passwrord': password, // Handling typo from the Postman backend hook just in case
      })
    ).timeout(const Duration(seconds: 15));
    
    final Map<String, dynamic> data = jsonDecode(response.body);
    data['status_code'] = response.statusCode; // Store to handle errors easily
    return data;
  }

  static Future<Map<String, dynamic>> getCustomerDetails(String id) async {
    final url = Uri.parse('$baseUrl/wc/v3/customers/$id');
    final response = await http.get(url, headers: {'Authorization': _basicAuth}).timeout(const Duration(seconds: 15));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateCustomerDetails(String id, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/wc/v3/customers/$id');
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': _basicAuth,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'error': 'Failed to update customer'};
    } catch (e) {
      return {'error': 'Timeout or network error'};
    }
  }

  // --- Products & Categories ---

  static Future<List<dynamic>> getCategories() async {
    try {
      final url = Uri.parse('$baseUrl/wc/v3/products/categories');
      final response = await http.get(url, headers: {'Authorization': _basicAuth}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }
      print('getCategories error: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('getCategories exception: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getProducts() async {
    try {
      final url = Uri.parse('$baseUrl/wc/v3/products');
      final response = await http.get(url, headers: {'Authorization': _basicAuth}).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }
      print('getProducts error: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('getProducts exception: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> getSingleCategory(String id) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/products/categories/$id');
    final response = await http.get(url, headers: {'Authorization': _basicAuth});
    return jsonDecode(response.body);
  }

  // --- Cart handling ---

  static Future<Map<String, dynamic>> getCart(String cartToken) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart');
    final headers = await _getHeaders(cartToken: cartToken);
    final response = await http.get(url, headers: headers);
    return jsonDecode(response.body);
  }

  // List Cart Items
  static Future<List<dynamic>> getCartItems(String cartToken) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items');
    final headers = await _getHeaders(cartToken: cartToken);
    final response = await http.get(url, headers: headers);
    return jsonDecode(response.body);
  }

  // Single Cart Item
  static Future<Map<String, dynamic>> getSingleCartItem(String cartToken, String itemKey) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items/$itemKey');
    final headers = await _getHeaders(cartToken: cartToken);
    final response = await http.get(url, headers: headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addCartItem(String cartToken, int productId, int quantity) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items?id=$productId&quantity=$quantity');
    final headers = await _getHeaders(cartToken: cartToken);
    final response = await http.post(url, headers: headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> editCartItem(String cartToken, String itemKey, int quantity) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items/$itemKey?quantity=$quantity');
    final headers = await _getHeaders(useAuth: true, cartToken: cartToken);
    final response = await http.put(url, headers: headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteCartItem(String cartToken, String itemKey) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items/$itemKey');
    final headers = await _getHeaders(useAuth: true, cartToken: cartToken);
    final response = await http.delete(url, headers: headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> clearCart(String cartToken) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items');
    final headers = await _getHeaders(useAuth: true, cartToken: cartToken);
    final response = await http.delete(url, headers: headers);
    return jsonDecode(response.body);
  }

  // --- Checkout ---

  static Future<Map<String, dynamic>> checkout(String cartToken, Map<String, dynamic> checkoutData) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/checkout');
    final headers = await _getHeaders(cartToken: cartToken);
    final response = await http.post(url, headers: headers, body: jsonEncode(checkoutData));
    return jsonDecode(response.body);
  }

  // --- Stripe ---

  static Future<Map<String, dynamic>> createPaymentIntent(int amount, String currency, String paymentMethod) async {
    final url = Uri.parse('$stripeBaseUrl/payment_intents');
    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $stripeSecretKey',
      'Content-Type': 'application/x-www-form-urlencoded'
    }, body: {
      'amount': amount.toString(),
      'currency': currency,
      'payment_method': paymentMethod,
      'confirm': 'true'
    });
    return jsonDecode(response.body);
  }

  // Confirm Payment Intent (from Stripe Copy endpoint)
  static Future<Map<String, dynamic>> confirmPaymentIntent(String paymentIntentId, Map<String, String> paymentMethodData) async {
    final url = Uri.parse('$stripeBaseUrl/payment_intents/$paymentIntentId/confirm');
    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $stripeSecretKey',
      'Content-Type': 'application/x-www-form-urlencoded'
    }, body: paymentMethodData);
    return jsonDecode(response.body);
  }
}
