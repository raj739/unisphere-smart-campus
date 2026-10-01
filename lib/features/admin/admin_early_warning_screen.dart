import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class AdminEarlyWarningScreen extends StatefulWidget {
  const AdminEarlyWarningScreen({super.key});

  @override
  State<AdminEarlyWarningScreen> createState() =>
      _AdminEarlyWarningScreenState();
}

class _AdminEarlyWarningScreenState extends State<AdminEarlyWarningScreen> {
  bool _loading = true;
  bool _working = false;
  String? _error;
  List<Map<String, dynamic>> _warnings = const [];
  String _filter = 'All';
  String _query = '';

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
      final warnings = await UniSphereApiService.getAdminEarlyWarnings();
      if (mounted) setState(() => _warnings = warnings);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load early warnings.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final needle = _query.trim().toLowerCase();
    return _warnings.where((warning) {
      final severity = warning['severity']?.toString() ?? '';
      final matchesFilter = _filter == 'All' ||
          (_filter == 'In intervention'
              ? warning['intervention_id'] != null
              : severity == _filter);
      final matchesQuery = needle.isEmpty ||
          [
            warning['student_name'],
            warning['uni_id'],
            warning['programme'],
            warning['title'],
            warning['warning_type'],
          ].any((value) => value.toString().toLowerCase().contains(needle));
      return matchesFilter && matchesQuery;
    }).toList();
  }

  Future<void> _createIntervention(Map<String, dynamic> warning) async {
    final assignedTo = TextEditingController();
    final dueDate = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .substring(0, 10),
    );
    final reason = TextEditingController(
      text: warning['recommended_action']?.toString() ?? '',
    );
    var type = switch (warning['warning_type']?.toString()) {
      'Attendance' => 'Attendance recovery',
      'Academic' => 'Academic support',
      'Fees' => 'Financial counselling',
      'Engagement' => 'Student engagement',
      _ => 'Student success review',
    };
    var priority = warning['severity']?.toString() ?? 'Medium';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.volunteer_activism_outlined),
              SizedBox(width: 10),
              Text('Create support intervention'),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: Text(
                      '${warning['student_name']} (${warning['uni_id']})\n${warning['title']}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(
                      labelText: 'Intervention type',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: const [
                      'Attendance recovery',
                      'Academic support',
                      'Financial counselling',
                      'Student engagement',
                      'Student success review',
                    ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => type = value ?? type),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      prefixIcon: Icon(Icons.flag_outlined),
                    ),
                    items: const ['Low', 'Medium', 'High']
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => priority = value ?? priority),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: assignedTo,
                    decoration: const InputDecoration(
                      labelText: 'Advisor or support owner',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: dueDate,
                    decoration: const InputDecoration(
                      labelText: 'Due date (YYYY-MM-DD)',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: reason,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Support plan',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.assignment_add),
              label: const Text('Create intervention'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    if (assignedTo.text.trim().isEmpty) {
      _message('Assign an advisor or support owner.');
      return;
    }
    await _run(
      () => UniSphereApiService.createInterventionV2(
        uniId: warning['uni_id']?.toString() ?? '',
        interventionType: type,
        assignedTo: assignedTo.text.trim(),
        priority: priority,
        reason: reason.text.trim(),
        dueDate: dueDate.text.trim(),
        warningId: warning['id'] as int,
      ),
      'Intervention created and linked to the warning.',
    );
  }

  Future<void> _resolve(Map<String, dynamic> warning) async {
    await _run(
      () => UniSphereApiService.resolveAdminEarlyWarning(
        warning['id'] as int,
      ),
      'Warning resolved.',
    );
  }

  Future<void> _run(Future<dynamic> Function() action, String success) async {
    setState(() => _working = true);
    try {
      await action();
      await _load();
      _message(success);
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('The warning operation could not be completed.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _header(),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(44),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_error != null)
                  _errorView()
                else ...[
                  _summary(),
                  const SizedBox(height: 16),
                  _filters(),
                  const SizedBox(height: 16),
                  if (_filtered.isEmpty)
                    _emptyView()
                  else
                    ..._filtered.map(_warningCard),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _header() => Row(
        children: [
          const Icon(
            Icons.crisis_alert_outlined,
            color: Color(0xFFB45309),
            size: 32,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Early Warning Centre',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Prediction signals requiring review, ownership, and a documented support response.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loading || _working ? null : _load,
            tooltip: 'Refresh warnings',
            icon: const Icon(Icons.refresh),
          ),
        ],
      );

  Widget _summary() => Row(
        children: [
          Expanded(
            child: _metric(
              'Active warnings',
              _warnings.length,
              const Color(0xFFB45309),
              Icons.notifications_active_outlined,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metric(
              'High severity',
              _warnings.where((item) => item['severity'] == 'High').length,
              const Color(0xFFB91C1C),
              Icons.priority_high,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _metric(
              'In intervention',
              _warnings.where((item) => item['intervention_id'] != null).length,
              const Color(0xFF6D28D9),
              Icons.volunteer_activism_outlined,
            ),
          ),
        ],
      );

  Widget _metric(String label, int value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(label, style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ],
        ),
      );

  Widget _filters() => Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search student, warning, or programme',
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _filter,
            items: const ['All', 'High', 'Medium', 'In intervention']
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _filter = value ?? 'All'),
          ),
        ],
      );

  Widget _warningCard(Map<String, dynamic> warning) {
    final high = warning['severity'] == 'High';
    final linked = warning['intervention_id'] != null;
    final color = high ? const Color(0xFFB91C1C) : const Color(0xFFB45309);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warning['student_name']?.toString() ??
                          'Student #${warning['student_id']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${warning['uni_id'] ?? '-'}  |  ${warning['programme'] ?? '-'}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              _badge(warning['severity']?.toString() ?? 'Medium', color),
              if (linked) ...[
                const SizedBox(width: 8),
                _badge('In intervention', const Color(0xFF6D28D9)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            warning['title']?.toString() ?? 'Early warning',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            warning['message']?.toString() ?? '',
            style: const TextStyle(color: Color(0xFF475569)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _detail('Signal', warning['trigger_value']?.toString() ?? '-'),
              _detail('Threshold', warning['threshold_value']?.toString() ?? '-'),
              _detail('Type', warning['warning_type']?.toString() ?? '-'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 18,
                color: Color(0xFF6D28D9),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  warning['recommended_action']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              if (!linked)
                FilledButton.icon(
                  onPressed: _working
                      ? null
                      : () => _createIntervention(warning),
                  icon: const Icon(Icons.assignment_add),
                  label: const Text('Create intervention'),
                ),
              if (!linked)
                TextButton.icon(
                  onPressed: _working ? null : () => _resolve(warning),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Resolve without intervention'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
      );

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );

  Widget _emptyView() => Container(
        padding: const EdgeInsets.all(42),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.verified_outlined,
              size: 42,
              color: Color(0xFF0F766E),
            ),
            SizedBox(height: 10),
            Text('No active warnings match this view.'),
          ],
        ),
      );

  Widget _errorView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 42),
            const SizedBox(height: 10),
            Text(_error!),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
}
