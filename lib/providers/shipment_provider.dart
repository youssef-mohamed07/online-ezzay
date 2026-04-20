import 'package:flutter/material.dart';
import '../core/api_service.dart';

class ShipmentProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _shipments = [];
  List<Map<String, dynamic>> get shipments => _shipments;

  ShipmentProvider() {
    loadShipments();
  }

  Future<void> loadShipments() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.getShipments();
      if (res is List) {
        _shipments = res
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      } else {
        _shipments = [];
      }
    } catch (e) {
      _shipments = [];
      print('Error loading shipments: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getShipmentDetails(String id) async {
    Map<String, dynamic>? result;
    try {
      result = await ApiService.getShipmentDetails(id);
    } catch (e) {
      print('Error loading shipment details: $e');
    }
    return result;
  }

  Future<Map<String, dynamic>?> trackShipment(String trackingNumber) async {
    _isLoading = true;
    notifyListeners();
    
    Map<String, dynamic>? result;
    try {
      result = await ApiService.trackShipment(trackingNumber);
    } catch (e) {
      print('Error tracking shipment: $e');
    }
    
    _isLoading = false;
    notifyListeners();
    return result;
  }
}
