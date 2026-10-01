import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> {
  List<Map<String, dynamic>> _allocations = const [];
  List<Map<String, dynamic>> _issues = const [];
  String? _error;
  bool _loading = true;

  Map<String, dynamic>? get _currentAllocation {
    for (final item in _allocations) {
      if (item['status'] == 'active') return item;
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
        UniSphereApiService.getMyTransportAllocations(),
        UniSphereApiService.getMyTransportIssues(),
      ]);
      if (!mounted) return;
      setState(() {
        _allocations = results[0];
        _issues = results[1];
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load transport information.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _createIssue() async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => const _TransportIssueDialog(),
    );
    if (!mounted || values == null) return;
    try {
      await UniSphereApiService.createTransportIssue(
        category: values[0],
        title: values[1],
        description: values[2],
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transport issue submitted.')),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(width < 700 ? 18 : 30),
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
                _emptyPanel(
                  Icons.error_outline_rounded,
                  'Transport information unavailable',
                  _error!,
                )
              else ...[
                if (_currentAllocation == null)
                  _emptyPanel(
                    Icons.directions_bus_outlined,
                    'No transport allocation',
                    'Your assigned route and boarding stop will appear here after allocation.',
                  )
                else
                  _passCard(_currentAllocation!),
                const SizedBox(height: 28),
                _sectionHeading('Reported issues', '${_issues.length} total'),
                const SizedBox(height: 12),
                if (_issues.isEmpty)
                  _emptyPanel(
                    Icons.task_alt_rounded,
                    'No reported issues',
                    'You have not submitted any transport support requests.',
                  )
                else
                  ..._issues.map(_issueTile),
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
              'My Transport',
              style: TextStyle(
                fontSize: 28,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF172554),
              ),
            ),
            SizedBox(height: 7),
            Text(
              'Route pass, pickup schedule and vehicle information',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Refresh transport information',
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh_rounded),
      ),
      FilledButton.icon(
        onPressed: _loading ? null : _createIssue,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report issue'),
      ),
    ],
  );

  Widget _passCard(Map<String, dynamic> item) => Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Color(0xFF0F4C5C),
            borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFFBBF24),
                foregroundColor: Color(0xFF422006),
                child: Icon(Icons.directions_bus_rounded),
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
                      style: const TextStyle(color: Color(0xFFCCFBF1)),
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
                    Icons.route_rounded,
                    'Route',
                    '${_text(item['route_name'])} (${_text(item['route_code'])})',
                  ),
                  _primaryFact(
                    Icons.pin_drop_outlined,
                    'Boarding stop',
                    _text(item['stop_name']),
                  ),
                  _primaryFact(
                    Icons.schedule_rounded,
                    'Pickup time',
                    _text(item['pickup_time'], 'Not scheduled'),
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
                        'Pass number',
                        item['allocation_number'],
                        itemWidth,
                      ),
                      _detail(
                        'Academic session',
                        item['academic_session'],
                        itemWidth,
                      ),
                      _detail(
                        'Vehicle number',
                        item['vehicle_number'],
                        itemWidth,
                      ),
                      _detail('Vehicle type', item['vehicle_type'], itemWidth),
                      _detail('Driver', item['driver_name'], itemWidth),
                      _detail(
                        'Driver contact',
                        item['driver_contact'],
                        itemWidth,
                      ),
                      _detail('Landmark', item['landmark'], itemWidth),
                      _detail(
                        'Allocated on',
                        _date(item['allocated_at']),
                        itemWidth,
                      ),
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

  Widget _issueTile(Map<String, dynamic> item) => Card(
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
        child: Icon(Icons.bus_alert_outlined),
      ),
      title: Text(
        _text(item['title'], 'Transport issue'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${_text(item['issue_number'])}  |  ${_date(item['created_at'])}  |  ${_text(item['category'])}',
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
    final active = {'active', 'resolved'}.contains(status.toLowerCase());
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

  String _text(dynamic value, [String fallback = '-']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _date(dynamic value) {
    final text = _text(value);
    return text == '-' ? text : text.split('T').first;
  }
}

class _TransportIssueDialog extends StatefulWidget {
  const _TransportIssueDialog();

  @override
  State<_TransportIssueDialog> createState() => _TransportIssueDialogState();
}

class _TransportIssueDialogState extends State<_TransportIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _category = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _category.dispose();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Report transport issue'),
    content: SizedBox(
      width: 500,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title_rounded),
              ),
              validator: _required,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              validator: _required,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton.icon(
        onPressed: () {
          if (!(_formKey.currentState?.validate() ?? false)) return;
          Navigator.pop(context, [
            _category.text.trim(),
            _title.text.trim(),
            _description.text.trim(),
          ]);
        },
        icon: const Icon(Icons.send_outlined),
        label: const Text('Submit'),
      ),
    ],
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;
}
