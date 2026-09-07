class UserModel {
  final int id;
  final String email;
  final String username;
  final String? fullName;
  final String role;
  final bool isActive;
  final int? assignedRouteId;
  final int? assignedVehicleId;
  final String? assignedRouteCode;
  final String? assignedRouteName;
  final String? assignedVehicleCode;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    required this.role,
    required this.isActive,
    this.assignedRouteId,
    this.assignedVehicleId,
    this.assignedRouteCode,
    this.assignedRouteName,
    this.assignedVehicleCode,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['user_id'] ?? 0,
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'],
      role: json['role'] ?? 'user',
      isActive: json['is_active'] ?? true,
      assignedRouteId: json['assigned_route_id'],
      assignedVehicleId: json['assigned_vehicle_id'],
      assignedRouteCode: json['assigned_route_code'],
      assignedRouteName: json['assigned_route_name'],
      assignedVehicleCode: json['assigned_vehicle_code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'role': role,
      'is_active': isActive,
      'assigned_route_id': assignedRouteId,
      'assigned_vehicle_id': assignedVehicleId,
      'assigned_route_code': assignedRouteCode,
      'assigned_route_name': assignedRouteName,
      'assigned_vehicle_code': assignedVehicleCode,
    };
  }
}
