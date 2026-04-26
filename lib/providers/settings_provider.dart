import 'package:flutter/material.dart';
import '../core/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _settings;
  Map<String, dynamic>? get settings => _settings;

  String _currency = 'USD';
  String get currency => _currency;

  String _currencySymbol = '\$';
  String get currencySymbol => _currencySymbol;

  SettingsProvider() {
    loadSettings();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getSettings();
      if (data != null) {
        _settings = data;
        
        // Extract currency from settings
        if (data['currency'] != null) {
          _currency = data['currency'].toString().toUpperCase();
        }
        
        // Extract currency symbol from settings
        if (data['currency_symbol'] != null) {
          _currencySymbol = data['currency_symbol'].toString();
        } else {
          // Fallback to common currency symbols
          _currencySymbol = _getCurrencySymbol(_currency);
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'IQD':
        return 'د.ع';
      case 'SAR':
        return 'ر.س';
      case 'AED':
        return 'د.إ';
      case 'EGP':
        return 'ج.م';
      case 'JOD':
        return 'د.أ';
      case 'KWD':
        return 'د.ك';
      default:
        return currencyCode;
    }
  }

  String formatCurrency(double value) {
    final formattedValue = value.toStringAsFixed(2);
    return '$formattedValue $currencySymbol';
  }

  String formatPrice(double value) {
    return value.toStringAsFixed(2);
  }
}
