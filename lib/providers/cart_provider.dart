import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _cartItems = [];
  List<dynamic> get cartItems => _cartItems;

  String? _cartToken;

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCartToken() async {
    final prefs = await SharedPreferences.getInstance();
    _cartToken = prefs.getString('cart_token');
    if (_cartToken == null) {
      _cartToken = DateTime.now().millisecondsSinceEpoch.toString(); // Generate simple fallback
      await prefs.setString('cart_token', _cartToken!);
    }
  }

  Future<void> _loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_cartToken == null) await _loadCartToken();
      final response = await ApiService.getCart(_cartToken!);
      _cartItems = response['items'] ?? [];
    } catch (e) {
      print('Load cart error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addToCart(int productId, int quantity) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_cartToken == null) await _loadCartToken();
      final response = await ApiService.addCartItem(_cartToken!, productId, quantity);
      if (response.containsKey('items')) {
        _cartItems = response['items'];
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Add to cart error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> removeCartItem(String itemKey) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_cartToken == null) return false;
      final response = await ApiService.deleteCartItem(_cartToken!, itemKey);
      if (response.containsKey('items')) {
         _cartItems = response['items'] ?? []; // some APIs return updated list
      } else {
         _cartItems.removeWhere((item) => item['key'] == itemKey);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Remove from cart error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> clearCart() async {
    try {
      if (_cartToken == null) return;
      await ApiService.clearCart(_cartToken!);
      _cartItems = [];
      notifyListeners();
    } catch (e) {
      print('Clear cart error: $e');
    }
  }

  Future<bool> updateCartItemQuantity(String itemKey, int quantity) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_cartToken == null) return false;
      final response = await ApiService.editCartItem(_cartToken!, itemKey, quantity);
      if (response.containsKey('items')) {
        _cartItems = response['items'] ?? [];
      }
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

  Future<Map<String, dynamic>?> checkout(Map<String, dynamic> checkoutData) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_cartToken == null) return null;
      final response = await ApiService.checkout(_cartToken!, checkoutData);
      
      // If checkout is successful, you might want to clear the cart locally
      if (response['status'] == 'processing' || response['status'] == 'completed' || response['id'] != null) {
        _cartItems = [];
      }
      
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      print('Checkout error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<Map<String, dynamic>?> createPaymentIntent(int amount, String currency, String paymentMethod) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.createPaymentIntent(amount, currency, paymentMethod);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      print('Create payment intent error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<Map<String, dynamic>?> confirmPaymentIntent(String paymentIntentId, Map<String, String> paymentMethodData) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.confirmPaymentIntent(paymentIntentId, paymentMethodData);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      print('Confirm payment intent error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return null;
  }

  Future<List<dynamic>?> getCartItems() async {
    try {
      if (_cartToken == null) await _loadCartToken();
      final response = await ApiService.getCartItems(_cartToken!);
      return response;
    } catch (e) {
      print('Get cart items error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getSingleCartItem(String itemKey) async {
    try {
      if (_cartToken == null) await _loadCartToken();
      final response = await ApiService.getSingleCartItem(_cartToken!, itemKey);
      return response;
    } catch (e) {
      print('Get single cart item error: $e');
      return null;
    }
  }
}
