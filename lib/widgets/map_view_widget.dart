import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/route_model.dart';
import '../models/vehicle_model.dart';
import '../models/gps_record_model.dart';

class MapViewWidget extends StatefulWidget {
  final RouteModel? route;
  final VehicleModel? vehicle;
  final GPSRecordModel? latestGps;
  final List<GPSRecordModel> history;

  const MapViewWidget({
    super.key,
    required this.route,
    required this.vehicle,
    required this.latestGps,
    this.history = const [],
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  final MapController _mapController = MapController();

  LatLng get _initialCenter {
    if (widget.latestGps != null) {
      return LatLng(widget.latestGps!.latitude, widget.latestGps!.longitude);
    }
    if (widget.route != null && widget.route!.waypoints.isNotEmpty) {
      final first = widget.route!.waypoints.first;
      return LatLng(first.latitude, first.longitude);
    }
    return const LatLng(12.9716, 77.5946); // Default Bangalore Center
  }

  void _centerOnVehicle() {
    if (widget.latestGps != null) {
      final zoom = (widget.route != null && widget.route!.waypoints.length > 5) ? 10.0 : 15.0;
      _mapController.move(
        LatLng(widget.latestGps!.latitude, widget.latestGps!.longitude),
        zoom,
      );
    }
  }

  void _recenterOnRouteOrBus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.latestGps != null) {
        final zoom = (widget.route != null && widget.route!.waypoints.length > 5) ? 9.5 : 13.5;
        _mapController.move(
          LatLng(widget.latestGps!.latitude, widget.latestGps!.longitude),
          zoom,
        );
      } else if (widget.route != null && widget.route!.waypoints.isNotEmpty) {
        final pts = widget.route!.waypoints;
        final midLat = (pts.first.latitude + pts.last.latitude) / 2;
        final midLon = (pts.first.longitude + pts.last.longitude) / 2;
        final zoom = pts.length > 5 ? 8.5 : 13.0;
        _mapController.move(LatLng(midLat, midLon), zoom);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.route?.id != widget.route?.id ||
        (oldWidget.latestGps == null && widget.latestGps != null)) {
      _recenterOnRouteOrBus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build route polyline points
    final List<LatLng> routePoints = widget.route?.waypoints
            .map((wp) => LatLng(wp.latitude, wp.longitude))
            .toList() ??
        [];

    // Build historical breadcrumbs
    final List<LatLng> historyPoints = widget.history
        .map((h) => LatLng(h.latitude, h.longitude))
        .toList();

    // Build markers for stops
    final List<Marker> stopMarkers = widget.route?.waypoints.map((wp) {
          return Marker(
            point: LatLng(wp.latitude, wp.longitude),
            width: 80,
            height: 60,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    wp.name.length > 12 ? '${wp.name.substring(0, 10)}...' : wp.name,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade700,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: Center(
                    child: Text(
                      '${wp.sequence}',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList() ??
        [];

    // Build vehicle marker if available
    Marker? vehicleMarker;
    if (widget.latestGps != null) {
      final headingRad = (widget.latestGps!.heading * math.pi) / 180.0;
      vehicleMarker = Marker(
        point: LatLng(widget.latestGps!.latitude, widget.latestGps!.longitude),
        width: 64,
        height: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
              ),
              child: Text(
                widget.vehicle?.vehicleId ?? 'BUS',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 2),
            Stack(
              alignment: Alignment.center,
              children: [
                // Vehicle circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6, spreadRadius: 1)],
                  ),
                  child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
                ),
                // Heading arrow pointer
                Transform.rotate(
                  angle: headingRad,
                  child: Transform.translate(
                    offset: const Offset(0, -18),
                    child: const Icon(Icons.navigation, color: Colors.amber, size: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _initialCenter,
            initialZoom: 13.5,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.gps_tracker_mobile',
            ),
            // Route polyline (Primary)
            if (routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5.0,
                    color: Colors.indigo.shade600.withOpacity(0.85),
                  ),
                ],
              ),
            // Historical breadcrumbs trail
            if (historyPoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: historyPoints,
                    strokeWidth: 3.0,
                    color: Colors.amber.shade800.withOpacity(0.7),
                    isDotted: true,
                  ),
                ],
              ),
            // Stops
            MarkerLayer(markers: stopMarkers),
            // Vehicle Pin
            if (vehicleMarker != null) MarkerLayer(markers: [vehicleMarker]),
          ],
        ),
        // Floating Control Buttons (Recenter & Fit Route)
        Positioned(
          bottom: 190,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'fit_route_fab',
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo.shade800,
                onPressed: () {
                  if (widget.route != null && widget.route!.waypoints.isNotEmpty) {
                    final pts = widget.route!.waypoints;
                    final midLat = (pts.first.latitude + pts.last.latitude) / 2;
                    final midLon = (pts.first.longitude + pts.last.longitude) / 2;
                    final zoom = pts.length > 5 ? 8.5 : 13.0;
                    _mapController.move(LatLng(midLat, midLon), zoom);
                  }
                },
                tooltip: 'Fit Corridor to Screen',
                child: const Icon(Icons.route_outlined),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'recenter_fab',
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo.shade800,
                onPressed: _centerOnVehicle,
                tooltip: 'Center on Vehicle',
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
