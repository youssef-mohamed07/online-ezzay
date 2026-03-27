import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _token;
  String? get token => _token;

  bool get isAuthenticated => _token != null;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    
    // Load associated user details if you kept user ID, 
    // or call fetchCustomerDetails if you have the ID.
    
    notifyListeners();
  }

  Future<bool> fetchCustomerDetails(String id) async {
    try {
      final response = await ApiService.getCustomerDetails(id);
      if (response.containsKey('id')) {
        _userData = response;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Fetch customer details error: $e');
    }
    return false;
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.login(username, password);
      if (response.containsKey('token')) {
        _token = response['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.register(username, email, password);
      _isLoading = false;
      notifyListeners();
      return true; // You should add proper check based on the actual API response
    } catch (e) {
      print('Registration error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    notifyListeners();
  }
}
