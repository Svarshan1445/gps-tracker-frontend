class VehicleModel {
  final int id;
  final String vehicleId;
  final String plateNumber;
  final String? model;
  final String status;
  final int? routeId;

  VehicleModel({
    required this.id,
    required this.vehicleId,
    required this.plateNumber,
    this.model,
    required this.status,
    this.routeId,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? '',
      plateNumber: json['plate_number'] ?? '',
      model: json['model'],
      status: json['status'] ?? 'ACTIVE',
      routeId: json['route_id'],
    );
  }
}
