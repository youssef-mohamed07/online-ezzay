import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://yourwebsite.com/wp-json'; // Update with your actual domain
  static const String stripeBaseUrl = 'https://api.stripe.com/v1';

  // Replace with your keys
  static const String consumerKey = 'ck_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  static const String consumerSecret = 'cs_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
  static const String stripeSecretKey = 'sk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxx';

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
    });
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register(String username, String email, String password) async {
    final url = Uri.parse('$baseUrl/custom-api/v1/register');
    final response = await http.post(
      url, 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password, // Note: fixing spelling from postman 'passwrord'
      })
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getCustomerDetails(String id) async {
    final url = Uri.parse('$baseUrl/wc/v3/customers/$id');
    final response = await http.get(url, headers: {'Authorization': _basicAuth});
    return jsonDecode(response.body);
  }

  // --- Products & Categories ---

  static Future<List<dynamic>> getCategories() async {
    final url = Uri.parse('$baseUrl/wc/v3/products/categories');
    final response = await http.get(url, headers: {'Authorization': _basicAuth});
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getProducts() async {
    final url = Uri.parse('$baseUrl/wc/v3/products');
    final response = await http.get(url, headers: {'Authorization': _basicAuth});
    return jsonDecode(response.body);
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
}
