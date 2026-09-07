import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gps_tracker_mobile/core/network/api_client.dart';
import 'package:gps_tracker_mobile/providers/auth_provider.dart';
import 'package:gps_tracker_mobile/providers/tracking_provider.dart';
import 'package:gps_tracker_mobile/models/route_model.dart';
import 'package:gps_tracker_mobile/models/vehicle_model.dart';
import 'package:gps_tracker_mobile/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders title and demo login chips', (WidgetTester tester) async {
    final apiClient = ApiClient();
    final authProvider = AuthProvider(apiClient: apiClient);
    final trackingProvider = TrackingProvider(apiClient: apiClient);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: trackingProvider),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    // Verify Title
    expect(find.text('TransitTrack Live'), findsOneWidget);
    // Verify Demo Quick Login Chips
    expect(find.text('User A (Route A / BUS-001)'), findsOneWidget);
    expect(find.text('User B (Route B / BUS-002)'), findsOneWidget);
    // Verify Sign In button
    expect(find.text('Sign In to Fleet Tracker'), findsOneWidget);
  });

  group('Corridor Switching & Route Parsing', () {
    test('RouteModel parses Route E (Hosur - Chennai) correctly', () {
      final json = {
        'id': 5,
        'route_code': 'ROUTE-E',
        'name': 'Hosur - Chennai Superfast Express',
        'description': 'Express transit corridor',
        'start_location': 'Hosur Central',
        'end_location': 'Chennai CMBT',
        'vehicle_id': 'BUS-005',
        'plate_number': 'TN-70-EX-5005',
        'waypoints': [
          {'name': 'Hosur Central Bus Stand', 'latitude': 12.7342, 'longitude': 77.8284, 'sequence': 1},
          {'name': 'Chennai CMBT Koyambedu Terminal', 'latitude': 13.0673, 'longitude': 80.2057, 'sequence': 2},
        ]
      };

      final route = RouteModel.fromJson(json);
      expect(route.id, 5);
      expect(route.routeCode, 'ROUTE-E');
      expect(route.vehicleId, 'BUS-005');
      expect(route.waypoints.length, 2);
      expect(route.waypoints.first.name, 'Hosur Central Bus Stand');
      expect(route.waypoints.last.name, 'Chennai CMBT Koyambedu Terminal');
    });

    test('VehicleModel parses BUS-005 with active status', () {
      final json = {
        'id': 5,
        'vehicle_id': 'BUS-005',
        'plate_number': 'TN-70-EX-5005',
        'model': 'Scania Multi-Axle Intercity AC',
        'status': 'ACTIVE',
        'route_id': 5,
      };

      final vehicle = VehicleModel.fromJson(json);
      expect(vehicle.id, 5);
      expect(vehicle.vehicleId, 'BUS-005');
      expect(vehicle.status, 'ACTIVE');
      expect(vehicle.routeId, 5);
    });
  });
}
