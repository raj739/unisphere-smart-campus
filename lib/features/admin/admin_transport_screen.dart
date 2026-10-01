import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';
import 'admin_operation_dialogs.dart';

class AdminTransportScreen extends StatefulWidget {
  const AdminTransportScreen({super.key});

  @override
  State<AdminTransportScreen> createState() => _AdminTransportScreenState();
}

class _AdminTransportScreenState extends State<AdminTransportScreen> {
  Map<String, dynamic> _data = const {};
  bool _loading = true;
  String? _error;
  int _tab = 0;

  Map<String, dynamic> get _metrics => _map(_data['metrics']);
  List<Map<String, dynamic>> get _routes => _list(_data['routes']);
  List<Map<String, dynamic>> get _vehicles => _list(_data['vehicles']);
  List<Map<String, dynamic>> get _allocations => _list(_data['allocations']);
  List<Map<String, dynamic>> get _issues => _list(_data['issues']);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await UniSphereApiService.getAdminTransportOverview();
      if (mounted) {
        setState(() => _data = data);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load transport administration.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _create() async {
    final choice = await chooseAdminOperation(
      context,
      title: 'Add transport record',
      subtitle: 'Create a route, stops and vehicle assignment before allocating students.',
      options: const [
        ('route', 'Route', Icons.route_rounded),
        ('stop', 'Route stop', Icons.pin_drop_rounded),
        ('vehicle', 'Vehicle', Icons.directions_bus_rounded),
        ('assignment', 'Route vehicle', Icons.sync_alt_rounded),
        ('allocation', 'Allocation', Icons.badge_outlined),
      ],
    );
    if (!mounted || choice == null) return;
    if (choice == 'route') await _createRoute();
    if (choice == 'stop') await _createStop();
    if (choice == 'vehicle') await _createVehicle();
    if (choice == 'assignment') await _createAssignment();
    if (choice == 'allocation') await _createAllocation();
  }

  Future<void> _createRoute() async {
    final values = await showAdminForm(
      context,
      title: 'Create transport route',
      labels: const ['Route name', 'Code', 'Description (optional)'],
    );
    if (values == null) return;
    await _run(
      () => UniSphereApiService.createTransportRoute(
        name: values[0],
        code: values[1],
        description: values[2].isEmpty ? null : values[2],
      ),
    );
  }

  Future<Map<String, dynamic>?> _pickRoute([String title = 'Select route']) =>
      pickAdminRecord(
        context,
        title: title,
        items: _routes,
        label: (item) => _text(item['name']),
        subtitle: (item) =>
            '${_text(item['code'])} | ${item['stop_count'] ?? 0} stops',
      );

  Future<void> _createStop() async {
    final route = await _pickRoute();
    if (!mounted || route == null) return;
    final values = await showAdminForm(
      context,
      title: 'Add stop to ${_text(route['name'])}',
      labels: const [
        'Stop name',
        'Sequence number',
        'Pickup time (optional)',
        'Landmark (optional)',
      ],
    );
    if (values == null) return;
    await _run(
      () => UniSphereApiService.createTransportStop(
        routeId: route['id'] as int,
        name: values[0],
        sequenceNumber: int.parse(values[1]),
        pickupTime: values[2].isEmpty ? null : values[2],
        landmark: values[3].isEmpty ? null : values[3],
      ),
    );
  }

  Future<void> _createVehicle() async {
    final values = await showAdminForm(
      context,
      title: 'Register vehicle',
      labels: const [
        'Vehicle number',
        'Vehicle type',
        'Capacity',
        'Driver name (optional)',
        'Driver contact (optional)',
      ],
    );
    if (values == null) return;
    await _run(
      () => UniSphereApiService.createTransportVehicle(
        vehicleNumber: values[0],
        vehicleType: values[1].isEmpty ? 'bus' : values[1],
        capacity: int.parse(values[2]),
        driverName: values[3].isEmpty ? null : values[3],
        driverContact: values[4].isEmpty ? null : values[4],
      ),
    );
  }

  Future<void> _createAssignment() async {
    final route = await _pickRoute('Select route to operate');
    if (!mounted || route == null) return;
    final vehicles = await UniSphereApiService.getTransportVehicles();
    if (!mounted) return;
    final vehicle = await pickAdminRecord(
      context,
      title: 'Select vehicle',
      items: vehicles,
      label: (item) => _text(item['vehicle_number']),
      subtitle: (item) =>
          '${_text(item['vehicle_type'])} | ${item['capacity'] ?? 0} seats | ${_text(item['driver_name'], 'Driver not set')}',
    );
    if (!mounted || vehicle == null) return;
    final values = await showAdminForm(
      context,
      title: 'Assign ${_text(vehicle['vehicle_number'])}',
      labels: const ['Academic session'],
    );
    if (values == null) return;
    await _run(
      () => UniSphereApiService.createTransportAssignment(
        routeId: route['id'] as int,
        vehicleId: vehicle['id'] as int,
        academicSession: values[0],
      ),
    );
  }

  Future<void> _createAllocation() async {
    final students = (await UniSphereApiService.getAdminStudents())
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    if (!mounted) return;
    final student = await pickAdminRecord(
      context,
      title: 'Select student',
      items: students,
      label: (item) => _text(item['full_name'], 'Student #${item['id']}'),
      subtitle: (item) =>
          '${_text(item['uni_id'])} | ${_text(item['programme'])}',
    );
    if (!mounted || student == null) return;
    final availableRoutes = _routes
        .where(
          (route) =>
              route['vehicle_id'] != null &&
              (route['passenger_count'] as num? ?? 0) <
                  (route['capacity'] as num? ?? 0),
        )
        .toList();
    final route = await pickAdminRecord(
      context,
      title: 'Select operating route',
      items: availableRoutes,
      label: (item) => '${_text(item['name'])} (${_text(item['code'])})',
      subtitle: (item) =>
          '${_text(item['vehicle_number'])} | ${item['available_seats'] ?? 0} seats free | ${_text(item['academic_session'])}',
    );
    if (!mounted || route == null) return;
    final stops = _list(route['stops']);
    final stop = await pickAdminRecord(
      context,
      title: 'Select boarding stop',
      items: stops,
      label: (item) => _text(item['name']),
      subtitle: (item) =>
          '${_text(item['pickup_time'], 'Time not set')} | Stop ${item['sequence_number'] ?? '-'}',
    );
    if (!mounted || stop == null) return;
    final values = await showAdminForm(
      context,
      title: 'Allocate ${_text(student['full_name'])}',
      labels: const ['Remarks (optional)'],
    );
    if (values == null) return;
    await _run(
      () => UniSphereApiService.createTransportAllocation(
        studentId: student['id'] as int,
        routeId: route['id'] as int,
        stopId: stop['id'] as int,
        academicSession: _text(route['academic_session']),
        remarks: values[0].isEmpty ? null : values[0],
      ),
    );
  }

  Future<void> _resolveIssue(Map<String, dynamic> issue) async {
    final values = await showAdminForm(
      context,
      title: 'Resolve ${_text(issue['issue_number'])}',
      labels: const ['Resolution'],
    );
    if (values == null) return;
    await _run(
      () => UniSphereApiService.resolveTransportIssue(
        issueId: issue['id'] as int,
        resolution: values[0],
      ),
    );
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    try {
      await action();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transport record saved.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Operation failed: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FA),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(28),
          children: [
            _header(),
            const SizedBox(height: 22),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _empty(
                Icons.error_outline_rounded,
                'Transport data unavailable',
                _error!,
              )
            else ...[
              _metricBand(),
              const SizedBox(height: 20),
              _tabs(),
              const SizedBox(height: 20),
              _tabContent(),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _header() => Row(
    children: [
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transport Operations',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172554),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Live routes, fleet, seat allocation and issue management',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh',
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
      const SizedBox(width: 6),
      FilledButton.icon(
        onPressed: _loading ? null : _create,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
    ],
  );

  Widget _metricBand() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      _metric(
        'Routes',
        _metrics['route_count'],
        Icons.route_outlined,
        const Color(0xFF1D4ED8),
      ),
      _metric(
        'Vehicles',
        _metrics['vehicle_count'],
        Icons.directions_bus_outlined,
        const Color(0xFF7C3AED),
      ),
      _metric(
        'Passengers',
        _metrics['allocated_students'],
        Icons.people_outline,
        const Color(0xFFC2410C),
      ),
      _metric(
        'Available seats',
        _metrics['available_seats'],
        Icons.event_seat_outlined,
        const Color(0xFF047857),
      ),
      _metric(
        'Open issues',
        _metrics['open_issues'],
        Icons.bus_alert_outlined,
        const Color(0xFFBE123C),
      ),
    ],
  );

  Widget _metric(
    String label,
    dynamic value,
    IconData icon,
    Color color,
  ) => Container(
    width: 176,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _text(value, '0'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _tabs() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          icon: Icon(Icons.dashboard_outlined),
          label: Text('Overview'),
        ),
        ButtonSegment(
          value: 1,
          icon: Icon(Icons.route_outlined),
          label: Text('Routes'),
        ),
        ButtonSegment(
          value: 2,
          icon: Icon(Icons.directions_bus_outlined),
          label: Text('Fleet'),
        ),
        ButtonSegment(
          value: 3,
          icon: Icon(Icons.people_outline),
          label: Text('Passengers'),
        ),
        ButtonSegment(
          value: 4,
          icon: Icon(Icons.bus_alert_outlined),
          label: Text('Issues'),
        ),
      ],
      selected: {_tab},
      onSelectionChanged: (value) => setState(() => _tab = value.first),
    ),
  );

  Widget _tabContent() => switch (_tab) {
    0 => _overview(),
    1 => _routeList(),
    2 => _vehicleList(),
    3 => _allocationList(),
    _ => _issueList(),
  };

  Widget _overview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(
        'Operating routes',
        '${_metrics['allocated_students'] ?? 0}/${_metrics['operating_seats'] ?? 0} seats allocated',
      ),
      const SizedBox(height: 12),
      _routeList(),
      if (_allocations.isNotEmpty) ...[
        const SizedBox(height: 24),
        _sectionTitle('Recent allocations', '${_allocations.length} records'),
        const SizedBox(height: 12),
        ..._allocations.take(4).map(_allocationTile),
      ],
    ],
  );

  Widget _routeList() => _routes.isEmpty
      ? _empty(
          Icons.route_outlined,
          'No transport routes',
          'Use Add to create the first route.',
        )
      : LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 820
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _routes
                  .map((route) => _routeCard(route, width))
                  .toList(),
            );
          },
        );

  Widget _routeCard(Map<String, dynamic> route, double width) {
    final passengers = (route['passenger_count'] as num?)?.toDouble() ?? 0;
    final capacity = (route['capacity'] as num?)?.toDouble() ?? 0;
    final ratio = capacity == 0 ? 0.0 : (passengers / capacity).clamp(0.0, 1.0);
    final stops = _list(route['stops']);
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFCCFBF1),
                foregroundColor: Color(0xFF0F766E),
                child: Icon(Icons.route_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(route['name']),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_text(route['code'])} | ${stops.length} stops',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              _badge(
                route['vehicle_number'] == null
                    ? 'vehicle needed'
                    : '${route['available_seats']} seats free',
                route['vehicle_number'] == null
                    ? const Color(0xFFD97706)
                    : const Color(0xFF047857),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.directions_bus_outlined,
                size: 18,
                color: Color(0xFF475569),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${_text(route['vehicle_number'], 'No vehicle assigned')} | ${_text(route['driver_name'], 'Driver not set')}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: ratio >= 1
                ? const Color(0xFFDC2626)
                : const Color(0xFF0F766E),
            backgroundColor: const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 8),
          Text(
            '${route['passenger_count'] ?? 0} passengers of ${route['capacity'] ?? 0} seats | ${_text(route['academic_session'], 'No session')}',
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          if (stops.isNotEmpty) ...[
            const Divider(height: 26),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stops
                  .map(
                    (stop) => Chip(
                      avatar: Text('${stop['sequence_number'] ?? '-'}'),
                      label: Text(
                        '${_text(stop['name'])} ${_text(stop['pickup_time'], '')}',
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _vehicleList() => _vehicles.isEmpty
      ? _empty(
          Icons.directions_bus_outlined,
          'No vehicles',
          'Use Add to register a bus or other vehicle.',
        )
      : LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 720
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _vehicles
                  .map((vehicle) => _vehicleCard(vehicle, width))
                  .toList(),
            );
          },
        );

  Widget _vehicleCard(Map<String, dynamic> item, double width) => Container(
    width: width,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFFFF7ED),
          foregroundColor: Color(0xFFC2410C),
          child: Icon(Icons.directions_bus_rounded),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _text(item['vehicle_number']),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_text(item['vehicle_type'])} | ${item['passenger_count'] ?? 0}/${item['capacity'] ?? 0} seats',
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 9),
              Text(
                '${_text(item['driver_name'], 'Driver not set')} | ${_text(item['driver_contact'], 'No contact')}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text(
                '${_text(item['route_name'], 'Not assigned')} | ${_text(item['academic_session'], 'No session')}',
                style: const TextStyle(color: Color(0xFF475569)),
              ),
            ],
          ),
        ),
        _badge(
          item['route_name'] == null ? 'available' : 'assigned',
          item['route_name'] == null
              ? const Color(0xFF047857)
              : const Color(0xFF1D4ED8),
        ),
      ],
    ),
  );

  Widget _allocationList() => _allocations.isEmpty
      ? _empty(
          Icons.people_outline,
          'No passengers allocated',
          'Student transport allocations will appear here.',
        )
      : Column(children: _allocations.map(_allocationTile).toList());

  Widget _allocationTile(Map<String, dynamic> item) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFDBEAFE),
        foregroundColor: Color(0xFF1D4ED8),
        child: Icon(Icons.person_outline_rounded),
      ),
      title: Text(
        _text(item['student_name']),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${_text(item['student_uni_id'])} | ${_text(item['route_name'])} | ${_text(item['stop_name'])} at ${_text(item['pickup_time'])}\n${_text(item['vehicle_number'])} | ${_text(item['academic_session'])}',
      ),
      isThreeLine: true,
      trailing: _badge(_text(item['status']), const Color(0xFF047857)),
    ),
  );

  Widget _issueList() => _issues.isEmpty
      ? _empty(
          Icons.task_alt_rounded,
          'No transport issues',
          'Student transport issues will appear here.',
        )
      : Column(
          children: _issues
              .map(
                (item) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFF7ED),
                      foregroundColor: Color(0xFFC2410C),
                      child: Icon(Icons.bus_alert_outlined),
                    ),
                    title: Text(
                      _text(item['title']),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${_text(item['student_name'])} (${_text(item['student_uni_id'])})\n${_text(item['issue_number'])} | ${_text(item['category'])} | ${_text(item['priority'])} priority',
                    ),
                    isThreeLine: true,
                    trailing: item['status'] == 'resolved'
                        ? _badge('resolved', const Color(0xFF047857))
                        : FilledButton.tonal(
                            onPressed: () => _resolveIssue(item),
                            child: const Text('Resolve'),
                          ),
                  ),
                ),
              )
              .toList(),
        );

  Widget _sectionTitle(String title, String detail) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172554),
          ),
        ),
      ),
      Text(detail, style: const TextStyle(color: Color(0xFF64748B))),
    ],
  );

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );

  Widget _empty(IconData icon, String title, String message) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 34, color: const Color(0xFF0F766E)),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    ),
  );

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];
  String _text(dynamic value, [String fallback = '-']) =>
      value == null || value.toString().trim().isEmpty
      ? fallback
      : value.toString();
}
