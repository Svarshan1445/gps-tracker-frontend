class WaypointModel {
  final String name;
  final double latitude;
  final double longitude;
  final int sequence;

  WaypointModel({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.sequence,
  });

  factory WaypointModel.fromJson(Map<String, dynamic> json) {
    return WaypointModel(
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      sequence: json['sequence'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'sequence': sequence,
    };
  }
}

class RouteModel {
  final int id;
  final String routeCode;
  final String name;
  final String? description;
  final String? startLocation;
  final String? endLocation;
  final String? vehicleId;
  final String? plateNumber;
  final List<WaypointModel> waypoints;

  RouteModel({
    required this.id,
    required this.routeCode,
    required this.name,
    this.description,
    this.startLocation,
    this.endLocation,
    this.vehicleId,
    this.plateNumber,
    required this.waypoints,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    var rawWaypoints = json['waypoints'] as List? ?? [];
    List<WaypointModel> waypointsList = rawWaypoints
        .map((w) => WaypointModel.fromJson(w as Map<String, dynamic>))
        .toList();

    return RouteModel(
      id: json['id'] ?? 0,
      routeCode: json['route_code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      vehicleId: json['vehicle_id'],
      plateNumber: json['plate_number'],
      waypoints: waypointsList,
    );
  }
}
