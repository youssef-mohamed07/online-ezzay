import 'package:flutter/material.dart';
import 'dart:async';

import '../core/api_service.dart';
import '../core/dashboard_payload.dart';

class DashboardProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  List<dynamic> _sliders = [];
  List<dynamic> get sliders => _sliders;

  DashboardProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final futures = await Future.wait([
        ApiService.getDashboard().timeout(
          const Duration(seconds: 8),
          onTimeout: () => null,
        ),
        ApiService.getSliders().timeout(
          const Duration(seconds: 8),
          onTimeout: () => <dynamic>[],
        ),
      ]).timeout(const Duration(seconds: 10));
      
      final dashRaw = futures[0];
      if (dashRaw == null) {
        _dashboardData = null;
      } else {
        _dashboardData = DashboardPayload.unwrap(dashRaw);
      }
      _sliders = futures[1] as List<dynamic>? ?? [];
    } catch (e) {
      print('Error loading dashboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
