import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/tracking_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tracking = Provider.of<TrackingProvider>(context);
    final history = tracking.history;

    return Scaffold(
      appBar: AppBar(
        title: Text('${tracking.assignedVehicle?.vehicleId ?? 'Vehicle'} GPS Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => tracking.fetchHistory(limit: 50),
          )
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_toggle_off, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text('No historical GPS records found yet.'),
                  const SizedBox(height: 8),
                  const Text('Incoming MQTT telemetry will appear here in real-time.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final record = history[index];
                final timeStr = DateFormat('HH:mm:ss • dd MMM yyyy').format(record.timestamp.toLocal());

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.shade50,
                    child: Icon(Icons.navigation, color: Colors.indigo.shade700, size: 18),
                  ),
                  title: Text(
                    '${record.latitude.toStringAsFixed(5)}, ${record.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                  ),
                  subtitle: Text(
                    '$timeStr • Heading ${record.heading.toStringAsFixed(0)}°',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${record.speed.toStringAsFixed(1)} km/h',
                      style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
