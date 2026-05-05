import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../agent_debug_log.dart';

class ApiService {
  static const String baseUrl = 'https://demo.onlineezzy.com/wp-json';

  /// Clears the session and returns the user to login (set from app bootstrap).
  static Future<void> Function()? onUnauthorized;

  static bool _handlingUnauthorized = false;

  static Future<void> _notifyIfBearerUnauthorized(
    Map<String, String> requestHeaders,
    int statusCode,
  ) async {
    if (statusCode != 401 && statusCode != 403) return;
    final auth = requestHeaders['Authorization'] ?? '';
    if (!auth.startsWith('Bearer ')) return;
    final cb = onUnauthorized;
    if (cb == null) return;
    if (_handlingUnauthorized) return;
    _handlingUnauthorized = true;
    try {
      await cb();
    } finally {
      _handlingUnauthorized = false;
    }
  }

  // Primary WooCommerce keys used by most secured endpoints.
  static const String consumerKey =
      'ck_5ca575dad48fd87c2b7fae55a80096e14f90ff4f';
  static const String consumerSecret =
      'cs_5d69ab19a7f8325b4d10e6a8687ed27ea5aa0768';

  // Catalog endpoints in Postman use a dedicated key pair.
  static const String catalogConsumerKey =
      'ck_f39120cd330fd760dc139d9509f02e4b2eedf3a2';
  static const String catalogConsumerSecret =
      'cs_446625012f0190865ee5a2c87c1bbd6d3edb6c62';
  // Helper method to get basic auth header
  static String get _basicAuth =>
      'Basic ${base64Encode(utf8.encode('$consumerKey:$consumerSecret'))}';

  static String get _catalogBasicAuth =>
      'Basic ${base64Encode(utf8.encode('$catalogConsumerKey:$catalogConsumerSecret'))}';

