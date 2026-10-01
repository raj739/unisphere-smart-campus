import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';
import 'admin_operation_dialogs.dart';

class AdminHostelScreen extends StatefulWidget {
  const AdminHostelScreen({super.key});

  @override
  State<AdminHostelScreen> createState() => _AdminHostelScreenState();
}

class _AdminHostelScreenState extends State<AdminHostelScreen> {
  Map<String, dynamic> _data = const {};
  bool _loading = true;
  String? _error;
  int _tab = 0;

  Map<String, dynamic> get _metrics => _map(_data['metrics']);
  List<Map<String, dynamic>> get _buildings => _list(_data['buildings']);
  List<Map<String, dynamic>> get _rooms => _list(_data['rooms']);
  List<Map<String, dynamic>> get _allocations => _list(_data['allocations']);
  List<Map<String, dynamic>> get _complaints => _list(_data['complaints']);

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
      final data = await UniSphereApiService.getAdminHostelOverview();
      if (mounted) {
        setState(() => _data = data);
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load hostel administration.');
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
      title: 'Add hostel record',
      subtitle: 'Buildings contain rooms, and students are allocated to available rooms.',
      options: const [
        ('building', 'Building', Icons.apartment_rounded),
        ('room', 'Room', Icons.meeting_room_rounded),
        ('allocation', 'Allocation', Icons.bed_rounded),
      ],
    );
    if (!mounted || choice == null) return;
    if (choice == 'building') await _createBuilding();
    if (choice == 'room') await _createRoom();
    if (choice == 'allocation') await _createAllocation();
  }

  Future<void> _createBuilding() async {
    final values = await showAdminForm(
      context,
      title: 'Register hostel building',
      labels: const [
        'Building name',
        'Code',
        'Hostel type',
        'Gender (optional)',
        'Address (optional)',
        'Floors (optional)',
      ],
      maximumCapacity: 20,
    );
    if (values == null) return;
    await _run(
      () => UniSphereApiService.createHostelBuilding(
        name: values[0],
        code: values[1],
        hostelType: values[2].isEmpty ? 'general' : values[2],
        gender: values[3].isEmpty ? null : values[3],
        address: values[4].isEmpty ? null : values[4],
        totalFloors: values[5].isEmpty ? null : int.parse(values[5]),
      ),
    );
  }

  Future<void> _createRoom() async {
    final building = await pickAdminRecord(
      context,
      title: 'Select building',
      items: _buildings,
      label: (item) => _text(item['name']),
      subtitle: (item) =>
          '${_text(item['code'])} | ${_text(item['hostel_type'])}',
    );
    if (!mounted || building == null) return;
    final values = await showAdminForm(
      context,
      title: 'Add room to ${_text(building['name'])}',
      labels: const [
        'Room number',
        'Floor (optional)',
        'Room type',
        'Capacity',
      ],
      maximumCapacity: 20,
    );
    if (values == null) return;
    await _run(
      () => UniSphereApiService.createHostelRoom(
        buildingId: building['id'] as int,
        roomNumber: values[0],
        floorNumber: values[1].isEmpty ? null : int.parse(values[1]),
        roomType: values[2].isEmpty ? 'shared' : values[2],
        capacity: int.parse(values[3]),
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
    final rooms = _rooms
        .where(
          (room) =>
              (room['occupied_count'] as num? ?? 0) <
              (room['capacity'] as num? ?? 0),
        )
        .toList();
    final room = await pickAdminRecord(
      context,
      title: 'Select available room',
      items: rooms,
      label: (item) =>
          '${_text(item['building_name'])} | Room ${_text(item['room_number'])}',
      subtitle: (item) =>
          '${_text(item['room_type'])} | ${item['occupied_count']}/${item['capacity']} occupied',
    );
    if (!mounted || room == null) return;
    final values = await showAdminForm(
      context,
      title: 'Allocate ${_text(student['full_name'])}',
      labels: const ['Remarks (optional)'],
    );
    if (values == null) return;
    await _run(
      () => UniSphereApiService.createHostelAllocation(
        studentId: student['id'] as int,
        roomId: room['id'] as int,
        remarks: values[0].isEmpty ? null : values[0],
      ),
    );
  }

  Future<void> _resolveComplaint(Map<String, dynamic> complaint) async {
    final values = await showAdminForm(
      context,
      title: 'Resolve ${_text(complaint['complaint_number'])}',
      labels: const ['Resolution'],
    );
    if (values == null) return;
    await _run(
      () => UniSphereApiService.resolveHostelComplaint(
        complaintId: complaint['id'] as int,
        resolution: values[0],
      ),
    );
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    try {
      await action();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Hostel record saved.')));
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
                'Hostel data unavailable',
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
              'Hostel Operations',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172554),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Live building, room, resident and complaint management',
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
        'Buildings',
        _metrics['building_count'],
        Icons.apartment_outlined,
        const Color(0xFF1D4ED8),
      ),
      _metric(
        'Rooms',
        _metrics['room_count'],
        Icons.meeting_room_outlined,
        const Color(0xFF7C3AED),
      ),
      _metric(
        'Occupied beds',
        _metrics['occupied_beds'],
        Icons.bed_rounded,
        const Color(0xFFC2410C),
      ),
      _metric(
        'Available beds',
        _metrics['available_beds'],
        Icons.event_available_outlined,
        const Color(0xFF047857),
      ),
      _metric(
        'Open complaints',
        _metrics['open_complaints'],
        Icons.support_agent_outlined,
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
          icon: Icon(Icons.apartment_outlined),
          label: Text('Buildings'),
        ),
        ButtonSegment(
          value: 2,
          icon: Icon(Icons.meeting_room_outlined),
          label: Text('Rooms'),
        ),
        ButtonSegment(
          value: 3,
          icon: Icon(Icons.people_outline),
          label: Text('Residents'),
        ),
        ButtonSegment(
          value: 4,
          icon: Icon(Icons.support_agent_outlined),
          label: Text('Complaints'),
        ),
      ],
      selected: {_tab},
      onSelectionChanged: (value) => setState(() => _tab = value.first),
    ),
  );

  Widget _tabContent() => switch (_tab) {
    0 => _overview(),
    1 => _buildingList(),
    2 => _roomList(),
    3 => _allocationList(),
    _ => _complaintList(),
  };

  Widget _overview() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionTitle(
        'Building occupancy',
        '${_metrics['occupied_beds'] ?? 0}/${_metrics['bed_capacity'] ?? 0} beds in use',
      ),
      const SizedBox(height: 12),
      _buildingList(),
      if (_allocations.isNotEmpty) ...[
        const SizedBox(height: 24),
        _sectionTitle('Recent allocations', '${_allocations.length} records'),
        const SizedBox(height: 12),
        ..._allocations.take(4).map(_allocationTile),
      ],
    ],
  );

  Widget _buildingList() => _buildings.isEmpty
      ? _empty(
          Icons.apartment_outlined,
          'No hostel buildings',
          'Use Add to register the first building.',
        )
      : LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 720
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _buildings
                  .map((item) => _buildingCard(item, width))
                  .toList(),
            );
          },
        );

  Widget _buildingCard(Map<String, dynamic> item, double width) {
    final occupied = (item['occupied'] as num?)?.toDouble() ?? 0;
    final capacity = (item['capacity'] as num?)?.toDouble() ?? 0;
    final ratio = capacity == 0 ? 0.0 : (occupied / capacity).clamp(0.0, 1.0);
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
                backgroundColor: Color(0xFFE0F2FE),
                foregroundColor: Color(0xFF0369A1),
                child: Icon(Icons.apartment_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(item['name']),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${_text(item['code'])} | ${_text(item['hostel_type'])}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Text(
                '${item['available'] ?? 0} free',
                style: const TextStyle(
                  color: Color(0xFF047857),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            color: ratio >= 1
                ? const Color(0xFFDC2626)
                : const Color(0xFF0F766E),
            backgroundColor: const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 9),
          Text(
            '${item['occupied'] ?? 0} occupied of ${item['capacity'] ?? 0} beds | ${item['room_count'] ?? 0} rooms',
            style: const TextStyle(color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  Widget _roomList() {
    if (_rooms.isEmpty) {
      return _empty(
        Icons.meeting_room_outlined,
        'No rooms',
        'Use Add to create rooms inside a building.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildings.expand((building) {
        final rooms = _rooms
            .where((room) => room['building_id'] == building['id'])
            .toList();
        if (rooms.isEmpty) {
          return <Widget>[];
        }
        return <Widget>[
          _sectionTitle(_text(building['name']), '${rooms.length} rooms'),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1000
                  ? 4
                  : constraints.maxWidth > 650
                  ? 3
                  : constraints.maxWidth > 420
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: rooms.map((room) => _roomCard(room, width)).toList(),
              );
            },
          ),
          const SizedBox(height: 22),
        ];
      }).toList(),
    );
  }

  Widget _roomCard(Map<String, dynamic> room, double width) {
    final status = _text(room['status']);
    final color = status == 'full'
        ? const Color(0xFFDC2626)
        : status == 'partially_occupied'
        ? const Color(0xFFD97706)
        : const Color(0xFF047857);
    final occupants = _list(room['occupants']);
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: color, width: 4),
          top: const BorderSide(color: Color(0xFFE2E8F0)),
          right: const BorderSide(color: Color(0xFFE2E8F0)),
          bottom: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Room ${_text(room['room_number'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              _badge(status, color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Floor ${_text(room['floor_number'])} | ${_text(room['room_type'])}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 8),
          Text(
            '${room['occupied_count'] ?? 0}/${room['capacity'] ?? 0} beds occupied',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (occupants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              occupants.map((item) => _text(item['student_name'])).join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _allocationList() => _allocations.isEmpty
      ? _empty(
          Icons.people_outline,
          'No residents allocated',
          'Student room allocations will appear here.',
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
        '${_text(item['student_uni_id'])} | ${_text(item['building_name'])}, Room ${_text(item['room_number'])} | ${_date(item['allocated_at'])}',
      ),
      trailing: _badge(
        _text(item['status']).replaceAll('_', ' '),
        const Color(0xFF047857),
      ),
    ),
  );

  Widget _complaintList() => _complaints.isEmpty
      ? _empty(
          Icons.task_alt_rounded,
          'No complaints',
          'Student hostel complaints will appear here.',
        )
      : Column(
          children: _complaints
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
                      child: Icon(Icons.support_agent_outlined),
                    ),
                    title: Text(
                      _text(item['title']),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      '${_text(item['student_name'])} (${_text(item['student_uni_id'])}) | ${_text(item['building_name'])}, Room ${_text(item['room_number'])}\n${_text(item['complaint_number'])} | ${_text(item['priority'])} priority',
                    ),
                    isThreeLine: true,
                    trailing: item['status'] == 'resolved'
                        ? _badge('resolved', const Color(0xFF047857))
                        : FilledButton.tonal(
                            onPressed: () => _resolveComplaint(item),
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
  String _date(dynamic value) =>
      _text(value) == '-' ? '-' : _text(value).split('T').first;
}
