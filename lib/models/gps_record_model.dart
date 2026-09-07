class GPSRecordModel {
  final int id;
  final String vehicleId;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final DateTime timestamp;
  final DateTime? receivedAt;

  GPSRecordModel({
    required this.id,
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
    this.receivedAt,
  });

  factory GPSRecordModel.fromJson(Map<String, dynamic> json) {
    return GPSRecordModel(
      id: json['id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      heading: (json['heading'] as num).toDouble(),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      receivedAt: json['received_at'] != null ? DateTime.tryParse(json['received_at']) : null,
    );
  }
}

class ETAModel {
  final String nextStopName;
  final double distanceKm;
  final int etaMinutes;
  final String transitStatus;
  final String statusDescription;
  final String? alert;

  ETAModel({
    required this.nextStopName,
    required this.distanceKm,
    required this.etaMinutes,
    required this.transitStatus,
    required this.statusDescription,
    this.alert,
  });

  factory ETAModel.fromJson(Map<String, dynamic> json) {
    return ETAModel(
      nextStopName: json['next_stop_name'] ?? 'Upcoming Stop',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      etaMinutes: json['eta_minutes'] ?? 0,
      transitStatus: json['transit_status'] ?? 'IN_TRANSIT',
      statusDescription: json['status_description'] ?? '',
      alert: json['alert'],
    );
  }
}
