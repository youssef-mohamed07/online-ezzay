import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final Set<int> _addingProductIds = <int>{};
  bool isAddingProduct(int productId) => _addingProductIds.contains(productId);

  List<dynamic> _cartItems = [];
  List<dynamic> get cartItems => _cartItems;

  List<String> _availablePaymentMethods = [];
  List<String> get availablePaymentMethods => _availablePaymentMethods;

  String? _lastCheckoutError;
  String? get lastCheckoutError => _lastCheckoutError;

  String? _cartToken;

  CartProvider() {
    _loadCart();
  }

  Future<void> _persistCartToken(String? token) async {
    if (token == null || token.isEmpty) return;
    _cartToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cart_token', token);
  }

  Future<void> _clearStoredCartToken() async {
    _cartToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_token');
  }

  Future<void> _loadCartToken() async {
    final prefs = await SharedPreferences.getInstance();
    _cartToken = prefs.getString('cart_token');

    // Older app versions stored a local timestamp as token; WooCommerce uses JWT-like token.
    if (_cartToken != null && !_cartToken!.contains('.')) {
      _cartToken = null;
      await prefs.remove('cart_token');
    }
  }

  Future<void> _loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_cartToken == null) await _loadCartToken();

      // Bootstrap cart session and token from WooCommerce store API.
      final bootstrap = await ApiService.getCartWithMeta(cartToken: _cartToken);
      await _persistCartToken(bootstrap['cart_token']?.toString());
      _updateAvailablePaymentMethods(bootstrap['data']);

      final response = await ApiService.getCartItemsWithMeta(
        cartToken: _cartToken,
      );
      await _persistCartToken(response['cart_token']?.toString());
      _cartItems = (response['items'] as List<dynamic>? ?? []);
    } catch (e) {
      print('Load cart error: $e');
      _cartItems = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  void _updateAvailablePaymentMethods(dynamic cartData) {
    if (cartData is! Map<String, dynamic>) return;
    final raw = cartData['payment_methods'];
    if (raw is List) {
      _availablePaymentMethods = raw
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  Future<List<String>> refreshAvailablePaymentMethods() async {
    try {
      if (_cartToken == null) await _loadCartToken();
      final cartData = await ApiService.getCartWithMeta(cartToken: _cartToken);
      await _persistCartToken(cartData['cart_token']?.toString());
      _updateAvailablePaymentMethods(cartData['data']);
      notifyListeners();
    } catch (e) {
      print('Refresh payment methods error: $e');
    }
    return _availablePaymentMethods;
  }

  bool _isCheckoutSuccess(Map<String, dynamic> response) {
    final status = response['status']?.toString().toLowerCase();
    final hasError = response['code'] != null || response['error'] != null;
    final statusCode = response['status_code'] as int? ?? 0;

    return !hasError &&
        (statusCode == 200 || statusCode == 201) &&
        (response['id'] != null ||
            status == 'processing' ||
            status == 'completed' ||
            status == 'pending' ||
            status == 'on-hold');
  }

  bool _shouldRetryCheckout(Map<String, dynamic> response) {
    final statusCode = response['status_code'] as int? ?? 0;
    final code = response['code']?.toString().toLowerCase() ?? '';
    final message = response['message']?.toString().toLowerCase() ?? '';

    if (statusCode == 401 || statusCode == 403) return true;
    return code.contains('token') ||
        code.contains('cart') ||
        message.contains('token') ||
        message.contains('cart');
  }

  Future<bool> addToCart(
    int productId,
    int quantity, {
    int? variationId,
  }) async {
    _isLoading = true;
    _addingProductIds.add(productId);
    notifyListeners();

    try {
      if (_cartToken == null) await _loadCartToken();
      final addRes = await ApiService.addCartItemWithMeta(
        productId: productId,
        quantity: quantity,
        variationId: variationId,
        cartToken: _cartToken,
      );
      var statusCode = addRes['status_code'] as int? ?? 500;
      String? nextToken = addRes['cart_token']?.toString();

      if (statusCode < 200 || statusCode >= 300) {
        // Recover from stale cart session by resetting token and retrying once.
        await _clearStoredCartToken();
        final bootstrap = await ApiService.getCartWithMeta(cartToken: null);
        await _persistCartToken(bootstrap['cart_token']?.toString());

        final retryRes = await ApiService.addCartItemWithMeta(
          productId: productId,
          quantity: quantity,
          variationId: variationId,
          cartToken: _cartToken,
        );
        statusCode = retryRes['status_code'] as int? ?? 500;
        nextToken = retryRes['cart_token']?.toString();

        if (statusCode < 200 || statusCode >= 300) {
          return false;
        }
      }

      await _persistCartToken(nextToken);

      // Refresh server cart using the latest token returned by WooCommerce.
      final response = await ApiService.getCartItemsWithMeta(
        cartToken: _cartToken,
      );
      await _persistCartToken(response['cart_token']?.toString());
      _cartItems = (response['items'] as List<dynamic>? ?? []);

      return true;
    } catch (e) {
      print('Add to cart error: $e');
      return false;
    } finally {
      _addingProductIds.remove(productId);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeCartItem(String itemKey) async {
    final previousItems = List<dynamic>.from(_cartItems);
    _cartItems = _cartItems
        .where((item) => item['key']?.toString() != itemKey)
        .toList();
    _isLoading = true;
    notifyListeners();

    try {
      if (_cartToken == null) await _loadCartToken();
      final deleteRes = await ApiService.deleteCartItemWithMeta(
        itemKey: itemKey,
        cartToken: _cartToken,
      );
      final deleteStatus = deleteRes['status_code'] as int? ?? 500;
      if (deleteStatus < 200 || deleteStatus >= 300) {
        throw Exception('Delete cart item failed with status $deleteStatus');
      }

      final response = await ApiService.getCartItemsWithMeta(
        cartToken: _cartToken,
      );
      await _persistCartToken(response['cart_token']?.toString());
      _cartItems = (response['items'] as List<dynamic>? ?? []);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Remove from cart error: $e');
      _cartItems = previousItems;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> clearCart() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_cartToken == null) await _loadCartToken();
      final clearRes = await ApiService.clearCartWithMeta(
        cartToken: _cartToken,
      );
      await _persistCartToken(clearRes['cart_token']?.toString());
      _cartItems = [];
      notifyListeners();
    } catch (e) {
      print('Clear cart error: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateCartItemQuantity(String itemKey, int quantity) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_cartToken == null) await _loadCartToken();
      final editRes = await ApiService.editCartItemWithMeta(
        itemKey: itemKey,
        quantity: quantity,
        cartToken: _cartToken,
      );
      await _persistCartToken(editRes['cart_token']?.toString());

      final response = await ApiService.getCartItemsWithMeta(
        cartToken: _cartToken,
      );
      await _persistCartToken(response['cart_token']?.toString());
      _cartItems = (response['items'] as List<dynamic>? ?? []);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Update cart item error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<Map<String, dynamic>?> checkout(
    Map<String, dynamic> checkoutData, {
    bool useAuth = true,
  }) async {
    _isLoading = true;
    _lastCheckoutError = null;
    notifyListeners();

    try {
      if (_cartToken == null) await _loadCartToken();

      // Re-bootstrap before checkout to ensure token and server cart session are valid.
      final bootstrap = await ApiService.getCartWithMeta(cartToken: _cartToken);
      await _persistCartToken(bootstrap['cart_token']?.toString());
      _updateAvailablePaymentMethods(bootstrap['data']);

      if (_cartToken == null) {
        _lastCheckoutError = 'تعذر الوصول إلى جلسة السلة.';
        _isLoading = false;
        notifyListeners();
        return {
          'code': 'missing_cart_token',
          'message': _lastCheckoutError,
          'status_code': 400,
        };
      }

      var response = await ApiService.checkout(
        _cartToken!,
        checkoutData,
        useAuth: useAuth,
      );

      if (!_isCheckoutSuccess(response) && _shouldRetryCheckout(response)) {
        await _clearStoredCartToken();
        final newCart = await ApiService.getCartWithMeta(cartToken: null);
        await _persistCartToken(newCart['cart_token']?.toString());
        _updateAvailablePaymentMethods(newCart['data']);

        if (_cartToken != null) {
          response = await ApiService.checkout(
            _cartToken!,
            checkoutData,
            useAuth: useAuth,
          );
        }
      }

      if (_isCheckoutSuccess(response)) {
        _cartItems = [];
        _isLoading = false;
        notifyListeners();
        return response;
      }

      _lastCheckoutError =
          response['message']?.toString() ?? response['code']?.toString();

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      print('Checkout error: $e');
      _lastCheckoutError = e.toString();
    }

    _isLoading = false;
    notifyListeners();
    return {
      'code': 'checkout_exception',
      'message': _lastCheckoutError ?? 'حدث خطأ أثناء إنشاء الطلب',
      'status_code': 500,
    };
  }

  Future<Map<String, dynamic>?> createPaymentIntent(
    int amount,
    String currency,
    String paymentMethod,
  ) async {
    try {
      final response = await ApiService.createPaymentIntent(
        amount,
        currency,
        paymentMethod,
      );
      return response;
    } catch (e) {
      print('Create payment intent error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> confirmPaymentIntent(
    String paymentIntentId,
    Map<String, String> paymentMethodData,
  ) async {
    try {
      final response = await ApiService.confirmPaymentIntent(
        paymentIntentId,
        paymentMethodData,
      );
      return response;
    } catch (e) {
      print('Confirm payment intent error: $e');
    }
    return null;
  }
}
