import 'package:flutter/material.dart';

class ShipmentProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _shipments = [];
  List<Map<String, dynamic>> get shipments => _shipments;

  ShipmentProvider() {
    _loadShipments();
  }

  Future<void> _loadShipments() async {
    _isLoading = true;
    notifyListeners();

    // Mock API call delay
    await Future.delayed(const Duration(seconds: 2));

    // Currently mocked as there's no WooCommerce shipment API yet
    _shipments = [
      {
        'id': 'TRK-100234',
        'status': 'في المستودع',
        'date': '2026-03-27',
        'source': 'الرياض',
        'destination': 'جدة',
        'items': 3,
        'weight': '5.2 كجم',
      },
      {
        'id': 'TRK-100235',
        'status': 'في الطريق',
        'date': '2026-03-26',
        'source': 'مكة',
        'destination': 'الدمام',
        'items': 1,
        'weight': '1.5 كجم',
      },
      {
        'id': 'TRK-100236',
        'status': 'تم التسليم',
        'date': '2026-03-20',
        'source': 'المدينة',
        'destination': 'الطائف',
        'items': 5,
        'weight': '10.0 كجم',
      },
    ];

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> trackShipment(String trackingNumber) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1)); // Mock Network delay
    
    _isLoading = false;
    notifyListeners();
    
    try {
      return _shipments.firstWhere((s) => s['id'] == trackingNumber);
    } catch (_) {
      return null; // Not found
    }
  }
}
