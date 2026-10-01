import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class AdminExaminationsScreen extends StatefulWidget {
  const AdminExaminationsScreen({super.key});

  @override
  State<AdminExaminationsScreen> createState() => _AdminExaminationsScreenState();
}

class _AdminExaminationsScreenState extends State<AdminExaminationsScreen> {
  bool _loading = true;
  bool _working = false;
  String? _error;
  List<Map<String, dynamic>> _exams = const [];
  List<Map<String, dynamic>> _registrations = const [];
  List<Map<String, dynamic>> _schedules = const [];
  List<Map<String, dynamic>> _students = const [];
  List<Map<String, dynamic>> _semesters = const [];
  List<Map<String, dynamic>> _courses = const [];
  List<Map<String, dynamic>> _offerings = const [];
  int? _selectedExamId;
  String _view = 'schedule';
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
        UniSphereApiService.getAdminExaminations(),
        UniSphereApiService.getAdminExamRegistrations(),
        UniSphereApiService.getAdminStudents(),
        UniSphereApiService.getSemesters(),
        UniSphereApiService.getAdminCourses(),
        UniSphereApiService.getCourseOfferings(),
      ]);
      final exams = List<Map<String, dynamic>>.from(data[0] as List);
      if (!mounted) return;
      setState(() {
        _exams = exams;
        _registrations = List<Map<String, dynamic>>.from(data[1] as List);
        _students = (data[2] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList();
        _semesters = List<Map<String, dynamic>>.from(data[3] as List);
        _courses = List<Map<String, dynamic>>.from(data[4] as List);
        _offerings = List<Map<String, dynamic>>.from(data[5] as List);
        if (_selectedExamId == null || !exams.any((item) => item['id'] == _selectedExamId)) {
          _selectedExamId = exams.firstOrNull?['id'] as int?;
        }
      });
      await _loadSchedules();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load examination operations.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSchedules() async {
    final examId = _selectedExamId;
    if (examId == null) {
      if (mounted) setState(() => _schedules = const []);
      return;
    }
    final schedules = await UniSphereApiService.getExaminationSchedules(examId);
    if (mounted && examId == _selectedExamId) setState(() => _schedules = schedules);
  }

  Map<String, dynamic>? get _exam =>
      _exams.where((item) => item['id'] == _selectedExamId).firstOrNull;

  List<Map<String, dynamic>> get _examRegistrations => _registrations
      .where((item) => item['examination_id'] == _selectedExamId)
      .toList();

  Map<String, dynamic>? _course(int? id) =>
      _courses.where((item) => item['id'] == id).firstOrNull;

  Map<String, dynamic>? _student(int? id) =>
      _students.where((item) => item['id'] == id).firstOrNull;

  List<Map<String, dynamic>> get _filteredExams {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return _exams;
    return _exams.where((item) => [item['name'], item['exam_type'], item['academic_session']]
        .any((value) => value.toString().toLowerCase().contains(needle))).toList();
  }

  Future<void> _selectExam(int id) async {
    setState(() {
      _selectedExamId = id;
      _schedules = const [];
    });
    try {
      await _loadSchedules();
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  Future<void> _createExam() async {
    int? semesterId = _semesters.firstOrNull?['id'] as int?;
    final name = TextEditingController();
    final type = TextEditingController(text: 'semester');
    final academicSession = TextEditingController(text: '2026-27');
    final startDate = TextEditingController();
    final endDate = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(children: [Icon(Icons.assignment_add), SizedBox(width: 10), Text('Create examination')]),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(name, 'Examination name', Icons.badge_outlined),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _field(type, 'Type', Icons.category_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(academicSession, 'Academic session', Icons.calendar_month_outlined)),
                ]),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: semesterId,
                  decoration: const InputDecoration(labelText: 'Semester', prefixIcon: Icon(Icons.date_range_outlined)),
                  items: _semesters.map((semester) => DropdownMenuItem(value: semester['id'] as int, child: Text(semester['name']?.toString() ?? 'Semester ${semester['number']}'))).toList(),
                  onChanged: (value) => setDialogState(() => semesterId = value),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _field(startDate, 'Start date YYYY-MM-DD', Icons.event_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(endDate, 'End date YYYY-MM-DD', Icons.event_available_outlined)),
                ]),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton.icon(
              onPressed: semesterId == null
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || semesterId == null) return;
    if (name.text.trim().isEmpty || academicSession.text.trim().isEmpty) {
      _message('Examination name and academic session are required.');
      return;
    }
    await _run(() async {
      final created = await UniSphereApiService.createExamination(
        name: name.text.trim(),
        examType: type.text.trim(),
        academicSession: academicSession.text.trim(),
        semesterId: semesterId!,
        startDate: startDate.text.trim().isEmpty ? null : startDate.text.trim(),
        endDate: endDate.text.trim().isEmpty ? null : endDate.text.trim(),
      );
      _selectedExamId = created['id'] as int?;
    }, 'Examination created.');
  }

  Future<void> _addPaper() async {
    final exam = _exam;
    if (exam == null || exam['is_locked'] == true) return;
    final eligibleCourseIds = _offerings
        .where((item) => item['semester_id'] == exam['semester_id'] && item['academic_session'] == exam['academic_session'])
        .map((item) => item['course_id'] as int)
        .toSet();
    final existingIds = _schedules.map((item) => item['course_id']).toSet();
    final eligible = _courses.where((item) => eligibleCourseIds.contains(item['id']) && !existingIds.contains(item['id'])).toList();
    if (eligible.isEmpty) {
      _message('Every active course offering for this examination already has a paper.');
      return;
    }
    int? courseId = eligible.first['id'] as int;
    final examDate = TextEditingController(text: exam['start_date']?.toString() ?? '');
    final start = TextEditingController(text: '10:00');
    final end = TextEditingController(text: '13:00');
    final building = TextEditingController(text: 'Examination Block');
    final room = TextEditingController();
    final maxMarks = TextEditingController(text: '100');
    final passingMarks = TextEditingController(text: '40');
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(children: [Icon(Icons.post_add_outlined), SizedBox(width: 10), Text('Schedule examination paper')]),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<int>(
                  initialValue: courseId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Course paper', prefixIcon: Icon(Icons.menu_book_outlined)),
                  items: eligible.map((course) => DropdownMenuItem(value: course['id'] as int, child: Text('${course['code']}  ${course['name']}', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (value) => setDialogState(() => courseId = value),
                ),
                const SizedBox(height: 14),
                _field(examDate, 'Exam date YYYY-MM-DD', Icons.event_outlined),
                const SizedBox(height: 14),
                Row(children: [Expanded(child: _field(start, 'Start time', Icons.schedule)), const SizedBox(width: 12), Expanded(child: _field(end, 'End time', Icons.schedule))]),
                const SizedBox(height: 14),
                Row(children: [Expanded(child: _field(building, 'Building', Icons.apartment_outlined)), const SizedBox(width: 12), Expanded(child: _field(room, 'Room', Icons.meeting_room_outlined))]),
                const SizedBox(height: 14),
                Row(children: [Expanded(child: _field(maxMarks, 'Maximum marks', Icons.score_outlined)), const SizedBox(width: 12), Expanded(child: _field(passingMarks, 'Passing marks', Icons.check_circle_outline))]),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton.icon(onPressed: () => Navigator.pop(dialogContext, true), icon: const Icon(Icons.add), label: const Text('Add paper')),
          ],
        ),
      ),
    );
    if (submitted != true || courseId == null) return;
    await _run(
      () => UniSphereApiService.createExaminationSchedule(
        examinationId: exam['id'] as int,
        courseId: courseId!,
        examDate: examDate.text.trim(),
        startTime: start.text.trim(),
        endTime: end.text.trim(),
        building: building.text.trim().isEmpty ? null : building.text.trim(),
        room: room.text.trim().isEmpty ? null : room.text.trim(),
        maxMarks: int.parse(maxMarks.text),
        passingMarks: int.parse(passingMarks.text),
      ),
      'Examination paper scheduled.',
    );
  }

  Future<void> _registerStudent() async {
    final exam = _exam;
    if (exam == null || _schedules.isEmpty || exam['is_registration_open'] != true) return;
    final registeredIds = _examRegistrations.map((item) => item['student_id']).toSet();
    final eligible = _students.where((student) =>
        student['current_semester'] == _semesterNumber(exam['semester_id'] as int?) &&
        student['academic_session'] == exam['academic_session'] &&
        !registeredIds.contains(student['id'])).toList();
    if (eligible.isEmpty) {
      _message('No unregistered students match this session and semester.');
      return;
    }
    final student = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register student'),
        content: SizedBox(
          width: 520,
          height: 420,
          child: ListView.separated(
            itemCount: eligible.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = eligible[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(item['full_name']?.toString() ?? 'Student'),
                subtitle: Text('${item['uni_id']}  |  ${item['programme']}'),
                onTap: () => Navigator.pop(context, item),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))],
      ),
    );
    if (student == null) return;
    await _run(
      () => UniSphereApiService.registerStudentForExamination(
        studentId: student['id'] as int,
        examinationId: exam['id'] as int,
        scheduleIds: _schedules.map((item) => item['id'] as int).toList(),
      ),
      '${student['full_name']} registered for all scheduled papers.',
    );
  }

  int? _semesterNumber(int? id) => _semesters.where((item) => item['id'] == id).firstOrNull?['number'] as int?;

  Future<void> _changeRegistrationStatus(Map<String, dynamic> registration, String status) => _run(
        () => UniSphereApiService.updateExaminationRegistrationStatus(registrationId: registration['id'] as int, status: status),
        'Registration marked $status.',
      );

  Future<void> _toggleRegistration() async {
    final exam = _exam;
    if (exam == null || exam['is_locked'] == true) return;
    final close = exam['is_registration_open'] == true;
    await _run(
      () => UniSphereApiService.setExaminationRegistrationLock(examinationId: exam['id'] as int, locked: close),
      close ? 'Registration closed.' : 'Registration reopened.',
    );
  }

  Future<void> _lockExam() async {
    final exam = _exam;
    if (exam == null || exam['is_locked'] == true) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lock examination?'),
        content: const Text('Locking closes registration and prevents the examination from being reopened.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lock examination')),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(() => UniSphereApiService.lockExamination(exam['id'] as int), 'Examination locked.');
    }
  }

  Widget _field(TextEditingController controller, String label, IconData icon) => TextField(
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
      _message('The examination operation could not be completed.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _message(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF4F7FA),
        body: SafeArea(
          child: Column(children: [
            _header(),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _error != null
                  ? _errorView()
                  : LayoutBuilder(builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 1080;
                      return wide
                          ? Row(children: [SizedBox(width: 390, child: _examPane()), const VerticalDivider(width: 1), Expanded(child: _detailPane())])
                          : Column(children: [SizedBox(height: 300, child: _examPane()), const Divider(height: 1), Expanded(child: _detailPane())]);
                    }),
            ),
          ]),
        ),
      );

  Widget _header() => Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
        child: Row(children: [
          const Icon(Icons.assignment_outlined, color: Color(0xFF4338CA), size: 30),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Examination Operations', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800)),
            Text('Control examination windows, paper schedules, student registrations, and approvals.', style: TextStyle(color: Color(0xFF64748B))),
          ])),
          IconButton(onPressed: _loading ? null : _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh)),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: _loading ? null : _createExam, icon: const Icon(Icons.add), label: const Text('New examination')),
        ]),
      );

  Widget _examPane() => Container(
        color: const Color(0xFFF8FAFC),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(child: _metric('Examinations', _exams.length.toString(), const Color(0xFF4338CA))),
            const SizedBox(width: 10),
            Expanded(child: _metric('Open', _exams.where((item) => item['is_registration_open'] == true).length.toString(), const Color(0xFF0F766E))),
          ]),
          const SizedBox(height: 12),
          TextField(onChanged: (value) => setState(() => _query = value), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search examinations')),
          const SizedBox(height: 10),
          Expanded(
            child: _filteredExams.isEmpty
                ? const Center(child: Text('No examinations configured.'))
                : ListView.builder(
                    itemCount: _filteredExams.length,
                    itemBuilder: (context, index) {
                      final exam = _filteredExams[index];
                      final selected = exam['id'] == _selectedExamId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: selected ? const Color(0xFFEDE9FE) : Colors.white, border: Border.all(color: selected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          onTap: () => _selectExam(exam['id'] as int),
                          title: Text(exam['name']?.toString() ?? 'Examination', maxLines: 2, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('${exam['academic_session']}  |  ${exam['start_date'] ?? 'Dates pending'}'),
                          trailing: Icon(exam['is_locked'] == true ? Icons.lock : Icons.chevron_right, size: 20),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      );

  Widget _detailPane() {
    final exam = _exam;
    if (exam == null) return const Center(child: Text('Select an examination to manage operations.'));
    final locked = exam['is_locked'] == true;
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(exam['name']?.toString() ?? 'Examination', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
            _badge(locked ? 'Locked' : exam['is_registration_open'] == true ? 'Registration open' : 'Registration closed', locked ? const Color(0xFF475569) : exam['is_registration_open'] == true ? const Color(0xFF0F766E) : const Color(0xFFB45309)),
          ]),
          const SizedBox(height: 5),
          Text('${exam['exam_type']}  |  ${exam['academic_session']}  |  ${exam['start_date'] ?? 'Start pending'} to ${exam['end_date'] ?? 'End pending'}', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _metric('Papers', _schedules.length.toString(), const Color(0xFF2563EB))),
            const SizedBox(width: 10),
            Expanded(child: _metric('Registered', _examRegistrations.length.toString(), const Color(0xFF7C3AED))),
            const SizedBox(width: 10),
            Expanded(child: _metric('Approved', _examRegistrations.where((item) => item['status'] == 'approved').length.toString(), const Color(0xFF0F766E))),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (!locked) OutlinedButton.icon(onPressed: _working ? null : _addPaper, icon: const Icon(Icons.post_add_outlined), label: const Text('Add paper')),
            if (!locked && exam['is_registration_open'] == true) FilledButton.icon(onPressed: _working || _schedules.isEmpty ? null : _registerStudent, icon: const Icon(Icons.person_add_alt), label: const Text('Register student')),
            if (!locked) TextButton.icon(onPressed: _working ? null : _toggleRegistration, icon: Icon(exam['is_registration_open'] == true ? Icons.lock_clock_outlined : Icons.lock_open_outlined), label: Text(exam['is_registration_open'] == true ? 'Close registration' : 'Open registration')),
            if (!locked) TextButton.icon(onPressed: _working ? null : _lockExam, icon: const Icon(Icons.lock_outline), label: const Text('Lock examination')),
          ]),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [ButtonSegment(value: 'schedule', label: Text('Paper schedule'), icon: Icon(Icons.event_note_outlined)), ButtonSegment(value: 'registrations', label: Text('Registrations'), icon: Icon(Icons.how_to_reg_outlined))],
            selected: {_view},
            onSelectionChanged: (value) => setState(() => _view = value.first),
          ),
        ]),
      ),
      const Divider(height: 1),
      Expanded(child: _view == 'schedule' ? _scheduleList() : _registrationList()),
    ]);
  }

  Widget _scheduleList() => _schedules.isEmpty
      ? const Center(child: Text('No examination papers scheduled yet.'))
      : ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _schedules.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _schedules[index];
            final course = _course(item['course_id'] as int?);
            return Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)), child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB)))),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${course?['code'] ?? 'Course'}  ${course?['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${item['exam_date']}  |  ${item['start_time']} - ${item['end_time']}  |  ${item['building'] ?? 'Building pending'}, ${item['room'] ?? 'Room pending'}', style: const TextStyle(color: Color(0xFF64748B))),
                ])),
                Text('${item['max_marks']} marks', style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
            );
          },
        );

  Widget _registrationList() => _examRegistrations.isEmpty
      ? const Center(child: Text('No students registered for this examination.'))
      : ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: _examRegistrations.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = _examRegistrations[index];
            final student = _student(item['student_id'] as int?);
            final status = item['status']?.toString() ?? 'registered';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const CircleAvatar(backgroundColor: Color(0xFFEDE9FE), child: Icon(Icons.person_outline, color: Color(0xFF6D28D9))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(student?['full_name']?.toString() ?? 'Student #${item['student_id']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('${student?['uni_id'] ?? '-'}  |  ${item['registration_number']}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ])),
                _badge(status, status == 'approved' ? const Color(0xFF0F766E) : status == 'rejected' ? const Color(0xFFB91C1C) : const Color(0xFFB45309)),
                if (_exam?['is_locked'] != true) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Change registration status',
                    onSelected: (value) => _changeRegistrationStatus(item, value),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'approved', child: Text('Approve')),
                      PopupMenuItem(value: 'rejected', child: Text('Reject')),
                      PopupMenuItem(value: 'cancelled', child: Text('Cancel registration')),
                    ],
                  ),
                ],
              ]),
            );
          },
        );

  Widget _metric(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), border: Border.all(color: color.withValues(alpha: 0.22)), borderRadius: BorderRadius.circular(8)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))), const SizedBox(height: 2), Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color))]),
      );

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );

  Widget _errorView() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 42, color: Color(0xFFB91C1C)),
        const SizedBox(height: 10),
        Text(_error!),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
      ]));
}
