import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _token;
  String? get token => _token;

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Map<String, dynamic>? _userData;
  Map<String, dynamic>? get userData => _userData;

  String get displayName {
    final firstName = _readFirstNonEmpty(_userData, [
      'first_name',
      'billing.first_name',
    ]);
    final lastName = _readFirstNonEmpty(_userData, [
      'last_name',
      'billing.last_name',
    ]);
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;

    final directName = _readFirstNonEmpty(_userData, [
      'user_display_name',
      'display_name',
      'name',
      'user_nicename',
      'nicename',
      'username',
      'user_login',
    ]);
    if (directName.isNotEmpty) return directName;

    final email = primaryEmail;
    if (email.contains('@')) {
      final localPart = email.split('@').first.trim();
      if (localPart.isNotEmpty) return localPart;
    }

    return isAuthenticated ? 'مستخدم' : 'ضيف';
  }

  String get primaryEmail {
    final email = _readFirstNonEmpty(_userData, [
      'user_email',
      'email',
      'billing.email',
    ]);
    return email.isNotEmpty ? email : 'غير متوفر';
  }

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');

    // Load associated user details
    final String? userStr = prefs.getString('user_data');
    if (userStr != null) {
      try {
        final decoded = jsonDecode(userStr);
        if (decoded is Map<String, dynamic>) {
          _userData = Map<String, dynamic>.from(decoded);
        } else if (decoded is Map) {
          _userData = decoded.map(
            (key, value) => MapEntry(key.toString(), value),
          );
        }
      } catch (e) {
        print('Error parsing user data: $e');
      }
    }

    final userId = _extractUserId(_userData);
    if (isAuthenticated && userId != null) {
      await fetchCustomerDetails(userId);
    }

    notifyListeners();
  }

  Future<bool> fetchCustomerDetails(String id) async {
    try {
      final response = await ApiService.getCustomerDetails(id);
      if (response.containsKey('id')) {
        _userData = {...?_userData, ...Map<String, dynamic>.from(response)};

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_userData));

        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Fetch customer details error: $e');
    }
    return false;
  }

  Future<bool> updateCustomerDetails(
    String id,
    Map<String, dynamic> data,
  ) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await ApiService.updateCustomerDetails(id, data);
      if (response.containsKey('error')) {
        _lastError = response['error'];
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _userData = {...?_userData, ...Map<String, dynamic>.from(response)};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_userData));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String? _lastError;
  String? get lastError => _lastError;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await ApiService.login(username, password);

      if (response['status_code'] == 200 && response.containsKey('token')) {
        _token = response['token'];
        _userData = Map<String, dynamic>.from(response);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', jsonEncode(_userData));

        final userId = _extractUserId(_userData);
        if (userId != null) {
          await fetchCustomerDetails(userId);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _lastError =
            response['message'] ?? response['code'] ?? 'فشل في تسجيل الدخول';
        print('Login API error: $_lastError');
      }
    } catch (e) {
      _lastError = 'خطأ في الاتصال بالشبكة';
      print('Login error: $e');
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final response = await ApiService.register(username, email, password);
      _isLoading = false;
      notifyListeners();

      // Check HTTP status code
      if (response['status_code'] != 200 && response['status_code'] != 201) {
        _lastError = response['message'] ?? 'حدث خطأ أثناء الإنشاء';
        print('Registration API error: $_lastError');
        return false;
      }

      // Some custom APIs return status or success boolean manually inside json
      if (response['status'] == 'error' ||
          response.containsKey('error') ||
          response['code'] == 500) {
        _lastError = response['message'] ?? 'فشل إنشاء حساب';
        print('Registration API internal error: $_lastError');
        return false;
      }

      return true;
    } catch (e) {
      _lastError = 'خطأ في الاتصال بالشبكة';
      print('Registration error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    _token = null;
    _userData = null;
    notifyListeners();
  }

  String _readFirstNonEmpty(Map<String, dynamic>? source, List<String> paths) {
    for (final path in paths) {
      final value = _valueByPath(source, path);
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  dynamic _valueByPath(Map<String, dynamic>? source, String path) {
    dynamic current = source;
    for (final part in path.split('.')) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  String? _extractUserId(Map<String, dynamic>? source) {
    final rawId =
        _valueByPath(source, 'id') ??
        _valueByPath(source, 'user_id') ??
        _valueByPath(source, 'ID') ??
        _valueByPath(source, 'data.id') ??
        _valueByPath(source, 'data.user.id');
    final id = rawId?.toString().trim();
    if (id == null || id.isEmpty || id.toLowerCase() == 'null') {
      return null;
    }
    return id;
  }
}
