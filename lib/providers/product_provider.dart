import 'package:flutter/material.dart';
import '../core/api_service.dart';

class ProductProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isCategoriesLoading = false;

  bool get isLoading => _isLoading;
  bool get isCategoriesLoading => _isCategoriesLoading;

  List<dynamic> _products = [];
  List<dynamic> get products => _products;

  List<dynamic> _deliveryProducts = [];
  List<dynamic> get deliveryProducts => _deliveryProducts;

  List<dynamic> _categories = [];
  List<dynamic> get categories => _categories;

  ProductProvider() {
    loadCategories();
    loadProducts();
  }

  Future<void> loadCategories() async {
    _isCategoriesLoading = true;
    notifyListeners();

    try {
      _categories = await ApiService.getCategories();
    } catch (e) {
      print('Load categories error: $e');
    }

    _isCategoriesLoading = false;
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await ApiService.getProducts();
    } catch (e) {
      print('Load products error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProductsByCategory(int categoryId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _deliveryProducts = await ApiService.getProducts(categoryId: categoryId);
    } catch (e) {
      print('Load category products error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProductsByCategories(List<int> categoryIds) async {
    _isLoading = true;
    notifyListeners();

    try {
      _deliveryProducts = await ApiService.getProducts(categoryIds: categoryIds);
    } catch (e) {
      print('Load categories products error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadDeliveryProducts({
    int categoryId = 68,
    List<int>? categoryIds,
  }) async {
    if (categoryIds != null && categoryIds.isNotEmpty) {
      await loadProductsByCategories(categoryIds);
      return;
    }
    await loadProductsByCategory(categoryId);
  }

  Future<Map<String, dynamic>?> getSingleCategoryDetails(String id) async {
    try {
      final response = await ApiService.getSingleCategory(id);
      return response;
    } catch (e) {
      print('Load single category error: $e');
    }
    return null;
  }
}
