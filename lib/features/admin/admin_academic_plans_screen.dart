import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class AdminAcademicPlansScreen extends StatefulWidget {
  const AdminAcademicPlansScreen({super.key});

  @override
  State<AdminAcademicPlansScreen> createState() =>
      _AdminAcademicPlansScreenState();
}

class _AdminAcademicPlansScreenState extends State<AdminAcademicPlansScreen> {
  List<Map<String, dynamic>> _students = const [];
  List<Map<String, dynamic>> _programmes = const [];
  List<Map<String, dynamic>> _sessions = const [];
  List<Map<String, dynamic>> _curricula = const [];
  Map<String, dynamic>? _selectedStudent;
  Map<String, dynamic>? _plan;
  int? _programmeId;
  int? _specializationId;
  int? _curriculumId;
  int? _sessionId;
  int _semester = 1;
  String _section = 'A';
  bool _autoEnroll = true;
  bool _standardTimetable = true;
  bool _demoExamPlan = true;
  bool _createInvoice = true;
  bool _loading = true;
  bool _saving = false;
  String? _error;
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
      final result = await Future.wait<dynamic>([
        UniSphereApiService.getAdminStudents(),
        UniSphereApiService.getProgrammes(),
        UniSphereApiService.getAcademicSessions(),
        UniSphereApiService.getCurricula(),
      ]);
      if (!mounted) return;
      final students = (result[0] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      setState(() {
        _students = students;
        _programmes = List<Map<String, dynamic>>.from(result[1] as List);
        _sessions = List<Map<String, dynamic>>.from(result[2] as List);
        _curricula = List<Map<String, dynamic>>.from(result[3] as List);
      });
      if (students.isNotEmpty) {
        final currentId = _selectedStudent?['id'];
        await _selectStudent(
          students.where((item) => item['id'] == currentId).firstOrNull ??
              students.first,
        );
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load academic plans.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectStudent(Map<String, dynamic> student) async {
    setState(() {
      _selectedStudent = student;
      _plan = null;
      _programmeId = student['programme_id'] as int?;
      _specializationId = student['specialization_id'] as int?;
      _curriculumId = student['curriculum_id'] as int?;
      _sessionId =
          student['academic_session_id'] as int? ??
          _sessions
                  .where((item) => item['is_active'] == true)
                  .firstOrNull?['id']
              as int?;
      _semester = student['current_semester'] as int? ?? 1;
      _section = 'A';
    });
    if (_programmeId == null) {
      _programmeId = _inferProgramme(student['programme']?.toString());
      final options = _specializationsFor(_programmeId);
      _specializationId = options.length == 1
          ? options.first['id'] as int
          : null;
      _curriculumId = _curriculaForSelection().firstOrNull?['id'] as int?;
      if (mounted) setState(() {});
      return;
    }
    try {
      final plan = await UniSphereApiService.getStudentAcademicPlan(
        student['id'] as int,
      );
      if (!mounted || _selectedStudent?['id'] != student['id']) return;
      setState(() {
        _plan = plan;
        _section = plan['section']?.toString() ?? 'A';
      });
    } on ApiException catch (error) {
      if (error.statusCode != 404) _message(error.message);
    }
  }

  int? _inferProgramme(String? label) {
    final value = _normalise(label ?? '');
    if (value.isEmpty) return null;
    final exact = _programmes.where((item) {
      final name = _normalise(item['name']?.toString() ?? '');
      return value == name || value.startsWith(name) || name.startsWith(value);
    }).firstOrNull;
    return exact?['id'] as int?;
  }

  List<Map<String, dynamic>> _specializationsFor(int? programmeId) {
    final programme = _programmes
        .where((item) => item['id'] == programmeId)
        .firstOrNull;
    final values = programme?['specializations'];
    if (values is! List) return const [];
    return values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['is_active'] != false)
        .toList();
  }

  List<Map<String, dynamic>> _curriculaForSelection() =>
      _curricula.where((item) {
        if (item['programme_id'] != _programmeId) return false;
        if (_specializationId == null) return item['specialization_id'] == null;
        return item['specialization_id'] == _specializationId;
      }).toList();

  List<Map<String, dynamic>> get _filteredStudents {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return _students;
    return _students
        .where(
          (student) => [
            student['full_name'],
            student['uni_id'],
            student['programme'],
          ].any((value) => value.toString().toLowerCase().contains(needle)),
        )
        .toList();
  }

  void _changeProgramme(int? value) {
    final options = _specializationsFor(value);
    setState(() {
      _programmeId = value;
      _specializationId = options.isEmpty ? null : options.first['id'] as int;
      _curriculumId = null;
      _semester = 1;
    });
    final curricula = _curriculaForSelection();
    if (curricula.isNotEmpty) {
      setState(() => _curriculumId = curricula.first['id'] as int);
    }
  }

  void _changeSpecialization(int? value) {
    setState(() {
      _specializationId = value;
      _curriculumId = null;
      _semester = 1;
    });
    final curricula = _curriculaForSelection();
    if (curricula.isNotEmpty) {
      setState(() => _curriculumId = curricula.first['id'] as int);
    }
  }

  Future<void> _save() async {
    final studentId = _selectedStudent?['id'] as int?;
    if (studentId == null ||
        _programmeId == null ||
        _curriculumId == null ||
        _sessionId == null) {
      _message('Select a programme, curriculum, and academic session.');
      return;
    }
    setState(() => _saving = true);
    try {
      final plan = await UniSphereApiService.assignStudentAcademicPlan(
        studentId: studentId,
        programmeId: _programmeId!,
        specializationId: _specializationId,
        curriculumId: _curriculumId!,
        academicSessionId: _sessionId!,
        currentSemester: _semester,
        section: _section.trim().isEmpty ? 'A' : _section.trim(),
        autoEnroll: _autoEnroll,
        createStandardTimetable: _standardTimetable,
        createDemoExamPlan: _demoExamPlan,
        createFeeInvoice: _createInvoice,
      );
      if (!mounted) return;
      setState(() => _plan = plan);
      _message(
        '${plan['enrollments_created']} enrolled, ${plan['timetable_entries_created']} timetable slots, ${plan['exam_registrations_created']} exam registrations.',
      );
      final students = (await UniSphereApiService.getAdminStudents())
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      if (!mounted) return;
      setState(() {
        _students = students;
        _selectedStudent = students
            .where((item) => item['id'] == studentId)
            .firstOrNull;
      });
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publishResult(Map course) async {
    final controller = TextEditingController(
      text: course['marks']?.toString() ?? '',
    );
    final marks = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publish course result'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${course['paper_code']}  ${course['course_name']}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Marks out of 100',
                  prefixIcon: Icon(Icons.assessment_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || value < 0 || value > 100) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (marks == null || _selectedStudent == null || _plan == null) return;
    try {
      await UniSphereApiService.publishStudentResult(
        studentId: _selectedStudent!['id'] as int,
        courseId: course['course_id'] as int,
        semesterId: _plan!['semester_id'] as int,
        marks: marks,
      );
      final plan = await UniSphereApiService.getStudentAcademicPlan(
        _selectedStudent!['id'] as int,
      );
      if (mounted) {
        setState(() => _plan = plan);
        _message('Result published to the student portal.');
      }
    } on ApiException catch (error) {
      _message(error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assigned = _students
        .where((item) => item['curriculum_id'] != null)
        .length;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Planning',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF172554),
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Connect each student to the curriculum that drives courses, timetable and fees.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh plans',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Metric(
                  label: 'Students',
                  value: '${_students.length}',
                  icon: Icons.people_outline,
                  color: const Color(0xFF2563EB),
                ),
                _Metric(
                  label: 'Plans assigned',
                  value: '$assigned',
                  icon: Icons.task_alt_outlined,
                  color: const Color(0xFF059669),
                ),
                _Metric(
                  label: 'Awaiting plan',
                  value: '${_students.length - assigned}',
                  icon: Icons.pending_actions_outlined,
                  color: const Color(0xFFD97706),
                ),
                _Metric(
                  label: 'Curricula',
                  value: '${_curricula.length}',
                  icon: Icons.library_books_outlined,
                  color: const Color(0xFF7C3AED),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(56),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _load)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final studentList = _studentList();
                  final editor = _editor();
                  if (constraints.maxWidth < 980) {
                    return Column(
                      children: [
                        studentList,
                        const SizedBox(height: 14),
                        editor,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 330, child: studentList),
                      const SizedBox(width: 16),
                      Expanded(child: editor),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _studentList() => _Surface(
    title: 'Student register',
    subtitle: 'Select a student to configure',
    child: Column(
      children: [
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search students',
          ),
        ),
        const SizedBox(height: 12),
        ..._filteredStudents.map((student) {
          final selected = student['id'] == _selectedStudent?['id'];
          final assigned = student['curriculum_id'] != null;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ListTile(
              selected: selected,
              selectedTileColor: const Color(0xFFEEF2FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              leading: CircleAvatar(
                backgroundColor: assigned
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFFF7ED),
                foregroundColor: assigned
                    ? const Color(0xFF047857)
                    : const Color(0xFFC2410C),
                child: Icon(assigned ? Icons.check : Icons.schedule, size: 18),
              ),
              title: Text(
                student['full_name']?.toString() ?? 'Student',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                '${student['uni_id']}\n${student['programme']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => _selectStudent(student),
            ),
          );
        }),
      ],
    ),
  );

  Widget _editor() {
    if (_selectedStudent == null) {
      return const _Surface(
        title: 'Academic plan',
        subtitle: '',
        child: Text('Select a student.'),
      );
    }
    final options = _specializationsFor(_programmeId);
    final curricula = _curriculaForSelection();
    final selectedCurriculum = curricula
        .where((item) => item['id'] == _curriculumId)
        .firstOrNull;
    final semesterCount = selectedCurriculum?['semester_count'] as int? ?? 1;
    if (_semester > semesterCount) _semester = 1;
    return _Surface(
      title: _selectedStudent!['full_name']?.toString() ?? 'Academic plan',
      subtitle:
          '${_selectedStudent!['uni_id']}  |  Current semester ${_selectedStudent!['current_semester']}',
      trailing: _selectedStudent!['curriculum_id'] == null
          ? const _Badge(label: 'PLAN REQUIRED', good: false)
          : const _Badge(label: 'PLAN ASSIGNED', good: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth < 700
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('programme-$_programmeId'),
                      initialValue: _programmeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Programme',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: _programmes
                          .map(
                            (item) => DropdownMenuItem(
                              value: item['id'] as int,
                              child: Text(
                                item['name']?.toString() ?? 'Programme',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _saving ? null : _changeProgramme,
                    ),
                  ),
                  if (options.isNotEmpty)
                    SizedBox(
                      width: width,
                      child: DropdownButtonFormField<int>(
                        key: ValueKey(
                          'specialization-$_programmeId-$_specializationId',
                        ),
                        initialValue: _specializationId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Subject / specialization',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: options
                            .map(
                              (item) => DropdownMenuItem(
                                value: item['id'] as int,
                                child: Text(
                                  item['name']?.toString() ?? 'Specialization',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _saving ? null : _changeSpecialization,
                      ),
                    ),
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(
                        'curriculum-$_programmeId-$_specializationId-$_curriculumId',
                      ),
                      initialValue:
                          curricula.any((item) => item['id'] == _curriculumId)
                          ? _curriculumId
                          : null,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Curriculum',
                        prefixIcon: Icon(Icons.library_books_outlined),
                      ),
                      items: curricula
                          .map(
                            (item) => DropdownMenuItem(
                              value: item['id'] as int,
                              child: Text(
                                '${item['version']}  |  ${item['course_count']} papers',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() {
                              _curriculumId = value;
                              _semester = 1;
                            }),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<int>(
                      initialValue: _sessionId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Academic session',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      items: _sessions
                          .map(
                            (item) => DropdownMenuItem(
                              value: item['id'] as int,
                              child: Text(
                                '${item['name']}${item['is_active'] == true ? ' (Active)' : ''}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _sessionId = value),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<int>(
                      key: ValueKey('semester-$_curriculumId-$_semester'),
                      initialValue: _semester,
                      decoration: const InputDecoration(
                        labelText: 'Current semester',
                        prefixIcon: Icon(Icons.date_range_outlined),
                      ),
                      items: List.generate(semesterCount, (index) => index + 1)
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('Semester $value'),
                            ),
                          )
                          .toList(),
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _semester = value ?? 1),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: TextFormField(
                      initialValue: _section,
                      decoration: const InputDecoration(
                        labelText: 'Section',
                        prefixIcon: Icon(Icons.grid_view_outlined),
                      ),
                      onChanged: (value) => _section = value,
                    ),
                  ),
                ],
              );
            },
          ),
          if (selectedCurriculum != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                selectedCurriculum['is_demo'] == true
                    ? 'Demo curriculum: workflow-ready sample data, not an official university syllabus.'
                    : 'Published university curriculum selected.',
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 4,
            children: [
              _Option(
                label: 'Enroll semester courses',
                value: _autoEnroll,
                onChanged: (value) => setState(() => _autoEnroll = value),
              ),
              _Option(
                label: 'Create standard timetable',
                value: _standardTimetable,
                onChanged: (value) =>
                    setState(() => _standardTimetable = value),
              ),
              _Option(
                label: 'Generate invoice from fee structure',
                value: _createInvoice,
                onChanged: (value) => setState(() => _createInvoice = value),
              ),
            ],
          ),
          _Option(
            label: 'Create demo examination plan',
            value: _demoExamPlan,
            onChanged: (value) => setState(() => _demoExamPlan = value),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.auto_awesome_motion_outlined),
              label: Text(
                _saving ? 'Provisioning...' : 'Save & provision semester',
              ),
            ),
          ),
          if (_plan != null) ...[const Divider(height: 34), _planSummary()],
        ],
      ),
    );
  }

  Widget _planSummary() {
    final courses = (_plan!['courses'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Provisioned semester',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF172554),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _CompactMetric(
              label: 'Curriculum papers',
              value: '${_plan!['curriculum_course_count']}',
            ),
            _CompactMetric(
              label: 'Active enrollments',
              value: '${_plan!['active_enrollment_count']}',
            ),
            _CompactMetric(
              label: 'Timetable slots',
              value: '${_plan!['timetable_entry_count']}',
            ),
            _CompactMetric(
              label: 'Invoices',
              value: '${_plan!['invoice_count']}',
            ),
            _CompactMetric(
              label: 'Exam registrations',
              value: '${_plan!['exam_registration_count']}',
            ),
            _CompactMetric(
              label: 'Results published',
              value: '${_plan!['result_count']}',
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...courses.map(
          (course) => Container(
            margin: const EdgeInsets.only(bottom: 7),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${course['paper_code']}  ${course['course_name']}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${course['paper_type']}  |  ${course['credits']} credits',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                _Badge(
                  label:
                      course['enrollment_status']?.toString().toUpperCase() ??
                      'PENDING',
                  good: course['enrollment_status'] == 'enrolled',
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${course['timetable_slots']} slot',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (course['grade'] != null)
                      Text(
                        '${course['marks']} marks  |  ${course['grade']}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF6D28D9),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  tooltip: course['grade'] == null
                      ? 'Publish result'
                      : 'Update result',
                  onPressed: () => _publishResult(course),
                  icon: const Icon(Icons.edit_note_outlined),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _normalise(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF172554),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 195,
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE2E8F0)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF2FF),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3730A3),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.good});
  final String label;
  final bool good;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: good ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: good ? const Color(0xFF047857) : const Color(0xFFC2410C),
      ),
    ),
  );
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Switch(value: value, onChanged: onChanged),
      Text(label),
    ],
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        Text(message),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}
