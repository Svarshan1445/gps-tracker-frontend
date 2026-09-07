import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/route_model.dart';
import '../providers/tracking_provider.dart';

class CityPreset {
  final String name;
  final double lat;
  final double lon;

  const CityPreset({required this.name, required this.lat, required this.lon});
}

const List<CityPreset> kCityPresets = [
  CityPreset(name: 'Chennai CMBT', lat: 13.0694, lon: 80.2056),
  CityPreset(name: 'Madurai Mattuthavani', lat: 9.9392, lon: 78.1581),
  CityPreset(name: 'Coimbatore Gandhipuram', lat: 11.0168, lon: 76.9675),
  CityPreset(name: 'Trichy Central', lat: 10.7967, lon: 78.6865),
  CityPreset(name: 'Salem New Bus Stand', lat: 11.6643, lon: 78.1460),
  CityPreset(name: 'Tirunelveli New Bus Stand', lat: 8.7139, lon: 77.7567),
  CityPreset(name: 'Vellore New Bus Stand', lat: 12.9349, lon: 79.1469),
  CityPreset(name: 'Hosur Central', lat: 12.7356, lon: 77.8281),
  CityPreset(name: 'Bangalore Majestic', lat: 12.9784, lon: 77.5726),
  CityPreset(name: 'Kanchipuram', lat: 12.8342, lon: 79.7036),
  CityPreset(name: 'Dindigul Bypass', lat: 10.3673, lon: 77.9803),
  CityPreset(name: 'Tiruppur Old Bus Stand', lat: 11.1085, lon: 77.3411),
  CityPreset(name: 'Erode Central', lat: 11.3410, lon: 77.7172),
  CityPreset(name: 'Thanjavur Junction', lat: 10.7870, lon: 79.1378),
];

class AddRouteDialog extends StatefulWidget {
  final int nextRouteNumber;
  final Function(RouteModel createdRoute)? onRouteCreated;

  const AddRouteDialog({
    super.key,
    required this.nextRouteNumber,
    this.onRouteCreated,
  });

  @override
  State<AddRouteDialog> createState() => _AddRouteDialogState();
}

