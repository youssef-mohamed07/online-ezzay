import 'package:flutter/material.dart';
import '../core/api_service.dart';

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
        ApiService.getDashboard(),
        ApiService.getSliders(),
      ]);
      
      _dashboardData = futures[0] as Map<String, dynamic>?;
      _sliders = futures[1] as List<dynamic>? ?? [];
    } catch (e) {
      print('Error loading dashboard: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
