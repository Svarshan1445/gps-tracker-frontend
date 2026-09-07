import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;

  UserModel? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({required this.apiClient});

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> login(String emailOrUsername, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post(
        ApiConstants.login,
        body: {
          'email_or_username': emailOrUsername.trim(),
          'password': password.trim(),
        },
      );

      _token = response['access_token'];
      apiClient.setToken(_token);

      // Fetch user profile & assignment
      final meResponse = await apiClient.get(ApiConstants.me);
      _currentUser = UserModel.fromJson(meResponse);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
    int? assignedRouteId,
    int? assignedVehicleId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await apiClient.post(
        ApiConstants.register,
        body: {
          'email': email.trim(),
          'username': username.trim(),
          'password': password.trim(),
          'full_name': (fullName != null && fullName.trim().isNotEmpty)
              ? fullName.trim()
              : username.trim(),
          'assigned_route_id': assignedRouteId ?? 1,
          'assigned_vehicle_id': assignedVehicleId ?? 1,
        },
      );

      // Automatically log in with the new credentials
      return await login(username.trim(), password.trim());
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> reloadUser() async {
    try {
      final meResponse = await apiClient.get(ApiConstants.me);
      _currentUser = UserModel.fromJson(meResponse);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reload user profile: $e');
    }
  }

  void logout() {
    _currentUser = null;
    _token = null;
    _errorMessage = null;
    apiClient.setToken(null);
    notifyListeners();
  }
}