  static dynamic _safeDecodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body);
    } catch (_) {
      return <String, dynamic>{'raw_body': body};
    }
  }

  // Headers for typical API requests
  static Future<Map<String, String>> _getHeaders({
    bool useAuth = false,
    String? cartToken,
  }) async {
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

  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/jwt-auth/v1/token');
    final response = await http
        .post(url, body: {'username': username, 'password': password})
        .timeout(const Duration(seconds: 15));

    final Map<String, dynamic> data = jsonDecode(response.body);
    data['status_code'] = response.statusCode; // Store to handle errors easily
    return data;
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final url = Uri.parse('$baseUrl/custom-api/v1/register');

    // Some WP apis crash if username has spaces. Using email prefix or stripping spaces
    String safeUsername = username.replaceAll(' ', '_');
    if (safeUsername.isEmpty) safeUsername = email.split('@').first;

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': safeUsername,
            'email': email,
            'password': password,
            'passwrord':
                password, // Handling typo from the Postman backend hook just in case
          }),
        )
        .timeout(const Duration(seconds: 15));

    final Map<String, dynamic> data = jsonDecode(response.body);
    data['status_code'] = response.statusCode; // Store to handle errors easily
    return data;
  }

  static Future<Map<String, dynamic>> getCustomerDetails(String id) async {
    final url = Uri.parse('$baseUrl/wc/v3/customers/$id');
    final response = await http
        .get(url, headers: {'Authorization': _basicAuth})
        .timeout(const Duration(seconds: 15));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateCustomerDetails(
    String id,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/wc/v3/customers/$id');
    try {
      final response = await http
          .put(
            url,
            headers: {
              'Authorization': _basicAuth,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 15));
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
      var response = await http
          .get(url, headers: {'Authorization': _catalogBasicAuth})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        response = await http
            .get(url, headers: {'Authorization': _basicAuth})
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        final queryUrl = url.replace(
          queryParameters: {
            ...url.queryParameters,
            'consumer_key': catalogConsumerKey,
            'consumer_secret': catalogConsumerSecret,
          },
        );
        response = await http
            .get(queryUrl)
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        final queryUrl = url.replace(
          queryParameters: {
            ...url.queryParameters,
            'consumer_key': consumerKey,
            'consumer_secret': consumerSecret,
          },
        );
        response = await http
            .get(queryUrl)
            .timeout(const Duration(seconds: 15));
      }

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

  static Future<List<dynamic>> getProducts({
    int? categoryId,
    List<int>? categoryIds,
  }) async {
    try {
      Uri url = Uri.parse('$baseUrl/wc/v3/products');
      if (categoryIds != null && categoryIds.isNotEmpty) {
        final joined = categoryIds.join(',');
        url = Uri.parse('$baseUrl/wc/v3/products?category=$joined');
      } else if (categoryId != null) {
        url = Uri.parse('$baseUrl/wc/v3/products?category=$categoryId');
      }
      var response = await http
          .get(url, headers: {'Authorization': _catalogBasicAuth})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        response = await http
            .get(url, headers: {'Authorization': _basicAuth})
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        final queryUrl = url.replace(
          queryParameters: {
            ...url.queryParameters,
            'consumer_key': catalogConsumerKey,
            'consumer_secret': catalogConsumerSecret,
          },
        );
        response = await http
            .get(queryUrl)
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        final queryUrl = url.replace(
          queryParameters: {
            ...url.queryParameters,
            'consumer_key': consumerKey,
            'consumer_secret': consumerSecret,
          },
        );
        response = await http
            .get(queryUrl)
            .timeout(const Duration(seconds: 15));
      }

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

  static Future<List<dynamic>> getProductVariations(
    int productId, {
    int perPage = 100,
  }) async {
    try {
      final base = Uri.parse('$baseUrl/wc/v3/products/$productId/variations');
      final url = base.replace(
        queryParameters: {
          ...base.queryParameters,
          'per_page': perPage.toString(),
        },
      );

      var response = await http
          .get(url, headers: {'Authorization': _catalogBasicAuth})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 401 || response.statusCode == 403) {
        response = await http
            .get(url, headers: {'Authorization': _basicAuth})
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        final queryUrl = url.replace(
          queryParameters: {
            ...url.queryParameters,
            'consumer_key': catalogConsumerKey,
            'consumer_secret': catalogConsumerSecret,
          },
        );
        response = await http
            .get(queryUrl)
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        final queryUrl = url.replace(
          queryParameters: {
            ...url.queryParameters,
            'consumer_key': consumerKey,
            'consumer_secret': consumerSecret,
          },
        );
        response = await http
            .get(queryUrl)
            .timeout(const Duration(seconds: 15));
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }

      print(
        'getProductVariations($productId) error: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('getProductVariations($productId) exception: $e');
    }

    return [];
  }

  static Future<Map<String, dynamic>> getSingleCategory(String id) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/products/categories/$id');
    final response = await http.get(
      url,
      headers: {'Authorization': _basicAuth},
    );
    return jsonDecode(response.body);
  }

  // --- Cart handling ---

  static Future<Map<String, dynamic>> getCart(String cartToken) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart');
    final headers = await _getHeaders(cartToken: cartToken);
    final response = await http.get(url, headers: headers);
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getCartWithMeta({
    String? cartToken,
  }) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart');
    final headers = await _getHeaders(cartToken: cartToken);
    final response = await http.get(url, headers: headers);
    final decoded = _safeDecodeBody(response.body);

    List<dynamic> items = [];
    if (decoded is Map<String, dynamic> && decoded['items'] is List) {
      items = decoded['items'] as List<dynamic>;
    }

    return {
      'items': items,
      'data': decoded,
      'cart_token':
          response.headers['cart-token'] ?? response.headers['Cart-Token'],
    };
  }

  // Normalize cart items response and carry forward server cart token.
  static Future<Map<String, dynamic>> getCartItemsWithMeta({
    String? cartToken,
  }) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items');
    final headers = await _getHeaders(cartToken: cartToken);
    final response = await http.get(url, headers: headers);
    final decoded = _safeDecodeBody(response.body);

    List<dynamic> items = [];
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['items'] is List) {
      items = decoded['items'] as List<dynamic>;
    }

    return {
      'items': items,
      'cart_token':
          response.headers['cart-token'] ?? response.headers['Cart-Token'],
    };
  }

  static Future<Map<String, dynamic>> addCartItemWithMeta({
    required int productId,
    required int quantity,
    int? variationId,
    String? cartToken,
  }) async {
    print('🛒 Adding to cart: productId=$productId, quantity=$quantity, variationId=$variationId');
    
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items');
    final headers = await _getHeaders(cartToken: cartToken);
    
    // Build request body
    // For variable products, use the variation ID as the main ID
    final itemId = (variationId != null && variationId > 0) ? variationId : productId;
    
    final body = <String, dynamic>{
      'id': itemId,
      'quantity': quantity,
    };
    
    print('🛒 Request URL: $url');
    print('🛒 Request body: ${jsonEncode(body)}');
    
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    
    print('🛒 Response status: ${response.statusCode}');
    print('🛒 Response body: ${response.body}');
    
    final decoded = _safeDecodeBody(response.body);
    return {
      'data': decoded,
      'status_code': response.statusCode,
      'cart_token':
          response.headers['cart-token'] ?? response.headers['Cart-Token'],
    };
  }

  static Future<Map<String, dynamic>> editCartItemWithMeta({
    required String itemKey,
    required int quantity,
    String? cartToken,
  }) async {
    final url = Uri.parse(
      '$baseUrl/wc/store/v1/cart/items/$itemKey?quantity=$quantity',
    );
    final headers = await _getHeaders(useAuth: true, cartToken: cartToken);
    final response = await http.put(url, headers: headers);
    await _notifyIfBearerUnauthorized(headers, response.statusCode);
    final decoded = _safeDecodeBody(response.body);
    return {
      'data': decoded,
      'status_code': response.statusCode,
      'cart_token':
          response.headers['cart-token'] ?? response.headers['Cart-Token'],
    };
  }

  static Future<Map<String, dynamic>> deleteCartItemWithMeta({
    required String itemKey,
    String? cartToken,
  }) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items/$itemKey');
    final headers = await _getHeaders(useAuth: true, cartToken: cartToken);
    final response = await http.delete(url, headers: headers);
    await _notifyIfBearerUnauthorized(headers, response.statusCode);
    final decoded = _safeDecodeBody(response.body);
    return {
      'data': decoded,
      'status_code': response.statusCode,
      'cart_token':
          response.headers['cart-token'] ?? response.headers['Cart-Token'],
    };
  }

  static Future<Map<String, dynamic>> clearCartWithMeta({
    String? cartToken,
  }) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items');
    final headers = await _getHeaders(useAuth: true, cartToken: cartToken);
    final response = await http.delete(url, headers: headers);
    await _notifyIfBearerUnauthorized(headers, response.statusCode);
    final decoded = _safeDecodeBody(response.body);
    return {
      'data': decoded,
      'status_code': response.statusCode,
      'cart_token':
          response.headers['cart-token'] ?? response.headers['Cart-Token'],
    };
  }

  // List Cart Items
  static Future<List<dynamic>> getCartItems(String cartToken) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items');
    final headers = await _getHeaders(cartToken: cartToken);
    final response = await http.get(url, headers: headers);
    final decoded = _safeDecodeBody(response.body);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic> && decoded['items'] is List) {
      return decoded['items'] as List<dynamic>;
    }
    return [];
  }

  // Single Cart Item
  static Future<Map<String, dynamic>> getSingleCartItem(
    String cartToken,
    String itemKey,
  ) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items/$itemKey');
    final headers = await _getHeaders(cartToken: cartToken);
    final response = await http.get(url, headers: headers);
    final decoded = _safeDecodeBody(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  static Future<Map<String, dynamic>> addCartItem(
    String cartToken,
    int productId,
    int quantity,
  ) async {
    final url = Uri.parse(
      '$baseUrl/wc/store/v1/cart/items?id=$productId&quantity=$quantity',
    );
    final headers = await _getHeaders(cartToken: cartToken);
    final response = await http.post(url, headers: headers);
    final decoded = _safeDecodeBody(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  static Future<Map<String, dynamic>> editCartItem(
    String cartToken,
    String itemKey,
    int quantity,
  ) async {
    final url = Uri.parse(
      '$baseUrl/wc/store/v1/cart/items/$itemKey?quantity=$quantity',
    );
    final headers = await _getHeaders(useAuth: true, cartToken: cartToken);
    final response = await http.put(url, headers: headers);
    await _notifyIfBearerUnauthorized(headers, response.statusCode);
    final decoded = _safeDecodeBody(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  static Future<Map<String, dynamic>> deleteCartItem(
    String cartToken,
    String itemKey,
  ) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items/$itemKey');
    final headers = await _getHeaders(useAuth: true, cartToken: cartToken);
    final response = await http.delete(url, headers: headers);
    await _notifyIfBearerUnauthorized(headers, response.statusCode);
    final decoded = _safeDecodeBody(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  static Future<Map<String, dynamic>> clearCart(String cartToken) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/cart/items');
    final headers = await _getHeaders(useAuth: true, cartToken: cartToken);
    final response = await http.delete(url, headers: headers);
    await _notifyIfBearerUnauthorized(headers, response.statusCode);
    final decoded = _safeDecodeBody(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  static Future<Map<String, dynamic>?> getOrder(String orderId) async {
    final url = Uri.parse('$baseUrl/wc/v3/orders/$orderId');
    final response = await http.get(
      url,
      headers: {'Authorization': _basicAuth},
    );
    if (response.statusCode == 200) {
      final decoded = _safeDecodeBody(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getCustomerOrders(
    String customerId, {
    int perPage = 50,
  }) async {
    final url = Uri.parse(
      '$baseUrl/wc/v3/orders?customer=$customerId&per_page=$perPage&orderby=date&order=desc',
    );
    final response = await http.get(
      url,
      headers: {'Authorization': _basicAuth},
    );

    if (response.statusCode != 200) {
      return [];
    }

    final decoded = _safeDecodeBody(response.body);
    if (decoded is! List) return [];

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  // --- Checkout ---

  static Future<Map<String, dynamic>> checkout(
    String cartToken,
    Map<String, dynamic> checkoutData, {
    bool useAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl/wc/store/v1/checkout');
    final headers = await _getHeaders(useAuth: useAuth, cartToken: cartToken);
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(checkoutData),
    );
    await _notifyIfBearerUnauthorized(headers, response.statusCode);
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = {'raw_body': response.body};
    }

    if (decoded is Map<String, dynamic>) {
      decoded['status_code'] = response.statusCode;
      return decoded;
    }

    return {'data': decoded, 'status_code': response.statusCode};
  }

  // --- Stripe ---

  // --- Native Stripe Payment (UPDATED to work with existing backend) ---

  // --- PayPal Native-Assisted Flow ---

  static Future<Map<String, dynamic>> createPaypalOrder({
    required String cartToken,
  }) async {
    final url = Uri.parse('$baseUrl/ezzy/v1/paypal/create-order');
    final headers = await _getHeaders(useAuth: true);
    final body = <String, dynamic>{'cart_token': cartToken};

    final response = await http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    await _notifyIfBearerUnauthorized(headers, response.statusCode);
    final decoded = _safeDecodeBody(response.body);
    if (decoded is Map<String, dynamic>) {
      decoded['status_code'] = response.statusCode;
      return decoded;
    }
    return {
      'data': decoded,
      'status_code': response.statusCode,
      'error': 'Invalid response format',
    };
  }

  static Future<Map<String, dynamic>> capturePaypalOrder({
    required String paypalOrderId,
    required String cartToken,
    required Map<String, dynamic> billingAddress,
  }) async {
    final url = Uri.parse('$baseUrl/ezzy/v1/paypal/capture-order');
    final headers = await _getHeaders(useAuth: true);
    final body = <String, dynamic>{
      'paypal_order_id': paypalOrderId,
      'cart_token': cartToken,
      'billing_address': billingAddress,
    };

    final response = await http
        .post(url, headers: headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    await _notifyIfBearerUnauthorized(headers, response.statusCode);
    final decoded = _safeDecodeBody(response.body);
    if (decoded is Map<String, dynamic>) {
      decoded['status_code'] = response.statusCode;
      return decoded;
    }
    return {
      'data': decoded,
      'status_code': response.statusCode,
      'error': 'Invalid response format',
    };
  }

  /// Creates a payment intent via backend endpoint.
  /// Backend is responsible for securely calling Stripe with secret key.
  static Future<Map<String, dynamic>> createStripePaymentIntent({
    required double amount,
    required String currency,
  }) async {
    final url = Uri.parse('$baseUrl/ezzy/v1/stripe/create-payment-intent');
    final headers = await _getHeaders(useAuth: true);
    final body = <String, dynamic>{
      // Backend endpoint expects major unit and converts internally if needed.
      'amount': double.parse(amount.toStringAsFixed(2)),
      'currency': currency.toLowerCase(),
    };

    // #region agent log
    agentDebugLog(
      location: 'api_service.dart:createStripePaymentIntent:request',
      message: 'creating intent',
      hypothesisId: 'H6',
      data: {
        'amount': body['amount'],
        'currency': body['currency'],
      },
    );
    // #endregion

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 20));

      await _notifyIfBearerUnauthorized(headers, response.statusCode);

      final decoded = _safeDecodeBody(response.body);
      
      if (decoded is Map<String, dynamic>) {
        decoded['status_code'] = response.statusCode;
        // #region agent log
        final id = decoded['payment_intent_id']?.toString() ??
            decoded['id']?.toString() ??
            '';
        agentDebugLog(
          location: 'api_service.dart:createStripePaymentIntent',
          message: 'intent response',
          hypothesisId: 'H3',
          data: {
            'httpStatus': response.statusCode,
            'hasClientSecret':
                (decoded['client_secret']?.toString().isNotEmpty ?? false),
            'idPrefix': id.length >= 10 ? id.substring(0, 10) : id,
          },
        );
        // #endregion
        return decoded;
      }

      return {
        'data': decoded,
        'status_code': response.statusCode,
        'error': 'Invalid response format',
      };
    } on TimeoutException {
      return {
        'error': 'Payment intent request timeout',
        'message':
            'تعذر الاتصال بخدمة الدفع حالياً. تحقق من الاتصال وحاول مرة أخرى.',
        'status_code': 504,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'status_code': 500,
      };
    }
  }

  /// Confirms order after successful Stripe payment via backend completion endpoint.
  static Future<Map<String, dynamic>> checkoutWithStripePayment({
    required String paymentIntentId,
    String? paymentIntentClientSecret,
    String? stripePaymentMethodId,
    required Map<String, dynamic> billingAddress,
    required String cartToken,
  }) async {
    final url = Uri.parse('$baseUrl/ezzy/v1/stripe/complete-order');
    final headers = await _getHeaders(useAuth: true);
    final body = <String, dynamic>{
      'payment_intent_id': paymentIntentId,
      'cart_token': cartToken,
      'billing_address': billingAddress,
    };

    // #region agent log
    agentDebugLog(
      location: 'api_service.dart:checkoutWithStripePayment:completeOrderRequest',
      message: 'sending complete-order request',
      hypothesisId: 'H7',
      data: {
        'hasAuth': headers.containsKey('Authorization'),
        'cartTokenLen': cartToken.length,
        'billingAddressKeys':
            billingAddress.keys.map((e) => e.toString()).toList(),
        'piPrefix': paymentIntentId.length >= 10
            ? paymentIntentId.substring(0, 10)
            : paymentIntentId,
      },
    );
    // #endregion

    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      await _notifyIfBearerUnauthorized(headers, response.statusCode);

      final decoded = _safeDecodeBody(response.body);
      final out = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
      out['status_code'] = response.statusCode;

      // #region agent log
      final msg = out['message']?.toString() ?? '';
      agentDebugLog(
        location: 'api_service.dart:checkoutWithStripePayment:completeOrderResponse',
        message: 'received complete-order response',
        hypothesisId: 'H7',
        data: {
          'httpStatus': response.statusCode,
          'status': out['status']?.toString(),
          'orderId': out['order_id']?.toString() ?? out['id']?.toString(),
          'msgLen': msg.length,
          'msgSnippet': msg.length > 100 ? msg.substring(0, 100) : msg,
        },
      );
      // #endregion

      return out;
    } on TimeoutException {
      return {
        'error': 'Complete order request timeout',
        'message':
            'الطلب استغرق وقتاً أطول من المتوقع. تحقق من الاتصال وحاول مرة أخرى.',
        'status_code': 504,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'status_code': 500,
      };
    }
  }

  // --- New Endpoints (ezzy/v1) ---

  static Future<dynamic> getShipments() async {
    final url = Uri.parse('$baseUrl/ezzy/v1/shipments');
    final authHeaders = await _getHeaders(useAuth: true);
    var response = await http.get(
      url,
      headers: {...authHeaders, 'Accept': 'application/json'},
    );

    final authValue = authHeaders['Authorization'] ?? '';
    final usedBasicAuth = authValue.startsWith('Basic ');

    if ((response.statusCode == 401 || response.statusCode == 403) &&
        !usedBasicAuth) {
      response = await http.get(
        url,
        headers: {'Authorization': _basicAuth, 'Accept': 'application/json'},
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      response = await http.get(url, headers: {'Accept': 'application/json'});
    }

    if (response.statusCode == 200) {
      final decoded = _safeDecodeBody(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is List) {
          return decoded['data'] as List<dynamic>;
        }
        if (decoded['shipments'] is List) {
          return decoded['shipments'] as List<dynamic>;
        }
      }
    }
    
    // Return error info if authentication failed
    if (response.statusCode == 401 || response.statusCode == 403) {
      final decoded = _safeDecodeBody(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    }
    
    return [];
  }

  static Future<dynamic> getShipmentDetails(String id) async {
    final url = Uri.parse('$baseUrl/ezzy/v1/shipments/$id');
    final authHeaders = await _getHeaders(useAuth: true);
    var response = await http
        .get(
          url,
          headers: {...authHeaders, 'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 12));

    final authValue = authHeaders['Authorization'] ?? '';
    final usedBasicAuth = authValue.startsWith('Basic ');

    if ((response.statusCode == 401 || response.statusCode == 403) &&
        !usedBasicAuth) {
      response = await http
          .get(
            url,
            headers: {'Authorization': _basicAuth, 'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
    }

    if (response.statusCode == 200) {
      final decoded = _safeDecodeBody(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return Map<String, dynamic>.from(decoded.first as Map);
      }
    }
    return null;
  }

  static Future<dynamic> requestShipment(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/ezzy/v1/shipments/request');
    final response = await http.post(
      url,
      headers: {
        'Authorization': _basicAuth,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getDashboard() async {
    final url = Uri.parse('$baseUrl/ezzy/v1/dashboard');
    final response = await http.get(
      url,
      headers: {'Authorization': _basicAuth},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<List<dynamic>> getSliders() async {
    final url = Uri.parse('$baseUrl/ezzy/v1/sliders');
    // Endpoint is public; sending Basic auth can return invalid_username on some setups.
    var response = await http.get(url, headers: {'Accept': 'application/json'});
    if (response.statusCode == 401 || response.statusCode == 403) {
      response = await http.get(url);
    }
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<Map<String, dynamic>?> trackShipment(String number) async {
    final res = await getShipmentDetails(number);
    if (res is Map<String, dynamic>) {
      return res;
    }
    return null;
  }

  static Future<List<dynamic>> getNotifications() async {
    final url = Uri.parse('$baseUrl/ezzy/v1/notifications');
    var headers = await _getHeaders(useAuth: true);
    var response = await http.get(url, headers: headers);

    if (response.statusCode == 401 || response.statusCode == 403) {
      response = await http.get(
        url,
        headers: {'Authorization': _basicAuth, 'Accept': 'application/json'},
      );
    }

    if (response.statusCode == 200) {
      final decoded = _safeDecodeBody(response.body);
      if (decoded is List) return decoded;
      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is List) {
          return decoded['data'] as List<dynamic>;
        }
        if (decoded['notifications'] is List) {
          return decoded['notifications'] as List<dynamic>;
        }
      }
      return [];
    }

    final decoded = _safeDecodeBody(response.body);
    String message = 'تعذر تحميل الإشعارات';
    if (decoded is Map<String, dynamic>) {
      message =
          decoded['message']?.toString() ??
          decoded['code']?.toString() ??
          message;
    }
    throw Exception('notifications_${response.statusCode}: $message');
  }

  static Future<int> getUnreadNotificationsCount() async {
    try {
      final items = await getNotifications();
      return items.where((raw) {
        if (raw is! Map) return false;
        final item = Map<String, dynamic>.from(raw);
        if (item['isUnread'] == true || item['is_unread'] == true) {
          return true;
        }
        if (item['read'] == false) return true;
        return false;
      }).length;
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> markNotificationAsRead(String id) async {
    final url = Uri.parse('$baseUrl/ezzy/v1/notifications/$id/read');
    var headers = await _getHeaders(useAuth: true);
    var response = await http.post(url, headers: headers);

    if (response.statusCode == 401 || response.statusCode == 403) {
      response = await http.post(
        url,
        headers: {'Authorization': _basicAuth, 'Accept': 'application/json'},
      );
    }

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final url = Uri.parse('$baseUrl/ezzy/v1/change_password');
    final response = await http.post(
      url,
      headers: {
        'Authorization': _basicAuth,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<dynamic> getWarehouseAddresses() async {
    final url = Uri.parse('$baseUrl/ezzy/v1/warehouse-addresses');
    final response = await http.get(
      url,
      headers: {'Authorization': _basicAuth},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }

  static Future<Map<String, dynamic>?> getPrivacyPolicy() async {
    final url = Uri.parse('$baseUrl/wp/v2/pages?slug=privacy-policy');
    final response = await http.get(
      url,
      headers: {'Authorization': _basicAuth},
    );
    if (response.statusCode == 200) {
      final List pages = jsonDecode(response.body);
      if (pages.isNotEmpty) return pages.first;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getSettings() async {
    final url = Uri.parse('$baseUrl/ezzy/v1/settings');
    final response = await http.get(
      url,
      headers: {'Authorization': _basicAuth},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> contactUs(
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('$baseUrl/ezzy/v1/contact');
    final response = await http.post(
      url,
      headers: {
        'Authorization': _basicAuth,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    return null;
  }
}
