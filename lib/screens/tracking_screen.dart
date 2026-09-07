import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/tracking_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/map_view_widget.dart';
import '../widgets/vehicle_card_widget.dart';
import '../widgets/route_explorer_sheet.dart';
import '../widgets/add_route_dialog.dart';
import 'history_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tracking = Provider.of<TrackingProvider>(context, listen: false);
      tracking.fetchAssignedData().then((_) {
        tracking.startLivePolling(interval: const Duration(seconds: 3));
      });
      // Eagerly preload all transit routes for instant search
      tracking.fetchAllRoutes();
    });
  }

  Color _getRouteColor(String code) {
    switch (code) {
      case 'ROUTE-A':
        return Colors.indigo.shade700;
      case 'ROUTE-B':
        return Colors.teal.shade700;
      case 'ROUTE-C':
        return Colors.deepOrange.shade700;
      case 'ROUTE-D':
        return Colors.purple.shade700;
      case 'ROUTE-E':
        return const Color(0xFF1D4ED8); // Royal Blue
      default:
        final vibrantColors = [
          Colors.amber.shade800,
          Colors.green.shade700,
          Colors.pink.shade700,
          Colors.cyan.shade800,
          Colors.deepPurple.shade700,
        ];
        return vibrantColors[code.hashCode.abs() % vibrantColors.length];
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final tracking = Provider.of<TrackingProvider>(context);
    final user = auth.currentUser;

    final activeRouteCode = tracking.assignedRoute?.routeCode ?? user?.assignedRouteCode ?? 'Route';
    final activeVehicleCode = tracking.assignedVehicle?.vehicleId ?? user?.assignedVehicleCode ?? 'Bus';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  user?.fullName ?? user?.username ?? 'Transit User',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(width: 8),
                const PulseIndicator(isActive: true, size: 8),
                const SizedBox(width: 4),
                const Text('LIVE', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
            Text(
              'Active Corridor: $activeRouteCode • Bus: $activeVehicleCode',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.indigo),
            tooltip: 'Search Routes & Stops',
            onPressed: () => RouteExplorerSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_road_rounded, color: Colors.indigo),
            tooltip: 'Add New Route & Bus',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AddRouteDialog(
                  nextRouteNumber: tracking.allRoutes.length + 1,
                  onRouteCreated: (created) {
                    RouteExplorerSheet.show(context);
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.alt_route, color: Colors.indigo),
            tooltip: 'Explore All Routes',
            onPressed: () => RouteExplorerSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.indigo),
            tooltip: 'Refresh Telemetry',
            onPressed: () => tracking.refreshLiveLocation(),
          ),
          IconButton(
            icon: const Icon(Icons.history, color: Colors.indigo),
            tooltip: 'Historical Logs',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Sign Out',
            onPressed: () {
              tracking.reset();
              auth.logout();
            },
          ),
        ],
      ),
      body: tracking.isLoading && tracking.assignedRoute == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading assigned route & vehicle...'),
                ],
              ),
            )
          : tracking.errorMessage != null && tracking.assignedRoute == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(tracking.errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => tracking.fetchAssignedData(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // Full Screen Map with Route and Vehicle
                    Positioned.fill(
                      child: MapViewWidget(
                        route: tracking.assignedRoute,
                        vehicle: tracking.assignedVehicle,
                        latestGps: tracking.latestGps,
                        history: tracking.history,
                      ),
                    ),

                    // Interactive Top Search & Route Bar
                    Positioned(
                      top: 14,
                      left: 16,
                      right: 16,
                      child: InkWell(
                        onTap: () => RouteExplorerSheet.show(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.96),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: Color(0xFF4338CA), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Search routes (e.g. Hosur to Chennai, Airport, IT...)...',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4338CA).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.alt_route, size: 13, color: Color(0xFF4338CA)),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${tracking.allRoutes.length} Routes',
                                      style: const TextStyle(
                                        color: Color(0xFF4338CA),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Quick Route Switcher Bar (Instant 1-Tap Corridor Switching for ANY route!)
                    if (tracking.allRoutes.isNotEmpty)
                      Positioned(
                        top: 66,
                        left: 0,
                        right: 0,
                        child: SizedBox(
                          height: 40,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: tracking.allRoutes.length + 1,
                            separatorBuilder: (_, __) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              if (index == tracking.allRoutes.length) {
                                return ActionChip(
                                  avatar: const Icon(Icons.add, size: 14, color: Color(0xFF4338CA)),
                                  label: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF4338CA))),
                                  backgroundColor: Colors.white.withOpacity(0.96),
                                  side: const BorderSide(color: Color(0xFFC7D2FE), width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AddRouteDialog(
                                        nextRouteNumber: tracking.allRoutes.length + 1,
                                        onRouteCreated: (created) {
                                          tracking.fetchAllRoutes();
                                          tracking.switchToRoute(created.id);
                                        },
                                      ),
                                    );
                                  },
                                );
                              }

                              final r = tracking.allRoutes[index];
                              final isSelected = tracking.assignedRoute?.id == r.id;
                              final routeColor = _getRouteColor(r.routeCode);

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: isSelected
                                      ? null
                                      : () async {
                                          final messenger = ScaffoldMessenger.of(context);
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  const SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(child: Text('Switching map to ${r.routeCode}: ${r.name}...')),
                                                ],
                                              ),
                                              duration: const Duration(milliseconds: 1200),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          final ok = await tracking.switchToRoute(r.id);
                                          if (ok) {
                                            await auth.reloadUser();
                                            messenger.hideCurrentSnackBar();
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        'Now Tracking ${r.routeCode}: ${r.name}',
                                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor: const Color(0xFF10B981),
                                                behavior: SnackBarBehavior.floating,
                                                duration: const Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSelected ? routeColor : Colors.white.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? routeColor : const Color(0xFFCBD5E1),
                                        width: isSelected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isSelected
                                              ? routeColor.withOpacity(0.35)
                                              : Colors.black.withOpacity(0.06),
                                          blurRadius: isSelected ? 8 : 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.white.withOpacity(0.25) : routeColor.withOpacity(0.12),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.directions_bus,
                                            size: 13,
                                            color: isSelected ? Colors.white : routeColor,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          r.routeCode,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'ACTIVE',
                                              style: TextStyle(
                                                color: routeColor,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                    // Bottom Floating Vehicle Telemetry Card
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: VehicleCardWidget(
                        vehicle: tracking.assignedVehicle,
                        route: tracking.assignedRoute,
                        latestGps: tracking.latestGps,
                        eta: tracking.eta,
                        onToggleHistory: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
