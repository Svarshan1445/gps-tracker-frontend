import 'package:flutter/foundation.dart';

class ApiConstants {
  // Default base URL depending on platform
  static String _baseUrl = kIsWeb
      ? 'http://localhost:8000/api/v1'
      : (defaultTargetPlatform == TargetPlatform.android
          ? 'http://10.0.2.2:8000/api/v1'
          : 'http://localhost:8000/api/v1');

  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String newUrl) {
    if (newUrl.endsWith('/')) {
      _baseUrl = newUrl.substring(0, newUrl.length - 1);
    } else {
      _baseUrl = newUrl;
    }
  }

  // Endpoints
  static String get login => '$_baseUrl/auth/login';
  static String get register => '$_baseUrl/auth/register';
  static String get me => '$_baseUrl/auth/me';
  static String get assignedRoute => '$_baseUrl/tracking/route';
  static String get assignedVehicle => '$_baseUrl/tracking/vehicle';
  static String get liveTracking => '$_baseUrl/tracking/live';
  static String get trackingHistory => '$_baseUrl/tracking/history';
  static String get gpsIngest => '$_baseUrl/gps/ingest';
  static String get allRoutes => '$_baseUrl/tracking/routes';
  static String get createRoute => '$_baseUrl/tracking/routes';
  static String switchCorridor(int routeId) => '$_baseUrl/tracking/switch-corridor/$routeId';
}
