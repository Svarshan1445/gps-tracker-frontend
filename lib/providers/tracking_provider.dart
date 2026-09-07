import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/route_model.dart';
import '../models/vehicle_model.dart';
import '../models/gps_record_model.dart';

class TrackingProvider extends ChangeNotifier {
  final ApiClient apiClient;

  RouteModel? _assignedRoute;
  VehicleModel? _assignedVehicle;
  GPSRecordModel? _latestGps;
  ETAModel? _eta;
  List<GPSRecordModel> _history = [];
  List<RouteModel> _allRoutes = [];

  bool _isLoading = false;
  bool _isPolling = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  TrackingProvider({required this.apiClient});

  RouteModel? get assignedRoute => _assignedRoute;
  VehicleModel? get assignedVehicle => _assignedVehicle;
  GPSRecordModel? get latestGps => _latestGps;
  ETAModel? get eta => _eta;
  List<GPSRecordModel> get history => _history;
  List<RouteModel> get allRoutes => _allRoutes;
  bool get isLoading => _isLoading;
  bool get isPolling => _isPolling;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> fetchAssignedData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch assigned route (enforced by backend)
      final routeJson = await apiClient.get(ApiConstants.assignedRoute);
      _assignedRoute = RouteModel.fromJson(routeJson);

      // 2. Fetch assigned vehicle (enforced by backend)
      final vehicleJson = await apiClient.get(ApiConstants.assignedVehicle);
      _assignedVehicle = VehicleModel.fromJson(vehicleJson);

      // 3. Fetch current live location
      await refreshLiveLocation();

      // 4. Fetch initial history trail
      await fetchHistory(limit: 30);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> switchToRoute(int routeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final liveJson = await apiClient.post(ApiConstants.switchCorridor(routeId));
      if (liveJson['route'] != null) {
        _assignedRoute = RouteModel.fromJson(liveJson['route']);
      }
      if (liveJson['vehicle'] != null) {
        _assignedVehicle = VehicleModel.fromJson(liveJson['vehicle']);
      }
      if (liveJson['latest_gps'] != null) {
        _latestGps = GPSRecordModel.fromJson(liveJson['latest_gps']);
      } else if (_assignedRoute != null && _assignedRoute!.waypoints.isNotEmpty) {
        final startWp = _assignedRoute!.waypoints.first;
        _latestGps = GPSRecordModel(
          id: 0,
          vehicleId: _assignedVehicle?.vehicleId ?? 'BUS-001',
          latitude: startWp.latitude,
          longitude: startWp.longitude,
          speed: 0.0,
          heading: 90.0,
          timestamp: DateTime.now(),
          receivedAt: DateTime.now(),
        );
      } else {
        _latestGps = null;
      }
      if (liveJson['eta'] != null) {
        _eta = ETAModel.fromJson(liveJson['eta']);
      } else {
        _eta = null;
      }
      _history = [];
      await fetchHistory(limit: 30);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshLiveLocation() async {
    try {
      final liveJson = await apiClient.get(ApiConstants.liveTracking);
      if (liveJson['latest_gps'] != null) {
        final newGps = GPSRecordModel.fromJson(liveJson['latest_gps']);
        _latestGps = newGps;

        // Parse live ETA if returned
        if (liveJson['eta'] != null) {
          _eta = ETAModel.fromJson(liveJson['eta']);
        }

        // Insert at start of history if new
        if (_history.isEmpty || _history.first.timestamp.isBefore(newGps.timestamp)) {
          _history.insert(0, newGps);
          if (_history.length > 100) _history.removeLast();
        }
        notifyListeners();
      }
    } catch (e) {
      // Background poll failure should not break the UI
      debugPrint('Live location poll error: $e');
    }
  }

  Future<void> fetchHistory({int limit = 50}) async {
    try {
      final historyJson = await apiClient.get('${ApiConstants.trackingHistory}?limit=$limit');
      final records = historyJson['records'] as List? ?? [];
      _history = records.map((r) => GPSRecordModel.fromJson(r)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load history: $e');
    }
  }

  Future<void> fetchAllRoutes() async {
    try {
      final routesJson = await apiClient.get(ApiConstants.allRoutes);
      if (routesJson is List) {
        _allRoutes = routesJson
            .map((r) => RouteModel.fromJson(r as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to load all routes: $e');
    }
  }

  Future<RouteModel?> createRoute(Map<String, dynamic> routeData) async {
    try {
      final res = await apiClient.post(ApiConstants.createRoute, body: routeData);
      final newRoute = RouteModel.fromJson(res);
      await fetchAllRoutes();
      return newRoute;
    } catch (e) {
      debugPrint('Failed to create route: $e');
      rethrow;
    }
  }

  void startLivePolling({Duration interval = const Duration(seconds: 3)}) {
    if (_isPolling) return;
    _isPolling = true;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) => refreshLiveLocation());
    notifyListeners();
  }

  void stopLivePolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    notifyListeners();
  }

  void reset() {
    stopLivePolling();
    _assignedRoute = null;
    _assignedVehicle = null;
    _latestGps = null;
    _eta = null;
    _history = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
