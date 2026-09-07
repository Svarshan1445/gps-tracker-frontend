import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route_model.dart';
import '../providers/tracking_provider.dart';
import '../providers/auth_provider.dart';
import 'add_route_dialog.dart';

class RouteExplorerSheet extends StatefulWidget {
  const RouteExplorerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const RouteExplorerSheet(),
    );
  }

  @override
  State<RouteExplorerSheet> createState() => _RouteExplorerSheetState();
}

class _RouteExplorerSheetState extends State<RouteExplorerSheet> {
  int? _expandedRouteId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCodeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tracking = Provider.of<TrackingProvider>(context, listen: false);
      if (tracking.allRoutes.isEmpty) {
        tracking.fetchAllRoutes();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _switchAndTrackRoute(RouteModel route) async {
    final tracking = Provider.of<TrackingProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    Navigator.pop(context); // Close sheet to view the map!

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Switching active map view to ${route.name} (${route.routeCode})...')),
          ],
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    final success = await tracking.switchToRoute(route.id);
    if (success) {
      await auth.reloadUser();
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Now Tracking ${route.routeCode}: ${route.name} (${route.vehicleId ?? 'Bus'})',
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
  }

  void _openAddRouteDialog(int nextNum) {
    showDialog(
      context: context,
      builder: (ctx) => AddRouteDialog(
        nextRouteNumber: nextNum,
        onRouteCreated: (createdRoute) {
          setState(() {
            _searchController.text = createdRoute.name;
            _searchQuery = createdRoute.name.toLowerCase();
            _expandedRouteId = createdRoute.id;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Route ${createdRoute.routeCode} created and active in live tracking!'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
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
        return const Color(0xFF1D4ED8); // Royal Blue for Hosur-Chennai
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
    final tracking = Provider.of<TrackingProvider>(context);
    final routes = tracking.allRoutes;
    final assignedRouteId = tracking.assignedRoute?.id;

    // Filter routes by search query & category chip
    final filteredRoutes = routes.where((route) {
      if (_selectedCodeFilter != null && route.routeCode != _selectedCodeFilter) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();

      // 1. Direct whole-string match
      final matchName = route.name.toLowerCase().contains(q);
      final matchCode = route.routeCode.toLowerCase().contains(q);
      final matchStart = (route.startLocation ?? '').toLowerCase().contains(q);
      final matchEnd = (route.endLocation ?? '').toLowerCase().contains(q);
      final matchDesc = (route.description ?? '').toLowerCase().contains(q);
      final matchStops = route.waypoints.any((wp) => wp.name.toLowerCase().contains(q));

      if (matchName || matchCode || matchStart || matchEnd || matchDesc || matchStops) {
        return true;
      }

      // 2. Smart Multi-keyword Origin-Destination Search (e.g. "Hosur to Chennai" or "Hosur Chennai")
      final cleanedQuery = q.replaceAll(RegExp(r'\b(to|from|via|bus|route|-)\b'), ' ');
      final keywords = cleanedQuery.split(RegExp(r'\s+')).where((k) => k.length >= 2).toList();
      if (keywords.length >= 2) {
        final fullRouteContent = [
          route.name,
          route.routeCode,
          route.startLocation ?? '',
          route.endLocation ?? '',
          route.description ?? '',
          ...route.waypoints.map((w) => w.name),
        ].join(' ').toLowerCase();

        final allKeywordsMatch = keywords.every((k) => fullRouteContent.contains(k));
        if (allKeywordsMatch) return true;
      }

      return false;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.50,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag Handle
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Title Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4338CA).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.alt_route, color: Color(0xFF4338CA), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transit Route Search & Explorer',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Search official bus routes, stops & transit corridors',
                            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2F6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            '${filteredRoutes.length}/${routes.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4338CA),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4338CA),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            visualDensity: VisualDensity.compact,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('+ Add Route', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          onPressed: () => _openAddRouteDialog(routes.length + 1),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Live Search Input Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search route, stop (e.g. Hosur to Chennai, Airport, IT)...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4338CA), size: 22),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Quick Filter Chips (All, Route A, Route B, Route C, Route D)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      selected: _selectedCodeFilter == null,
                      label: Text('All Routes (${routes.length})'),
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _selectedCodeFilter == null ? Colors.white : const Color(0xFF334155),
                      ),
                      selectedColor: const Color(0xFF4338CA),
                      backgroundColor: const Color(0xFFF1F5F9),
                      checkmarkColor: Colors.white,
                      onSelected: (_) => setState(() => _selectedCodeFilter = null),
                    ),
                    const SizedBox(width: 8),
                    ...routes.map((r) {
                      final isSelected = _selectedCodeFilter == r.routeCode;
                      final color = _getRouteColor(r.routeCode);
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          avatar: Icon(Icons.directions_bus_rounded, size: 14, color: isSelected ? Colors.white : color),
                          label: Text(r.routeCode),
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : color,
                          ),
                          selectedColor: color,
                          backgroundColor: color.withOpacity(0.1),
                          checkmarkColor: Colors.white,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCodeFilter = selected ? r.routeCode : null;
                            });
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Route List or Empty State
              Expanded(
                child: routes.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filteredRoutes.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(28),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade400),
                                  const SizedBox(height: 14),
                                  Text(
                                    'No routes found matching "$_searchQuery"',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Try searching for "Hosur to Chennai", "Airport", "Krishnagiri", "Vellore", "Kanchipuram", or "Majestic".',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchQuery = '';
                                            _selectedCodeFilter = null;
                                          });
                                        },
                                        icon: const Icon(Icons.refresh_rounded, size: 16),
                                        label: const Text('Reset Filters'),
                                        style: OutlinedButton.styleFrom(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _openAddRouteDialog(routes.length + 1),
                                        icon: const Icon(Icons.add_rounded, size: 16),
                                        label: const Text('+ Create This Route'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF4338CA),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredRoutes.length,
                            itemBuilder: (context, index) {
                              final route = filteredRoutes[index];
                              final isAssigned = route.id == assignedRouteId;
                              final isExpanded = _expandedRouteId == route.id;
                              final color = _getRouteColor(route.routeCode);

                              // Check if any stop matched the search query
                              final matchedStops = _searchQuery.isNotEmpty
                                  ? route.waypoints
                                      .where((wp) => wp.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                                      .toList()
                                  : <WaypointModel>[];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 14),
                                elevation: isAssigned ? 3 : 1,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isAssigned ? color : const Color(0xFFE2E8F0),
                                    width: isAssigned ? 2 : 1,
                                  ),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    if (!isAssigned) {
                                      _switchAndTrackRoute(route);
                                    } else {
                                      setState(() {
                                        _expandedRouteId = isExpanded ? null : route.id;
                                      });
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Top Row: Code Badge + Name + Assigned Chip
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                route.routeCode,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                route.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                             if (isAssigned)
                                               Container(
                                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                 decoration: BoxDecoration(
                                                   color: const Color(0xFFECFDF5),
                                                   borderRadius: BorderRadius.circular(8),
                                                   border: Border.all(color: const Color(0xFF10B981)),
                                                 ),
                                                 child: const Row(
                                                   mainAxisSize: MainAxisSize.min,
                                                   children: [
                                                     Icon(Icons.check_circle, size: 12, color: Color(0xFF059669)),
                                                     SizedBox(width: 4),
                                                     Text(
                                                       'Active',
                                                       style: TextStyle(
                                                         fontSize: 10.5,
                                                         fontWeight: FontWeight.bold,
                                                         color: Color(0xFF059669),
                                                       ),
                                                     ),
                                                   ],
                                                 ),
                                               )
                                              else
                                                ElevatedButton.icon(
                                                  onPressed: () => _switchAndTrackRoute(route),
                                                  icon: const Icon(Icons.navigation_rounded, size: 13, color: Colors.white),
                                                  label: const Text(
                                                    'Track on Map',
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: color,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                                    visualDensity: VisualDensity.compact,
                                                    elevation: 1.5,
                                                  ),
                                                ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _expandedRouteId = isExpanded ? null : route.id;
                                                  });
                                                },
                                                borderRadius: BorderRadius.circular(20),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(4),
                                                  child: Icon(
                                                    isExpanded ? Icons.expand_less : Icons.expand_more,
                                                    color: Colors.grey.shade600,
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),

                                        if (route.description != null && route.description!.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            route.description!,
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],

                                        // Highlight matched stops when searching
                                        if (matchedStops.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF3C7),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFFCD34D)),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.place, size: 14, color: Color(0xFFB45309)),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Matching Stop: ${matchedStops.map((s) => "${s.name} (#${s.sequence})").join(", ")}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF92400E),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],

                                        const SizedBox(height: 12),

                                        // Terminals Row
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.trip_origin, size: 16, color: Color(0xFF059669)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  route.startLocation ?? 'Terminal A',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.location_on, size: 16, color: Color(0xFFDC2626)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  route.endLocation ?? 'Terminal B',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 10),

                                        // Expand / Collapse Header
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${route.waypoints.length} Stops along this corridor',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: color,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Icon(
                                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                              color: Colors.grey.shade600,
                                            ),
                                          ],
                                        ),

                                        // Expanded List of Stops
                                        if (isExpanded) ...[
                                          const SizedBox(height: 10),
                                          const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                          const SizedBox(height: 8),
                                          ...route.waypoints.map((wp) {
                                            final isQueryMatch = _searchQuery.isNotEmpty &&
                                                wp.name.toLowerCase().contains(_searchQuery.toLowerCase());
                                            return _buildStopItem(wp, color, isQueryMatch);
                                          }),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            height: 44,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _switchAndTrackRoute(route),
                                              icon: Icon(
                                                isAssigned ? Icons.check_circle_rounded : Icons.navigation_rounded,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                              label: Text(
                                                isAssigned
                                                    ? 'Currently Active (Close Sheet to View)'
                                                    : 'Switch to ${route.routeCode} & Track Live on Map',
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: isAssigned ? const Color(0xFF059669) : color,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                elevation: 2,
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildStopItem(WaypointModel wp, Color color, bool isHighlight) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFFEF3C7) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: isHighlight ? const Color(0xFFB45309) : color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${wp.sequence}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? Colors.white : color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              wp.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? const Color(0xFF92400E) : Colors.black87,
              ),
            ),
          ),
          Text(
            '${wp.latitude.toStringAsFixed(4)}, ${wp.longitude.toStringAsFixed(4)}',
            style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
