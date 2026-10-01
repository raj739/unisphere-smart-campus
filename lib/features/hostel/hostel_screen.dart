import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';
import 'hostel_complaint_dialog.dart';

class HostelScreen extends StatefulWidget {
  const HostelScreen({super.key});

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> {
  List<Map<String, dynamic>> _allocations = const [];
  List<Map<String, dynamic>> _complaints = const [];
  String? _error;
  bool _loading = true;

  Map<String, dynamic>? get _currentAllocation {
    for (final item in _allocations) {
      if (item['status'] == 'checked_in' || item['status'] == 'allocated') {
        return item;
      }
    }
    return _allocations.isEmpty ? null : _allocations.first;
  }

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
      final results = await Future.wait([
        UniSphereApiService.getMyHostelAllocations(),
        UniSphereApiService.getMyHostelComplaints(),
      ]);
      if (!mounted) return;
      setState(() {
        _allocations = results[0];
        _complaints = results[1];
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load hostel information.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createComplaint() async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => const HostelComplaintDialog(),
    );
    if (!mounted || values == null || values.length < 3) return;
    if (values.any((value) => value.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all complaint details.')),
      );
      return;
    }
    try {
      await UniSphereApiService.createHostelComplaint(
        category: values[0],
        title: values[1],
        description: values[2],
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hostel complaint submitted.')),
        );
      }
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final padding = width < 700 ? 18.0 : 30.0;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(padding),
            children: [
              _pageHeader(width < 620),
              const SizedBox(height: 24),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                _errorState()
              else ...[
                if (_currentAllocation == null)
                  _emptyAllocation()
                else
                  _allocationCard(_currentAllocation!),
                const SizedBox(height: 28),
                _sectionHeading(
                  'Requests & complaints',
                  '${_complaints.length} total',
                ),
                const SizedBox(height: 12),
                if (_complaints.isEmpty)
                  _emptyComplaints()
                else
                  ..._complaints.map(_complaintTile),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageHeader(bool compact) => Wrap(
    spacing: 12,
    runSpacing: 14,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: compact ? double.infinity : 520,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Hostel',
              style: TextStyle(
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172554),
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Room allocation, residence status and service requests',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh hostel information',
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
      FilledButton.icon(
        onPressed: _loading ? null : _createComplaint,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New request'),
      ),
    ],
  );

  Widget _allocationCard(Map<String, dynamic> item) {
    final occupied = (item['room_occupied_count'] as num?)?.toInt() ?? 0;
    final capacity = (item['room_capacity'] as num?)?.toInt() ?? 0;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xFF172554),
              borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFF2DD4BF),
                  foregroundColor: Color(0xFF0F172A),
                  child: Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text(item['student_name'], 'Student'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_text(item['student_uni_id'])}  |  ${_text(item['student_programme'])}',
                        style: const TextStyle(color: Color(0xFFCBD5E1)),
                      ),
                    ],
                  ),
                ),
                _statusPill(item['status']),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _primaryFact(
                      Icons.apartment_rounded,
                      'Building',
                      '${_text(item['building_name'])} (${_text(item['building_code'])})',
                    ),
                    _primaryFact(
                      Icons.meeting_room_outlined,
                      'Room',
                      _text(item['room_number']),
                    ),
                    _primaryFact(
                      Icons.bed_outlined,
                      'Occupancy',
                      '$occupied of $capacity beds',
                    ),
                  ],
                ),
                const Divider(height: 34),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 900
                        ? 4
                        : constraints.maxWidth > 520
                        ? 2
                        : 1;
                    final itemWidth =
                        (constraints.maxWidth - (columns - 1) * 18) / columns;
                    return Wrap(
                      spacing: 18,
                      runSpacing: 18,
                      children: [
                        _detail(
                          'Allocation number',
                          item['allocation_number'],
                          itemWidth,
                        ),
                        _detail('Hostel type', item['hostel_type'], itemWidth),
                        _detail('Floor', item['floor_number'], itemWidth),
                        _detail('Room type', item['room_type'], itemWidth),
                        _detail('Room status', item['room_status'], itemWidth),
                        _detail(
                          'Allocated on',
                          _date(item['allocated_at']),
                          itemWidth,
                        ),
                        _detail(
                          'Check-in',
                          _date(item['check_in_at']),
                          itemWidth,
                        ),
                        _detail('Remarks', item['remarks'], itemWidth),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryFact(IconData icon, String label, String value) => Container(
    width: 250,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF0F766E)),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _detail(String label, dynamic value, double width) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(_text(value), style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _complaintTile(Map<String, dynamic> item) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      leading: const CircleAvatar(
        backgroundColor: Color(0xFFFFF7ED),
        foregroundColor: Color(0xFFC2410C),
        child: Icon(Icons.home_repair_service_outlined),
      ),
      title: Text(
        _text(item['title'], 'Hostel request'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${_text(item['complaint_number'])}  |  ${_date(item['created_at'])}  |  ${_text(item['category'])}',
        ),
      ),
      trailing: _statusPill(item['status']),
    ),
  );

  Widget _sectionHeading(String title, String count) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172554),
          ),
        ),
      ),
      Text(count, style: const TextStyle(color: Color(0xFF64748B))),
    ],
  );

  Widget _emptyAllocation() => _emptyPanel(
    Icons.hotel_outlined,
    'No hostel allocation',
    'Your active room assignment will appear here after the hostel office allocates it.',
  );

  Widget _emptyComplaints() => _emptyPanel(
    Icons.task_alt_rounded,
    'No open requests',
    'You have not submitted any hostel complaints or service requests.',
  );

  Widget _emptyPanel(IconData icon, String title, String message) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Row(
      children: [
        Icon(icon, size: 34, color: const Color(0xFF0F766E)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _statusPill(dynamic value) {
    final status = _text(value).replaceAll('_', ' ');
    final active = {
      'allocated',
      'checked in',
      'available',
      'resolved',
    }.contains(status.toLowerCase());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: active ? const Color(0xFF166534) : const Color(0xFF9A3412),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _errorState() => _emptyPanel(
    Icons.error_outline_rounded,
    'Hostel information unavailable',
    _error!,
  );

  String _text(dynamic value, [String fallback = '-']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _date(dynamic value) {
    final text = _text(value);
    if (text == '-') return text;
    return text.split('T').first;
  }
}
