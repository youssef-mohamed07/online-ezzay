import 'package:flutter/material.dart';
import 'dart:async';

import '../core/image_url_utils.dart';
import '../core/api_service.dart';

class ShipmentProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> _shipments = [];
  List<Map<String, dynamic>> get shipments => _shipments;

  final Map<String, String> _shipmentImageUrls = {};
  final Map<String, Future<String>> _shipmentImageRequests = {};

  String? _error;
  String? get error => _error;

  bool _requiresAuth = false;
  bool get requiresAuth => _requiresAuth;

  ShipmentProvider() {
    loadShipments();
  }

  Future<void> loadShipments() async {
    _isLoading = true;
    _error = null;
    _requiresAuth = false;
    notifyListeners();

    try {
      final res = await ApiService.getShipments().timeout(
        const Duration(seconds: 10),
        onTimeout: () => <dynamic>[],
      );
      if (res is List) {
        _shipments = res
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _error = null;
      } else if (res is Map && res['code'] == 'rest_forbidden') {
        _shipments = [];
        _requiresAuth = true;
        _error = 'يجب تسجيل الدخول لعرض الشحنات';
      } else {
        _shipments = [];
        _error = null;
      }
    } catch (e) {
      _shipments = [];
      _error = 'حدث خطأ في تحميل الشحنات';
      print('Error loading shipments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getShipmentDetails(String id) async {
    Map<String, dynamic>? result;
    try {
      result = await ApiService.getShipmentDetails(id);
    } on TimeoutException {
      return null;
    } catch (e) {
      print('Error loading shipment details: $e');
    }
    return result;
  }

  String cachedShipmentImageUrl(String trackingNumber) {
    return _shipmentImageUrls[trackingNumber.trim()] ?? '';
  }

  Future<String> loadShipmentImage(
    String trackingNumber, {
    Map<dynamic, dynamic>? shipment,
  }) {
    final tracking = trackingNumber.trim();
    if (tracking.isEmpty) return Future.value('');

    final existing = _shipmentImageUrls[tracking];
    if (existing != null && existing.isNotEmpty) {
      return Future.value(existing);
    }

    final localImageUrl = shipmentImageUrl(shipment);
    if (localImageUrl.isNotEmpty) {
      _shipmentImageUrls[tracking] = localImageUrl;
      return Future.value(localImageUrl);
    }

    final inFlight = _shipmentImageRequests[tracking];
    if (inFlight != null) return inFlight;

    final request = (() async {
      try {
        final details = await getShipmentDetails(tracking).timeout(
          const Duration(seconds: 8),
          onTimeout: () => null,
        );
        final imageUrl = shipmentImageUrl(details);
        if (imageUrl.isNotEmpty) {
          _shipmentImageUrls[tracking] = imageUrl;
          notifyListeners();
        }
        return imageUrl;
      } finally {
        _shipmentImageRequests.remove(tracking);
      }
    })();

    _shipmentImageRequests[tracking] = request;
    return request;
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
