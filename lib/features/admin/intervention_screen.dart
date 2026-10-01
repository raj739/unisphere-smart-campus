import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class InterventionScreen extends StatefulWidget {
  const InterventionScreen({super.key});

  @override
  State<InterventionScreen> createState() => _InterventionScreenState();
}

class _InterventionScreenState extends State<InterventionScreen> {
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _students = const [];
  String? _error;
  bool _loading = true;
  bool _working = false;
  String _status = 'Active';
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
      final data = await Future.wait<dynamic>([
        UniSphereApiService.getInterventionsV2(),
        UniSphereApiService.getAdminStudents(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = (data[0] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _students = (data[1] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load interventions.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final needle = _query.trim().toLowerCase();
    return _items.where((item) {
      final status = item['status']?.toString() ?? 'Open';
      final matchesStatus = switch (_status) {
        'Active' => !{'Completed', 'Cancelled'}.contains(status),
        'All' => true,
        _ => status == _status,
      };
      final matchesQuery = needle.isEmpty ||
          [
            item['student_name'],
            item['uni_id'],
            item['programme'],
            item['intervention_type'],
            item['assigned_to'],
            item['warning_title'],
          ].any((value) => value.toString().toLowerCase().contains(needle));
      return matchesStatus && matchesQuery;
    }).toList();
  }

  Future<void> _showCreateDialog() async {
    if (_students.isEmpty) {
      _message('Register a student before creating an intervention.');
      return;
    }
    int studentId = _students.first['id'] as int;
    var type = 'Academic support';
    var priority = 'Medium';
    final advisor = TextEditingController();
    final dueDate = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .substring(0, 10),
    );
    final reason = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.assignment_add),
              SizedBox(width: 10),
              Text('Create intervention'),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: studentId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Student',
                      prefixIcon: Icon(Icons.person_search_outlined),
                    ),
                    items: _students
                        .map(
                          (student) => DropdownMenuItem(
                            value: student['id'] as int,
                            child: Text(
                              '${student['full_name']} (${student['uni_id']})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setDialogState(
                      () => studentId = value ?? studentId,
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
                      'Academic support',
                      'Attendance recovery',
                      'Student engagement',
                      'Financial counselling',
                      'Wellbeing referral',
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
                  _field(advisor, 'Advisor or support owner', Icons.person_outline),
                  const SizedBox(height: 14),
                  _field(dueDate, 'Due date (YYYY-MM-DD)', Icons.event_outlined),
                  const SizedBox(height: 14),
                  TextField(
                    controller: reason,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Reason and initial support plan',
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
              icon: const Icon(Icons.add),
              label: const Text('Create case'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final student = _students.firstWhere((item) => item['id'] == studentId);
    await _run(
      () => UniSphereApiService.createInterventionV2(
        uniId: student['uni_id']?.toString() ?? '',
        interventionType: type,
        assignedTo: advisor.text.trim().isEmpty ? null : advisor.text.trim(),
        priority: priority,
        reason: reason.text.trim().isEmpty ? null : reason.text.trim(),
        dueDate: dueDate.text.trim().isEmpty ? null : dueDate.text.trim(),
      ),
      'Intervention created.',
    );
  }

  Future<void> _openCase(Map<String, dynamic> item) async {
    var status = item['status']?.toString() ?? 'Open';
    final advisor = TextEditingController(text: item['assigned_to']?.toString());
    final dueDate = TextEditingController(text: item['due_date']?.toString());
    final notes = TextEditingController(text: item['notes']?.toString());
    final outcome = TextEditingController(text: item['outcome']?.toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item['student_name']?.toString() ?? 'Intervention case'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['intervention_type']}  |  ${item['uni_id']}',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  if (item['warning_title'] != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Linked warning: ${item['warning_title']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: 'Case status',
                      prefixIcon: Icon(Icons.track_changes_outlined),
                    ),
                    items: const [
                      'Open',
                      'Assigned',
                      'In Progress',
                      'Completed',
                      'Cancelled',
                    ]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setDialogState(() => status = value ?? status),
                  ),
                  const SizedBox(height: 14),
                  _field(advisor, 'Advisor or support owner', Icons.person_outline),
                  const SizedBox(height: 14),
                  _field(dueDate, 'Due date (YYYY-MM-DD)', Icons.event_outlined),
                  const SizedBox(height: 14),
                  TextField(
                    controller: notes,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Case notes and actions taken',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: outcome,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: status == 'Completed'
                          ? 'Outcome (required)'
                          : 'Outcome',
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
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save case'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    if (status == 'Completed' && outcome.text.trim().isEmpty) {
      _message('Record an outcome before completing the intervention.');
      return;
    }
    await _run(
      () => UniSphereApiService.updateInterventionV2Status(
        interventionId: item['id'] as int,
        status: status,
        assignedTo: advisor.text.trim(),
        dueDate: dueDate.text.trim().isEmpty ? null : dueDate.text.trim(),
        notes: notes.text.trim(),
        outcome: outcome.text.trim(),
      ),
      status == 'Completed'
          ? 'Intervention completed and linked warning resolved.'
          : 'Intervention updated.',
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon,
  ) =>
      TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      );

  Future<void> _run(Future<dynamic> Function() action, String success) async {
    setState(() => _working = true);
    try {
      await action();
      await _load();
      _message(success);
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('The intervention operation could not be completed.');
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
                    ..._filtered.map(_caseCard),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _header() => Row(
        children: [
          const Icon(
            Icons.volunteer_activism_outlined,
            color: Color(0xFF6D28D9),
            size: 32,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Support Interventions',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Assign ownership, document support actions, and record measurable outcomes.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loading || _working ? null : _load,
            tooltip: 'Refresh interventions',
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _loading || _working ? null : _showCreateDialog,
            icon: const Icon(Icons.add),
            label: const Text('New case'),
          ),
        ],
      );

  Widget _summary() {
    int count(String status) =>
        _items.where((item) => item['status'] == status).length;
    return Row(
      children: [
        Expanded(
          child: _metric(
            'Active cases',
            _items
                .where(
                  (item) =>
                      !{'Completed', 'Cancelled'}.contains(item['status']),
                )
                .length,
            const Color(0xFF6D28D9),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metric(
            'In progress',
            count('In Progress'),
            const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metric(
            'Completed',
            count('Completed'),
            const Color(0xFF0F766E),
          ),
        ),
      ],
    );
  }

  Widget _metric(String label, int value, Color color) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
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
      );

  Widget _filters() => Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search student, advisor, or support type',
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _status,
            items: const [
              'Active',
              'All',
              'Open',
              'Assigned',
              'In Progress',
              'Completed',
              'Cancelled',
            ]
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
            onChanged: (value) => setState(() => _status = value ?? 'Active'),
          ),
        ],
      );

  Widget _caseCard(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? 'Open';
    final color = status == 'Completed'
        ? const Color(0xFF0F766E)
        : status == 'Cancelled'
        ? const Color(0xFF64748B)
        : item['priority'] == 'High'
        ? const Color(0xFFB91C1C)
        : const Color(0xFF6D28D9);
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
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.1),
                child: const Icon(Icons.person_outline),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['student_name']?.toString() ?? item['uni_id'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${item['uni_id']}  |  ${item['programme']}',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              _badge(status, color),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _working ? null : () => _openCase(item),
                tooltip: 'Open intervention case',
                icon: const Icon(Icons.edit_note_outlined),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item['intervention_type']?.toString() ?? 'Support intervention',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          if (item['warning_title'] != null) ...[
            const SizedBox(height: 5),
            Text(
              'Warning: ${item['warning_title']}',
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (item['reason'] != null) ...[
            const SizedBox(height: 8),
            Text(item['reason'].toString()),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _detail(
                Icons.person_outline,
                item['assigned_to']?.toString() ?? 'Owner not assigned',
              ),
              _detail(
                Icons.event_outlined,
                item['due_date']?.toString() ?? 'No deadline',
              ),
              _detail(
                Icons.flag_outlined,
                '${item['priority'] ?? 'Medium'} priority',
              ),
            ],
          ),
          if (item['notes']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              'Latest notes: ${item['notes']}',
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ],
          if (item['outcome']?.toString().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Outcome: ${item['outcome']}',
                style: const TextStyle(
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF64748B)),
            const SizedBox(width: 5),
            Text(text, style: const TextStyle(fontSize: 12)),
          ],
        ),
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
        child: const Center(child: Text('No interventions match this view.')),
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
