import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/route_model.dart';
import '../models/vehicle_model.dart';
import '../models/gps_record_model.dart';
import 'common_widgets.dart';

class VehicleCardWidget extends StatelessWidget {
  final VehicleModel? vehicle;
  final RouteModel? route;
  final GPSRecordModel? latestGps;
  final ETAModel? eta;
  final VoidCallback? onToggleHistory;
  final bool isHistoryVisible;

  const VehicleCardWidget({
    super.key,
    required this.vehicle,
    required this.route,
    required this.latestGps,
    this.eta,
    this.onToggleHistory,
    this.isHistoryVisible = false,
  });

  String _formatHeading(double heading) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((heading / 45.0) + 0.5).floor() % 8;
    return '${heading.toStringAsFixed(0)}° ${directions[index]}';
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = latestGps != null
        ? DateFormat('HH:mm:ss').format(latestGps!.timestamp.toLocal())
        : '--:--:--';

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white.withOpacity(0.97),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Vehicle Code, Plate, Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        vehicle?.vehicleId ?? '---',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle?.plateNumber ?? 'No Plate Assigned',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        vehicle?.model ?? 'Commercial Transit Bus',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: vehicle?.status ?? 'UNKNOWN'),
              ],
            ),
            const Divider(height: 24),
            // Middle: Route Info
            Row(
              children: [
                Icon(Icons.alt_route, color: Colors.indigo.shade600, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route != null ? '${route!.routeCode} • ${route!.name}' : 'Loading route...',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (eta != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: eta!.transitStatus == 'OVERSPEEDING' ? Colors.red.shade50 : Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: eta!.transitStatus == 'OVERSPEEDING' ? Colors.red.shade200 : Colors.indigo.shade100,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      eta!.transitStatus == 'OVERSPEEDING' ? Icons.warning_amber_rounded : Icons.fmd_good,
                      size: 16,
                      color: eta!.transitStatus == 'OVERSPEEDING' ? Colors.red.shade700 : Colors.indigo.shade700,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Next: ${eta!.nextStopName} • ~${eta!.etaMinutes} mins (${eta!.distanceKm.toStringAsFixed(1)} km)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: eta!.transitStatus == 'OVERSPEEDING' ? Colors.red.shade900 : Colors.indigo.shade900,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            // Telemetry Grid: Speed, Heading, Coordinates, Last Updated
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Speed
                  _buildTelemetryItem(
                    icon: Icons.speed,
                    label: 'Speed',
                    value: latestGps != null ? '${latestGps!.speed.toStringAsFixed(1)} km/h' : '-- km/h',
                    color: Colors.blue.shade700,
                  ),
                  // Heading
                  _buildTelemetryItem(
                    icon: Icons.explore,
                    label: 'Heading',
                    value: latestGps != null ? _formatHeading(latestGps!.heading) : '--',
                    color: Colors.teal.shade700,
                  ),
                  // Last Updated
                  _buildTelemetryItem(
                    icon: Icons.access_time,
                    label: 'GPS Clock',
                    value: timeStr,
                    color: Colors.purple.shade700,
                  ),
                ],
              ),
            ),
            if (latestGps != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Coords: ${latestGps!.latitude.toStringAsFixed(5)}, ${latestGps!.longitude.toStringAsFixed(5)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
            ],
            if (onToggleHistory != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onToggleHistory,
                  icon: Icon(isHistoryVisible ? Icons.map : Icons.history, size: 18),
                  label: Text(isHistoryVisible ? 'Back to Live Map' : 'View GPS History Log'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}