class _AddRouteDialogState extends State<AddRouteDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _vehicleIdController;
  late final TextEditingController _plateController;

  // Custom stop entry controllers
  final _customStopNameController = TextEditingController();
  final _customLatController = TextEditingController();
  final _customLonController = TextEditingController();

  final List<WaypointModel> _waypoints = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final routeChar = String.fromCharCode(64 + widget.nextRouteNumber);
    _codeController = TextEditingController(text: 'ROUTE-$routeChar');
    _nameController = TextEditingController();
    _vehicleIdController = TextEditingController(
      text: 'BUS-${widget.nextRouteNumber.toString().padLeft(3, '0')}',
    );
    _plateController = TextEditingController(
      text: 'TN-58-EX-${(4000 + widget.nextRouteNumber)}',
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _vehicleIdController.dispose();
    _plateController.dispose();
    _customStopNameController.dispose();
    _customLatController.dispose();
    _customLonController.dispose();
    super.dispose();
  }

  void _addPresetStop(CityPreset preset) {
    setState(() {
      _waypoints.add(
        WaypointModel(
          name: preset.name,
          latitude: preset.lat,
          longitude: preset.lon,
          sequence: _waypoints.length + 1,
        ),
      );
      if (_nameController.text.trim().isEmpty && _waypoints.length >= 2) {
        final start = _waypoints.first.name.split(' ').first;
        final end = _waypoints.last.name.split(' ').first;
        _nameController.text = '$start - $end Express';
      }
    });
  }

  void _addCustomStop() {
    final name = _customStopNameController.text.trim();
    final lat = double.tryParse(_customLatController.text.trim());
    final lon = double.tryParse(_customLonController.text.trim());

    if (name.isEmpty || lat == null || lon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid Stop Name, Latitude, and Longitude')),
      );
      return;
    }

    setState(() {
      _waypoints.add(
        WaypointModel(
          name: name,
          latitude: lat,
          longitude: lon,
          sequence: _waypoints.length + 1,
        ),
      );
      _customStopNameController.clear();
      _customLatController.clear();
      _customLonController.clear();
    });
  }

  void _removeStop(int index) {
    setState(() {
      _waypoints.removeAt(index);
      for (int i = 0; i < _waypoints.length; i++) {
        _waypoints[i] = WaypointModel(
          name: _waypoints[i].name,
          latitude: _waypoints[i].latitude,
          longitude: _waypoints[i].longitude,
          sequence: i + 1,
        );
      }
    });
  }

  Future<void> _submitRoute() async {
    if (!_formKey.currentState!.validate()) return;

    if (_waypoints.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 2 stops (Origin and Destination).'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final payload = {
        'route_code': _codeController.text.trim().toUpperCase(),
        'name': _nameController.text.trim(),
        'start_location': _waypoints.first.name,
        'end_location': _waypoints.last.name,
        'description': 'Direct express corridor from ${_waypoints.first.name} to ${_waypoints.last.name}',
        'vehicle_id': _vehicleIdController.text.trim().toUpperCase(),
        'plate_number': _plateController.text.trim().toUpperCase(),
        'model': 'Ashok Leyland Intercity AC Coach',
        'waypoints': _waypoints.map((w) => w.toJson()).toList(),
      };

      final trackingProvider = Provider.of<TrackingProvider>(context, listen: false);
      final created = await trackingProvider.createRoute(payload);

      if (mounted) {
        Navigator.pop(context);
        if (created != null && widget.onRouteCreated != null) {
          widget.onRouteCreated!(created);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create route: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4338CA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_road_rounded, color: Color(0xFF4338CA), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Transit Route & Bus',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'New corridor with stops & live GPS simulator',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Route Code & Route Name
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              labelText: 'Route Code *',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Route Name (e.g. Madurai - Chennai) *',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Vehicle ID & Plate Number
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _vehicleIdController,
                            decoration: InputDecoration(
                              labelText: 'Bus ID (e.g. BUS-006) *',
                              prefixIcon: const Icon(Icons.directions_bus_outlined, size: 18),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _plateController,
                            decoration: InputDecoration(
                              labelText: 'Plate (e.g. TN-58-AA-1234) *',
                              prefixIcon: const Icon(Icons.badge_outlined, size: 18),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section: Quick Pick Stops
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Text(
                          'QUICK-ADD POPULAR STOPS (Click to add in sequence):',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: kCityPresets.map((preset) {
                        return ActionChip(
                          avatar: const Icon(Icons.add_location_alt_outlined, size: 14, color: Color(0xFF4338CA)),
                          backgroundColor: const Color(0xFFEEF2FF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: BorderSide(color: Colors.indigo.shade100),
                          label: Text(
                            preset.name,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3730A3)),
                          ),
                          onPressed: () => _addPresetStop(preset),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Section: Selected Stops sequence
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ROUTE WAYPOINTS (${_waypoints.length} Stops Added)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              if (_waypoints.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => setState(() => _waypoints.clear()),
                                  icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Colors.red),
                                  label: const Text('Clear All', style: TextStyle(fontSize: 11, color: Colors.red)),
                                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_waypoints.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              alignment: Alignment.center,
                              child: Text(
                                'No stops added yet. Click city chips above or add custom stops below.\n(At least 2 stops required: Start & Destination)',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _waypoints.length,
                              separatorBuilder: (_, __) => const Divider(height: 12),
                              itemBuilder: (ctx, i) {
                                final wp = _waypoints[i];
                                final isFirst = i == 0;
                                final isLast = i == _waypoints.length - 1 && _waypoints.length > 1;

                                return Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: isFirst
                                          ? const Color(0xFF10B981)
                                          : isLast
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF4338CA),
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            wp.name,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                          ),
                                          Text(
                                            '(${wp.latitude.toStringAsFixed(4)}, ${wp.longitude.toStringAsFixed(4)})',
                                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                                      tooltip: 'Remove stop',
                                      onPressed: () => _removeStop(i),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Custom Stop Entry (Expandable)
                    ExpansionTile(
                      title: const Text('Add Custom Stop (Coordinates)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      leading: const Icon(Icons.pin_drop_outlined, size: 20, color: Color(0xFF4338CA)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _customStopNameController,
                                decoration: InputDecoration(
                                  labelText: 'Custom Stop Name (e.g. Perambalur Toll)',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _customLatController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Latitude (e.g. 11.2341)',
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _customLonController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Longitude (e.g. 78.8789)',
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4338CA),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    onPressed: _addCustomStop,
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit & Cancel Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF312E81), Color(0xFF4338CA), Color(0xFF3B82F6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4338CA).withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isSubmitting ? null : _submitRoute,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 18),
                              label: Text(
                                _isSubmitting ? 'Deploying...' : 'Create & Deploy Route',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
