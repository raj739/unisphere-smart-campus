import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _sessions = const [];
  List<Map<String, dynamic>> _offerings = const [];
  List<Map<String, dynamic>> _courses = const [];
  List<Map<String, dynamic>> _roster = const [];
  int? _selectedSessionId;
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
      final values = await Future.wait([
        UniSphereApiService.getAttendanceSessions(),
        UniSphereApiService.getCourseOfferings(),
        UniSphereApiService.getAdminCourses(),
      ]);
      final sessions = values[0];
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _offerings = values[1];
        _courses = values[2];
        if (_selectedSessionId == null ||
            !sessions.any((item) => item['id'] == _selectedSessionId)) {
          _selectedSessionId = sessions.firstOrNull?['id'] as int?;
        }
      });
      await _loadRoster();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load attendance operations.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRoster() async {
    final sessionId = _selectedSessionId;
    if (sessionId == null) {
      if (mounted) setState(() => _roster = const []);
      return;
    }
    final roster = await UniSphereApiService.getAttendanceRoster(sessionId);
    if (mounted && _selectedSessionId == sessionId) {
      setState(() => _roster = roster.map((item) => {...item}).toList());
    }
  }

  Map<String, dynamic>? get _selectedSession => _sessions
      .where((item) => item['id'] == _selectedSessionId)
      .firstOrNull;

  Map<String, dynamic>? _offeringFor(Map<String, dynamic> session) => _offerings
      .where((item) => item['id'] == session['course_offering_id'])
      .firstOrNull;

  Map<String, dynamic>? _courseFor(Map<String, dynamic> session) {
    final offering = _offeringFor(session);
    return _courses
        .where((item) => item['id'] == offering?['course_id'])
        .firstOrNull;
  }

  List<Map<String, dynamic>> get _filteredSessions {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return _sessions;
    return _sessions.where((session) {
      final course = _courseFor(session);
      return [
        course?['code'],
        course?['name'],
        session['topic'],
        session['faculty_name'],
        session['session_date'],
      ].any((value) => value.toString().toLowerCase().contains(needle));
    }).toList();
  }

  Future<void> _selectSession(int id) async {
    setState(() {
      _selectedSessionId = id;
      _roster = const [];
    });
    try {
      await _loadRoster();
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _createSession() async {
    int? offeringId = _offerings.firstOrNull?['id'] as int?;
    var selectedDate = DateTime.now();
    final topic = TextEditingController();
    final start = TextEditingController(text: '09:00');
    final end = TextEditingController(text: '10:00');
    final faculty = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.event_available_outlined),
              SizedBox(width: 10),
              Text('Create class session'),
            ],
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: offeringId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Course offering',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    items: _offerings.map((offering) {
                      final course = _courses
                          .where((item) => item['id'] == offering['course_id'])
                          .firstOrNull;
                      return DropdownMenuItem(
                        value: offering['id'] as int,
                        child: Text(
                          '${course?['code'] ?? 'Course'}  ${course?['name'] ?? ''} | ${offering['academic_session']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setDialogState(() => offeringId = value),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Class date'),
                    subtitle: Text(_date(selectedDate)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () async {
                      final value = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2035),
                      );
                      if (value != null) {
                        setDialogState(() => selectedDate = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _field(start, 'Start time', Icons.schedule)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(end, 'End time', Icons.schedule)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field(topic, 'Topic', Icons.subject_outlined),
                  const SizedBox(height: 14),
                  _field(faculty, 'Faculty name', Icons.person_outline),
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
              onPressed: offeringId == null
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.add),
              label: const Text('Create session'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || offeringId == null) return;
    await _run(() async {
      final created = await UniSphereApiService.createAttendanceSession(
        courseOfferingId: offeringId!,
        sessionDate: _date(selectedDate),
        startTime: start.text.trim().isEmpty ? null : start.text.trim(),
        endTime: end.text.trim().isEmpty ? null : end.text.trim(),
        topic: topic.text.trim().isEmpty ? null : topic.text.trim(),
        facultyName: faculty.text.trim().isEmpty ? null : faculty.text.trim(),
      );
      _selectedSessionId = created['id'] as int?;
    });
  }

  Widget _field(TextEditingController controller, String label, IconData icon) =>
      TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      );

  Future<void> _saveRoster() async {
    final sessionId = _selectedSessionId;
    if (sessionId == null) return;
    final records = _roster
        .where((item) => item['status'] != null)
        .map(
          (item) => {
            'student_id': item['student_id'],
            'status': item['status'],
            'remarks': item['remarks'],
          },
        )
        .toList();
    if (records.isEmpty) {
      _message('Select an attendance status for at least one student.');
      return;
    }
    await _run(
      () => UniSphereApiService.recordAttendanceBulk(
        sessionId: sessionId,
        records: records,
      ),
    );
  }

  Future<void> _lockSession() async {
    final session = _selectedSession;
    if (session == null || session['is_locked'] == true) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock attendance session?'),
        content: const Text(
          'Locked attendance cannot be changed. Confirm the roster is complete before continuing.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lock session')),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => UniSphereApiService.lockAttendanceSession(session['id'] as int));
    }
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    setState(() => _saving = true);
    try {
      await action();
      await _load();
      _message('Attendance updated successfully.');
    } on ApiException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('The attendance operation could not be completed.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _markAll(String status) {
    setState(() {
      _roster = _roster.map((item) => {...item, 'status': status}).toList();
    });
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final locked = _selectedSession?['is_locked'] == true;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _error != null
                  ? _errorView()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 1050;
                        final sessions = _sessionPane();
                        final roster = _rosterPane(locked);
                        return wide
                            ? Row(
                                children: [
                                  SizedBox(width: 390, child: sessions),
                                  const VerticalDivider(width: 1),
                                  Expanded(child: roster),
                                ],
                              )
                            : Column(
                                children: [
                                  SizedBox(height: 310, child: sessions),
                                  const Divider(height: 1),
                                  Expanded(child: roster),
                                ],
                              );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
        child: Row(
          children: [
            const Icon(Icons.fact_check_outlined, color: Color(0xFF0F766E), size: 30),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Attendance Operations', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
                  Text('Create class sessions, mark the enrolled roster, and lock verified records.', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
            IconButton(onPressed: _loading ? null : _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
            const SizedBox(width: 8),
            FilledButton.icon(onPressed: _loading ? null : _createSession, icon: const Icon(Icons.add), label: const Text('New session')),
          ],
        ),
      );

  Widget _sessionPane() => Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _metric('Sessions', _sessions.length.toString(), const Color(0xFF2563EB))),
                const SizedBox(width: 10),
                Expanded(child: _metric('Locked', _sessions.where((item) => item['is_locked'] == true).length.toString(), const Color(0xFF0F766E))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Course, faculty, topic'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredSessions.isEmpty
                  ? const Center(child: Text('No class sessions found.'))
                  : ListView.builder(
                      itemCount: _filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = _filteredSessions[index];
                        final course = _courseFor(session);
                        final selected = session['id'] == _selectedSessionId;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFE0F2FE) : Colors.white,
                            border: Border.all(color: selected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            onTap: () => _selectSession(session['id'] as int),
                            title: Text('${course?['code'] ?? 'Course'}  ${course?['name'] ?? ''}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('${session['session_date']}  |  ${session['topic'] ?? 'Topic not set'}', maxLines: 2),
                            trailing: Icon(session['is_locked'] == true ? Icons.lock : Icons.chevron_right, size: 20),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );

  Widget _rosterPane(bool locked) {
    final session = _selectedSession;
    if (session == null) return const Center(child: Text('Select a class session to open its roster.'));
    final course = _courseFor(session);
    final marked = _roster.where((item) => item['status'] != null).length;
    final present = _roster.where((item) => item['status'] == 'present' || item['status'] == 'late').length;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('${course?['code'] ?? 'Course'}  ${course?['name'] ?? ''}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                  _statusBadge(locked ? 'Locked' : 'Open', locked ? const Color(0xFF475569) : const Color(0xFF0F766E)),
                ],
              ),
              const SizedBox(height: 4),
              Text('${session['session_date']}  |  ${session['start_time'] ?? '--:--'} - ${session['end_time'] ?? '--:--'}  |  ${session['faculty_name'] ?? 'Faculty not assigned'}', style: const TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _metric('Enrolled', _roster.length.toString(), const Color(0xFF2563EB))),
                  const SizedBox(width: 10),
                  Expanded(child: _metric('Marked', '$marked/${_roster.length}', const Color(0xFF7C3AED))),
                  const SizedBox(width: 10),
                  Expanded(child: _metric('Present + late', present.toString(), const Color(0xFF0F766E))),
                ],
              ),
              if (!locked) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(onPressed: () => _markAll('present'), icon: const Icon(Icons.done_all), label: const Text('Mark all present')),
                    FilledButton.icon(onPressed: _saving ? null : _saveRoster, icon: const Icon(Icons.save_outlined), label: const Text('Save roster')),
                    TextButton.icon(onPressed: _saving ? null : _lockSession, icon: const Icon(Icons.lock_outline), label: const Text('Lock verified session')),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _roster.isEmpty
              ? const Center(child: Text('No active students are enrolled in this course offering.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _roster.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final student = _roster[index];
                    final value = student['status']?.toString();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: const Color(0xFFE0F2FE), child: Text((student['student_name']?.toString() ?? '?').substring(0, 1).toUpperCase())),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(student['student_name']?.toString() ?? 'Student', style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${student['uni_id']}  |  ${student['programme']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ]),
                          ),
                          SizedBox(
                            width: 145,
                            child: DropdownButtonFormField<String>(
                              initialValue: value,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Status', isDense: true),
                              items: const [
                                DropdownMenuItem(value: 'present', child: Text('Present')),
                                DropdownMenuItem(value: 'absent', child: Text('Absent')),
                                DropdownMenuItem(value: 'late', child: Text('Late')),
                                DropdownMenuItem(value: 'excused', child: Text('Excused')),
                              ],
                              onChanged: locked ? null : (status) => setState(() => _roster[index] = {...student, 'status': status}),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _metric(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), border: Border.all(color: color.withValues(alpha: 0.24)), borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))), const SizedBox(height: 2), Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color))]),
      );

  Widget _statusBadge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );

  Widget _errorView() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 42, color: Color(0xFFB91C1C)),
          const SizedBox(height: 10),
          Text(_error!),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ]),
      );
}
