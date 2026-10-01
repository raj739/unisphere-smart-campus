import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class Student360Screen extends StatefulWidget {
  const Student360Screen({super.key});

  @override
  State<Student360Screen> createState() => _Student360ScreenState();
}

class _Student360ScreenState extends State<Student360Screen> {
  static const _navy = Color(0xFF172554);
  static const _indigo = Color(0xFF4F46E5);
  static const _teal = Color(0xFF0F766E);
  static const _amber = Color(0xFFD97706);
  static const _coral = Color(0xFFDC2626);

  List<Map<String, dynamic>> _students = const [];
  List<Map<String, dynamic>> _courses = const [];
  List<Map<String, dynamic>> _offerings = const [];
  List<Map<String, dynamic>> _semesters = const [];
  List<Map<String, dynamic>> _examinations = const [];
  List<Map<String, dynamic>> _examRegistrations = const [];
  List<Map<String, dynamic>> _enrollments = const [];
  List<Map<String, dynamic>> _timetable = const [];
  List<Map<String, dynamic>> _attendance = const [];
  List<Map<String, dynamic>> _invoices = const [];

  Map<String, dynamic>? _selectedStudent;
  String _query = '';
  int _section = 0;
  bool _loadingWorkspace = true;
  bool _loadingStudent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  Future<void> _loadWorkspace() async {
    final selectedId = _id(_selectedStudent?['id']);
    setState(() {
      _loadingWorkspace = true;
      _error = null;
    });

    try {
      final students = _maps(await UniSphereApiService.getAdminStudents());
      final values = await Future.wait<List<Map<String, dynamic>>>([
        _optionalRecords(UniSphereApiService.getAdminCourses()),
        _optionalRecords(UniSphereApiService.getCourseOfferings()),
        _optionalRecords(UniSphereApiService.getSemesters()),
        _optionalRecords(UniSphereApiService.getAdminExaminations()),
        _optionalRecords(UniSphereApiService.getAdminExamRegistrations()),
      ]);

      if (!mounted) return;
      final preserved = students.where((item) => _id(item['id']) == selectedId);
      setState(() {
        _students = students;
        _courses = values[0];
        _offerings = values[1];
        _semesters = values[2];
        _examinations = values[3];
        _examRegistrations = values[4];
        _selectedStudent = preserved.isNotEmpty
            ? preserved.first
            : (students.isEmpty ? null : students.first);
        _loadingWorkspace = false;
      });
      await _loadStudentRecords();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingWorkspace = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingWorkspace = false;
        _error = 'Unable to load the Student 360 workspace.';
      });
    }
  }

  Future<void> _loadStudentRecords() async {
    final studentId = _id(_selectedStudent?['id']);
    if (studentId == null) {
      setState(() {
        _enrollments = const [];
        _timetable = const [];
        _attendance = const [];
        _invoices = const [];
      });
      return;
    }

    setState(() => _loadingStudent = true);
    try {
      final values = await Future.wait<List<Map<String, dynamic>>>([
        _optionalRecords(UniSphereApiService.getStudentCoursesAdmin(studentId)),
        _optionalRecords(
          UniSphereApiService.getAdminStudentTimetable(studentId),
        ),
        _optionalRecords(
          UniSphereApiService.getAdminStudentAttendance(studentId),
        ),
        _optionalRecords(
          UniSphereApiService.getAdminInvoices(studentId: studentId),
        ),
      ]);
      if (!mounted || _id(_selectedStudent?['id']) != studentId) return;
      setState(() {
        _enrollments = values[0];
        _timetable = values[1];
        _attendance = values[2];
        _invoices = values[3];
      });
    } on ApiException catch (error) {
      if (mounted) _message(error.message, error: true);
    } catch (_) {
      if (mounted) _message('Unable to load this student record.', error: true);
    } finally {
      if (mounted && _id(_selectedStudent?['id']) == studentId) {
        setState(() => _loadingStudent = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _optionalRecords(
    Future<List<Map<String, dynamic>>> request,
  ) async {
    try {
      return await request;
    } catch (_) {
      return const [];
    }
  }

  Future<void> _selectStudent(Map<String, dynamic> student) async {
    if (_id(student['id']) == _id(_selectedStudent?['id'])) return;
    setState(() {
      _selectedStudent = student;
      _section = 0;
    });
    await _loadStudentRecords();
  }

  List<Map<String, dynamic>> get _filteredStudents {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _students;
    return _students.where((student) {
      return [
        student['full_name'],
        student['uni_id'],
        student['programme'],
        student['enrollment_number'],
      ].any(
        (value) => value?.toString().toLowerCase().contains(query) ?? false,
      );
    }).toList();
  }

  List<Map<String, dynamic>> get _activeEnrollments => _enrollments
      .where((item) => item['enrollment_status'] == 'enrolled')
      .toList();

  List<Map<String, dynamic>> get _studentExamRegistrations {
    final studentId = _id(_selectedStudent?['id']);
    return _examRegistrations
        .where((item) => _id(item['student_id']) == studentId)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          children: [
            _pageHeader(),
            Expanded(
              child: _loadingWorkspace
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _errorState()
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 1050) {
                          return Column(
                            children: [
                              _compactStudentPicker(),
                              Expanded(child: _studentWorkspace()),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(width: 318, child: _studentDirectory()),
                            const VerticalDivider(width: 1),
                            Expanded(child: _studentWorkspace()),
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

  Widget _pageHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E7EF))),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student 360',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: _navy,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'A live, complete view of every student journey.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bolt, size: 15, color: _teal),
                SizedBox(width: 5),
                Text(
                  'LIVE DATA',
                  style: TextStyle(
                    color: _teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Refresh workspace',
            child: IconButton.filledTonal(
              onPressed: _loadingStudent ? null : _loadWorkspace,
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _studentDirectory() {
    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                hintText: 'Find a student',
                prefixIcon: Icon(Icons.search, size: 20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${_filteredStudents.length} STUDENTS',
              style: const TextStyle(
                color: Color(0xFF7A8699),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _filteredStudents.isEmpty
                ? const Center(child: Text('No matching students'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = _filteredStudents[index];
                      final selected =
                          _id(student['id']) == _id(_selectedStudent?['id']);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(7),
                          onTap: () => _selectStudent(student),
                          child: Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFEAF0F7)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFB8C8DB)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: selected
                                      ? _navy
                                      : const Color(0xFFE8F3F1),
                                  child: Text(
                                    _initials(student['full_name']),
                                    style: TextStyle(
                                      color: selected ? Colors.white : _teal,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _text(student['full_name'], 'Student'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF253247),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${_text(student['programme'], 'Programme')} | Sem ${student['current_semester'] ?? '-'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF7A8699),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected)
                                  const Icon(
                                    Icons.chevron_right,
                                    color: _navy,
                                    size: 19,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _compactStudentPicker() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: DropdownButtonFormField<int>(
        initialValue: _id(_selectedStudent?['id']),
        decoration: const InputDecoration(
          labelText: 'Selected student',
          prefixIcon: Icon(Icons.person_search_outlined),
        ),
        items: _students
            .map(
              (student) => DropdownMenuItem<int>(
                value: _id(student['id']),
                child: Text(
                  '${_text(student['full_name'], 'Student')} - ${_text(student['uni_id'], '-')}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (id) {
          final matches = _students.where((item) => _id(item['id']) == id);
          if (matches.isNotEmpty) _selectStudent(matches.first);
        },
      ),
    );
  }

  Widget _studentWorkspace() {
    if (_selectedStudent == null) {
      return const Center(child: Text('Register a student to begin setup.'));
    }

    return Column(
      children: [
        _studentHeader(),
        _workspaceTabs(),
        Expanded(
          child: _loadingStudent
              ? const Center(child: CircularProgressIndicator())
              : switch (_section) {
                  1 => _academicsView(),
                  2 => _financeView(),
                  _ => _overviewView(),
                },
        ),
      ],
    );
  }

  Widget _studentHeader() {
    final student = _selectedStudent!;
    return Container(
      width: double.infinity,
      color: _navy,
      padding: const EdgeInsets.fromLTRB(26, 22, 26, 22),
      child: Wrap(
        spacing: 22,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: _indigo,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: Center(
              child: Text(
                _initials(student['full_name']),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _text(student['full_name'], 'Student'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _identityChip(
                      Icons.badge_outlined,
                      _text(student['uni_id'], 'Uni-ID pending'),
                    ),
                    _identityChip(Icons.verified_outlined, 'Active'),
                  ],
                ),
              ],
            ),
          ),
          _headerFact(
            Icons.menu_book_outlined,
            'Programme',
            student['programme'],
          ),
          _headerFact(
            Icons.layers_outlined,
            'Semester',
            student['current_semester'],
          ),
          _headerFact(
            Icons.calendar_today_outlined,
            'Session',
            student['academic_session'],
          ),
        ],
      ),
    );
  }

  Widget _identityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFC7D2FE)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _workspaceTabs() {
    const tabs = [
      (Icons.grid_view_outlined, 'Overview'),
      (Icons.school_outlined, 'Academics'),
      (Icons.account_balance_wallet_outlined, 'Finance'),
    ];
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final selected = _section == index;
            return InkWell(
              onTap: () => setState(() => _section = index),
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? _indigo : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      tabs[index].$1,
                      size: 18,
                      color: selected ? _indigo : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tabs[index].$2,
                      style: TextStyle(
                        color: selected ? _navy : const Color(0xFF64748B),
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _headerFact(IconData icon, String label, Object? value) {
    return Container(
      width: 158,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: const Color(0xFFA5B4FC)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _text(value, 'Not set'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overviewView() {
    final held = _attendance.fold<int>(
      0,
      (sum, item) => sum + (_id(item['classes_held']) ?? 0),
    );
    final outstanding = _invoices.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['outstanding_amount'] as num?)?.toDouble() ?? 0),
    );

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        _sectionTitle(
          'Setup progress',
          'Live records connected to this student',
          Icons.checklist_outlined,
        ),
        const SizedBox(height: 12),
        _progressStrip(),
        const SizedBox(height: 22),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _metric(
              'Active courses',
              '${_activeEnrollments.length}',
              _navy,
              Icons.menu_book_outlined,
            ),
            _metric(
              'Weekly classes',
              '${_timetable.length}',
              _teal,
              Icons.calendar_view_week_outlined,
            ),
            _metric(
              'Attendance sessions',
              '$held',
              _amber,
              Icons.fact_check_outlined,
            ),
            _metric(
              'Outstanding fee',
              _money(outstanding),
              _coral,
              Icons.receipt_long_outlined,
            ),
          ],
        ),
        const SizedBox(height: 26),
        _sectionTitle(
          'Next actions',
          'Complete the student record without leaving this workspace',
          Icons.bolt_outlined,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionButton(
              'Create course',
              Icons.library_add_outlined,
              _indigo,
              _showCreateCourseDialog,
              subtitle: 'Add a subject to the catalogue',
            ),
            _actionButton(
              'Enroll course',
              Icons.add_task_outlined,
              _teal,
              _showEnrollDialog,
              subtitle: 'Assign an existing offering',
            ),
            _actionButton(
              'Create & enroll offering',
              Icons.auto_awesome_motion_outlined,
              _navy,
              _showCreateOfferingDialog,
              subtitle: 'Set up and assign in one step',
            ),
            _actionButton(
              'Add timetable',
              Icons.edit_calendar_outlined,
              _amber,
              _showTimetableDialog,
              subtitle: 'Schedule the weekly class',
            ),
            _actionButton(
              'Record attendance',
              Icons.how_to_reg_outlined,
              _teal,
              _showAttendanceDialog,
              subtitle: 'Capture a completed session',
            ),
            _actionButton(
              'Schedule exam',
              Icons.assignment_add,
              _indigo,
              _showExamDialog,
              subtitle: 'Create a paper and registration',
            ),
            _actionButton(
              'Create invoice',
              Icons.post_add_outlined,
              _coral,
              _showInvoiceDialog,
              subtitle: 'Build a payable fee statement',
            ),
          ],
        ),
      ],
    );
  }

  Widget _academicsView() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        _sectionHeader(
          'Course enrollment',
          '${_activeEnrollments.length} active',
          [
            OutlinedButton.icon(
              onPressed: _showCreateCourseDialog,
              icon: const Icon(Icons.library_add_outlined, size: 18),
              label: const Text('New course'),
            ),
            OutlinedButton.icon(
              onPressed: _showCreateOfferingDialog,
              icon: const Icon(Icons.add_box_outlined, size: 18),
              label: const Text('Create offering'),
            ),
            FilledButton.icon(
              onPressed: _showEnrollDialog,
              icon: const Icon(Icons.add_task_outlined, size: 18),
              label: const Text('Enroll'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_enrollments.isEmpty)
          _emptyPanel(
            Icons.menu_book_outlined,
            'No courses enrolled',
            'Create or select an offering and enroll this student.',
            _courses.isEmpty ? 'Create course' : 'Enroll course',
            _courses.isEmpty ? _showCreateCourseDialog : _showEnrollDialog,
          )
        else
          ..._enrollments.map(_enrollmentRow),
        const SizedBox(height: 26),
        _sectionHeader('Weekly timetable', '${_timetable.length} classes', [
          FilledButton.icon(
            onPressed: _showTimetableDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add class'),
          ),
        ]),
        const SizedBox(height: 12),
        if (_timetable.isEmpty)
          _emptyPanel(
            Icons.calendar_view_week_outlined,
            'No timetable yet',
            'Timetable entries appear after the student is enrolled.',
            'Add class',
            _showTimetableDialog,
          )
        else
          _timetableTable(),
        const SizedBox(height: 26),
        _sectionHeader('Attendance', '${_attendance.length} course summaries', [
          FilledButton.icon(
            onPressed: _showAttendanceDialog,
            icon: const Icon(Icons.how_to_reg_outlined, size: 18),
            label: const Text('Record'),
          ),
        ]),
        const SizedBox(height: 12),
        if (_attendance.isEmpty)
          _emptyPanel(
            Icons.fact_check_outlined,
            'No attendance summary',
            'Record the first class session for this student.',
            'Record attendance',
            _showAttendanceDialog,
          )
        else
          ..._attendance.map(_attendanceRow),
        const SizedBox(height: 26),
        _sectionHeader(
          'Examinations',
          '${_studentExamRegistrations.length} registrations',
          [
            FilledButton.icon(
              onPressed: _showExamDialog,
              icon: const Icon(Icons.assignment_add, size: 18),
              label: const Text('Schedule & assign'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_studentExamRegistrations.isEmpty)
          _emptyPanel(
            Icons.assignment_outlined,
            'No examination assigned',
            'Create an examination paper and approve registration in one step.',
            'Schedule exam',
            _showExamDialog,
          )
        else
          ..._studentExamRegistrations.map(_examRow),
      ],
    );
  }

  Widget _financeView() {
    final outstanding = _invoices.fold<double>(
      0,
      (sum, item) =>
          sum + ((item['outstanding_amount'] as num?)?.toDouble() ?? 0),
    );
    final paid = _invoices.fold<double>(
      0,
      (sum, item) => sum + ((item['paid_amount'] as num?)?.toDouble() ?? 0),
    );
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _metric(
              'Invoices',
              '${_invoices.length}',
              _navy,
              Icons.receipt_long_outlined,
            ),
            _metric('Paid', _money(paid), _teal, Icons.task_alt_outlined),
            _metric(
              'Outstanding',
              _money(outstanding),
              _coral,
              Icons.pending_actions_outlined,
            ),
          ],
        ),
        const SizedBox(height: 26),
        _sectionHeader('Student invoices', 'Generated by the accounts office', [
          FilledButton.icon(
            onPressed: _showInvoiceDialog,
            icon: const Icon(Icons.post_add_outlined, size: 18),
            label: const Text('Create invoice'),
          ),
        ]),
        const SizedBox(height: 12),
        if (_invoices.isEmpty)
          _emptyPanel(
            Icons.receipt_long_outlined,
            'No invoices generated',
            'Create the first fee invoice for this student.',
            'Create invoice',
            _showInvoiceDialog,
          )
        else
          ..._invoices.map(_invoiceRow),
      ],
    );
  }

  Widget _progressStrip() {
    final steps = [
      ('Identity', true, Icons.badge_outlined),
      ('Courses', _activeEnrollments.isNotEmpty, Icons.menu_book_outlined),
      ('Timetable', _timetable.isNotEmpty, Icons.schedule_outlined),
      (
        'Attendance',
        _attendance.any((item) => (_id(item['classes_held']) ?? 0) > 0),
        Icons.fact_check_outlined,
      ),
      ('Fees', _invoices.isNotEmpty, Icons.receipt_long_outlined),
      (
        'Exams',
        _studentExamRegistrations.isNotEmpty,
        Icons.assignment_outlined,
      ),
    ];
    final completed = steps.where((step) => step.$2).length;
    final progress = completed / steps.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$completed of ${steps.length} areas connected',
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: _indigo,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              color: _indigo,
              backgroundColor: const Color(0xFFE8EAF3),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: steps.map((step) {
              final complete = step.$2;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: complete
                      ? const Color(0xFFEEF2FF)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: complete
                        ? const Color(0xFFC7D2FE)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      complete ? Icons.check_circle : step.$3,
                      size: 16,
                      color: complete ? _indigo : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      step.$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: complete ? _navy : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value, Color color, IconData icon) {
    return Container(
      width: 220,
      height: 106,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              Container(
                width: 22,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback action, {
    String? subtitle,
  }) {
    return SizedBox(
      width: 236,
      height: 92,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFE2E7EF)),
        ),
        child: InkWell(
          onTap: action,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(icon, size: 21, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10.5,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _navy, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF7A8699), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, String subtitle, List<Widget> actions) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 360,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF7A8699)),
              ),
            ],
          ),
        ),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }

  Widget _emptyPanel(
    IconData icon,
    String title,
    String message,
    String actionLabel,
    VoidCallback action,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF7A8699)),
          ),
          SizedBox(
            width: 390,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF344054),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF7A8699),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(onPressed: action, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _enrollmentRow(Map<String, dynamic> item) {
    final course = _course(_id(item['course_id']));
    final status = _text(item['enrollment_status'], 'unknown');
    return _recordRow(
      icon: Icons.menu_book_outlined,
      color: _navy,
      title: _text(
        item['course_name'] ?? course?['name'],
        'Course ${item['course_id'] ?? '-'}',
      ),
      subtitle:
          '${_text(item['course_code'] ?? course?['code'], 'No code')} | ${_semesterLabel(_id(item['semester_id']))} | ${_text(item['faculty_name'], 'Faculty not assigned')}',
      trailing: _statusBadge(status),
    );
  }

  Widget _timetableTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: Column(
        children: _timetable.map((item) {
          return _recordRow(
            icon: Icons.schedule_outlined,
            color: _teal,
            title: _text(
              item['course_name'] ?? _course(_id(item['course_id']))?['name'],
              'Scheduled class',
            ),
            subtitle:
                '${_dayName(_id(item['day_of_week']))} | ${item['start_time'] ?? '-'} - ${item['end_time'] ?? '-'} | ${_text(item['faculty_name'], 'Faculty not assigned')}',
            trailing: Text(
              _text(item['room'], 'Room TBD'),
              style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _attendanceRow(Map<String, dynamic> item) {
    final percentage = (item['attendance_percentage'] as num?)?.toDouble() ?? 0;
    final color = percentage >= 75
        ? _teal
        : percentage >= 60
        ? _amber
        : _coral;
    return _recordRow(
      icon: Icons.fact_check_outlined,
      color: color,
      title: _text(
        item['course_name'] ?? _course(_id(item['course_id']))?['name'],
        'Course ${item['course_id'] ?? '-'}',
      ),
      subtitle:
          '${item['classes_attended'] ?? 0} attended of ${item['classes_held'] ?? 0} sessions',
      trailing: Text(
        '${percentage.toStringAsFixed(1)}%',
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _examRow(Map<String, dynamic> registration) {
    final examId = _id(registration['examination_id']);
    final exam = _examinations.where((item) => _id(item['id']) == examId);
    return _recordRow(
      icon: Icons.assignment_turned_in_outlined,
      color: _navy,
      title: exam.isEmpty
          ? 'Examination ${examId ?? '-'}'
          : _text(exam.first['name'], 'Examination'),
      subtitle:
          'Registration ${_text(registration['registration_number'], '-')} | ${_text(registration['status'], 'registered')}',
      trailing: _statusBadge(_text(registration['status'], 'registered')),
    );
  }

  Widget _invoiceRow(Map<String, dynamic> item) {
    final status = _text(item['status'], 'pending');
    return _recordRow(
      icon: Icons.receipt_long_outlined,
      color: status.toLowerCase() == 'paid' ? _teal : _coral,
      title: _text(item['invoice_number'], 'Invoice'),
      subtitle:
          '${_text(item['academic_session'], 'Session')} | Semester ${item['semester'] ?? '-'} | Due ${_text(item['due_date'], 'not set')}',
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _money((item['outstanding_amount'] as num?)?.toDouble() ?? 0),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 3),
          _statusBadge(status),
        ],
      ),
    );
  }

  Widget _recordRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E7EF)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF253247),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7A8699),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();
    final positive = {
      'active',
      'enrolled',
      'approved',
      'paid',
      'good',
    }.contains(normalized);
    final color = positive ? _teal : _amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _showCreateCourseDialog() async {
    final code = TextEditingController();
    final name = TextEditingController();
    final credits = TextEditingController(text: '4');
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _operationDialog(
          icon: Icons.library_add_outlined,
          color: _navy,
          title: 'Create master course',
          subtitle: 'Add a reusable course for the selected department.',
          saving: saving,
          saveLabel: 'Create Course',
          onSave: () async {
            final parsedCredits = int.tryParse(credits.text.trim());
            if (code.text.trim().isEmpty ||
                name.text.trim().isEmpty ||
                parsedCredits == null ||
                parsedCredits < 0) {
              _message(
                'Enter a course code, name, and valid credits.',
                error: true,
              );
              return;
            }
            setDialogState(() => saving = true);
            try {
              await UniSphereApiService.createCourse(
                code: code.text.trim(),
                name: name.text.trim(),
                credits: parsedCredits,
                departmentId: _id(_selectedStudent?['department_id']),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _afterSave(
                'Course created. You can now create an offering.',
              );
            } on ApiException catch (error) {
              setDialogState(() => saving = false);
              _message(error.message, error: true);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _dialogField(
                      code,
                      'Course code',
                      Icons.tag_outlined,
                      hint: 'MSC101',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dialogField(
                      credits,
                      'Credits',
                      Icons.stars_outlined,
                      number: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _dialogField(
                name,
                'Course name',
                Icons.menu_book_outlined,
                hint: 'Foundations of Data Science',
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  'This course will be linked to the selected student\'s department.',
                  style: const TextStyle(
                    color: Color(0xFF526078),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    code.dispose();
    name.dispose();
    credits.dispose();
  }

  Future<void> _showEnrollDialog() async {
    final studentId = _id(_selectedStudent?['id']);
    if (studentId == null) return;
    final enrolledIds = _enrollments
        .map((item) => _id(item['course_offering_id']))
        .whereType<int>()
        .toSet();
    final available = _offerings
        .where(
          (item) =>
              item['is_active'] != false &&
              !enrolledIds.contains(_id(item['id'])),
        )
        .toList();
    if (available.isEmpty) {
      _message(
        'No available offerings. Create a new offering first.',
        error: true,
      );
      return;
    }
    int? offeringId = _id(available.first['id']);
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _operationDialog(
          icon: Icons.add_task_outlined,
          color: _teal,
          title: 'Enroll course',
          subtitle: 'Assign an active course offering to ${_studentName()}.',
          saving: saving,
          onSave: () async {
            if (offeringId == null) return;
            setDialogState(() => saving = true);
            try {
              await UniSphereApiService.enrollStudent(
                studentId: studentId,
                courseOfferingId: offeringId!,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _afterSave('Course enrolled successfully.');
            } on ApiException catch (error) {
              setDialogState(() => saving = false);
              _message(error.message, error: true);
            }
          },
          child: DropdownButtonFormField<int>(
            initialValue: offeringId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Course offering',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
            items: available
                .map(
                  (offering) => DropdownMenuItem<int>(
                    value: _id(offering['id']),
                    child: Text(
                      _offeringLabel(offering),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: saving ? null : (value) => offeringId = value,
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateOfferingDialog() async {
    if (_courses.isEmpty || _semesters.isEmpty) {
      _message(
        'Create at least one course and semester before making an offering.',
        error: true,
      );
      return;
    }
    final studentId = _id(_selectedStudent?['id']);
    if (studentId == null) return;
    final session = TextEditingController(
      text: _text(_selectedStudent?['academic_session'], ''),
    );
    final section = TextEditingController();
    final faculty = TextEditingController();
    final capacity = TextEditingController();
    int? courseId = _id(_courses.first['id']);
    int? semesterId = _matchingSemesterId() ?? _id(_semesters.first['id']);
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _operationDialog(
          icon: Icons.auto_awesome_motion_outlined,
          color: _navy,
          title: 'Create and enroll offering',
          subtitle:
              'Set up a course delivery and enroll ${_studentName()} immediately.',
          saving: saving,
          saveLabel: 'Create & Enroll',
          onSave: () async {
            if (courseId == null ||
                semesterId == null ||
                session.text.trim().isEmpty) {
              _message(
                'Course, semester, and academic session are required.',
                error: true,
              );
              return;
            }
            setDialogState(() => saving = true);
            try {
              final offering = await UniSphereApiService.createCourseOffering(
                courseId: courseId!,
                semesterId: semesterId!,
                academicSession: session.text.trim(),
                section: _optional(section.text),
                facultyName: _optional(faculty.text),
                capacity: int.tryParse(capacity.text.trim()),
              );
              await UniSphereApiService.enrollStudent(
                studentId: studentId,
                courseOfferingId: _id(offering['id'])!,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _afterSave('Offering created and student enrolled.');
            } on ApiException catch (error) {
              setDialogState(() => saving = false);
              _message(error.message, error: true);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: courseId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Course',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                items: _courses
                    .map(
                      (course) => DropdownMenuItem<int>(
                        value: _id(course['id']),
                        child: Text(
                          '${_text(course['code'], '-')} - ${_text(course['name'], 'Course')}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: saving ? null : (value) => courseId = value,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: semesterId,
                decoration: const InputDecoration(
                  labelText: 'Semester',
                  prefixIcon: Icon(Icons.layers_outlined),
                ),
                items: _semesters
                    .map(
                      (semester) => DropdownMenuItem<int>(
                        value: _id(semester['id']),
                        child: Text(_semesterLabel(_id(semester['id']))),
                      ),
                    )
                    .toList(),
                onChanged: saving ? null : (value) => semesterId = value,
              ),
              const SizedBox(height: 12),
              _dialogField(
                session,
                'Academic session',
                Icons.calendar_today_outlined,
                hint: '2026-27',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dialogField(
                      section,
                      'Section',
                      Icons.view_column_outlined,
                      hint: 'A',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dialogField(
                      capacity,
                      'Capacity',
                      Icons.groups_outlined,
                      hint: '60',
                      number: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _dialogField(
                faculty,
                'Faculty name',
                Icons.person_outline,
                hint: 'Assigned instructor',
              ),
            ],
          ),
        ),
      ),
    );
    session.dispose();
    section.dispose();
    faculty.dispose();
    capacity.dispose();
  }

  Future<void> _showTimetableDialog() async {
    if (_activeEnrollments.isEmpty) {
      _message('Enroll the student in a course first.', error: true);
      return;
    }
    int? offeringId = _id(_activeEnrollments.first['course_offering_id']);
    int day = 1;
    String start = '09:00';
    String end = '10:00';
    final room = TextEditingController();
    final building = TextEditingController();
    final faculty = TextEditingController(
      text: _text(_activeEnrollments.first['faculty_name'], ''),
    );
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _operationDialog(
          icon: Icons.edit_calendar_outlined,
          color: _amber,
          title: 'Add timetable entry',
          subtitle: 'Schedule a class for an enrolled course.',
          saving: saving,
          onSave: () async {
            if (offeringId == null || start.compareTo(end) >= 0) {
              _message('Choose a valid course and time range.', error: true);
              return;
            }
            setDialogState(() => saving = true);
            try {
              await UniSphereApiService.createTimetableEntry(
                courseOfferingId: offeringId!,
                dayOfWeek: day,
                startTime: start,
                endTime: end,
                room: _optional(room.text),
                building: _optional(building.text),
                facultyName: _optional(faculty.text),
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _afterSave('Timetable entry added.');
            } on ApiException catch (error) {
              setDialogState(() => saving = false);
              _message(error.message, error: true);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: offeringId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Enrolled course',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                items: _activeEnrollments
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: _id(item['course_offering_id']),
                        child: Text(
                          _enrollmentLabel(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) => setDialogState(() => offeringId = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: day,
                decoration: const InputDecoration(
                  labelText: 'Day',
                  prefixIcon: Icon(Icons.today_outlined),
                ),
                items: List.generate(
                  7,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text(_dayName(index + 1)),
                  ),
                ),
                onChanged: saving
                    ? null
                    : (value) => setDialogState(() => day = value ?? 1),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _timeDropdown(
                      'Starts',
                      start,
                      (value) => setDialogState(() => start = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeDropdown(
                      'Ends',
                      end,
                      (value) => setDialogState(() => end = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dialogField(
                      room,
                      'Room',
                      Icons.meeting_room_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dialogField(
                      building,
                      'Building',
                      Icons.apartment_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _dialogField(faculty, 'Faculty', Icons.person_outline),
            ],
          ),
        ),
      ),
    );
    room.dispose();
    building.dispose();
    faculty.dispose();
  }

  Future<void> _showAttendanceDialog() async {
    if (_activeEnrollments.isEmpty) {
      _message('Enroll the student in a course first.', error: true);
      return;
    }
    int? offeringId = _id(_activeEnrollments.first['course_offering_id']);
    final date = TextEditingController(text: _date(DateTime.now()));
    final topic = TextEditingController();
    final faculty = TextEditingController(
      text: _text(_activeEnrollments.first['faculty_name'], ''),
    );
    final remarks = TextEditingController();
    String attendanceStatus = 'Present';
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _operationDialog(
          icon: Icons.how_to_reg_outlined,
          color: _teal,
          title: 'Record attendance',
          subtitle:
              'Create a class session and mark ${_studentName()} in one step.',
          saving: saving,
          onSave: () async {
            if (offeringId == null) return;
            setDialogState(() => saving = true);
            try {
              final session = await UniSphereApiService.createAttendanceSession(
                courseOfferingId: offeringId!,
                sessionDate: date.text,
                topic: _optional(topic.text),
                facultyName: _optional(faculty.text),
              );
              await UniSphereApiService.recordAttendanceBulk(
                sessionId: _id(session['id'])!,
                records: [
                  {
                    'student_id': _id(_selectedStudent?['id']),
                    'status': attendanceStatus,
                    'remarks': _optional(remarks.text),
                  },
                ],
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _afterSave('Attendance recorded.');
            } on ApiException catch (error) {
              setDialogState(() => saving = false);
              _message(error.message, error: true);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                initialValue: offeringId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Course session',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                items: _activeEnrollments
                    .map(
                      (item) => DropdownMenuItem<int>(
                        value: _id(item['course_offering_id']),
                        child: Text(
                          _enrollmentLabel(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: saving ? null : (value) => offeringId = value,
              ),
              const SizedBox(height: 12),
              _dateField(dialogContext, date, 'Session date'),
              const SizedBox(height: 12),
              _dialogField(topic, 'Topic', Icons.subject_outlined),
              const SizedBox(height: 12),
              _dialogField(faculty, 'Faculty', Icons.person_outline),
              const SizedBox(height: 16),
              const Text(
                'Attendance status',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF344054),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'Present', label: Text('Present')),
                    ButtonSegment(value: 'Absent', label: Text('Absent')),
                    ButtonSegment(value: 'Late', label: Text('Late')),
                    ButtonSegment(value: 'Excused', label: Text('Excused')),
                  ],
                  selected: {attendanceStatus},
                  onSelectionChanged: saving
                      ? null
                      : (value) => setDialogState(
                          () => attendanceStatus = value.first,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              _dialogField(remarks, 'Remarks', Icons.notes_outlined),
            ],
          ),
        ),
      ),
    );
    date.dispose();
    topic.dispose();
    faculty.dispose();
    remarks.dispose();
  }

  Future<void> _showExamDialog() async {
    if (_activeEnrollments.isEmpty || _semesters.isEmpty) {
      _message('Enroll the student and create a semester first.', error: true);
      return;
    }
    int? enrollmentIndex = 0;
    int? semesterId = _matchingSemesterId() ?? _id(_semesters.first['id']);
    final name = TextEditingController();
    final session = TextEditingController(
      text: _text(_selectedStudent?['academic_session'], ''),
    );
    final date = TextEditingController(text: _date(DateTime.now()));
    final room = TextEditingController();
    final building = TextEditingController();
    final maxMarks = TextEditingController(text: '100');
    final passingMarks = TextEditingController(text: '40');
    String type = 'semester';
    String start = '10:00';
    String end = '13:00';
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _operationDialog(
          icon: Icons.assignment_add,
          color: _navy,
          title: 'Schedule and assign exam',
          subtitle:
              'Create an exam paper and approve ${_studentName()} automatically.',
          saving: saving,
          saveLabel: 'Schedule & Assign',
          onSave: () async {
            final enrollment = _activeEnrollments[enrollmentIndex ?? 0];
            if (name.text.trim().isEmpty ||
                session.text.trim().isEmpty ||
                semesterId == null ||
                start.compareTo(end) >= 0) {
              _message('Complete the required exam details.', error: true);
              return;
            }
            setDialogState(() => saving = true);
            try {
              final exam = await UniSphereApiService.createExamination(
                name: name.text.trim(),
                examType: type,
                academicSession: session.text.trim(),
                semesterId: semesterId!,
                startDate: date.text,
                endDate: date.text,
              );
              final schedule =
                  await UniSphereApiService.createExaminationSchedule(
                    examinationId: _id(exam['id'])!,
                    courseId: _id(enrollment['course_id'])!,
                    examDate: date.text,
                    startTime: start,
                    endTime: end,
                    room: _optional(room.text),
                    building: _optional(building.text),
                    maxMarks: int.tryParse(maxMarks.text) ?? 100,
                    passingMarks: int.tryParse(passingMarks.text) ?? 40,
                  );
              await UniSphereApiService.registerStudentForExamination(
                studentId: _id(_selectedStudent?['id'])!,
                examinationId: _id(exam['id'])!,
                scheduleIds: [_id(schedule['id'])!],
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _afterSave('Examination scheduled and assigned.');
            } on ApiException catch (error) {
              setDialogState(() => saving = false);
              _message(error.message, error: true);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(
                name,
                'Examination name',
                Icons.assignment_outlined,
                hint: 'Mid Semester Examination',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: enrollmentIndex,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Course paper',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
                items: List.generate(
                  _activeEnrollments.length,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text(
                      _enrollmentLabel(_activeEnrollments[index]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                onChanged: saving ? null : (value) => enrollmentIndex = value,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Exam type',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'semester',
                          child: Text('Semester'),
                        ),
                        DropdownMenuItem(
                          value: 'midterm',
                          child: Text('Midterm'),
                        ),
                        DropdownMenuItem(
                          value: 'internal',
                          child: Text('Internal'),
                        ),
                        DropdownMenuItem(
                          value: 'practical',
                          child: Text('Practical'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) => type = value ?? 'semester',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: semesterId,
                      decoration: const InputDecoration(
                        labelText: 'Semester',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                      items: _semesters
                          .map(
                            (semester) => DropdownMenuItem<int>(
                              value: _id(semester['id']),
                              child: Text(_semesterLabel(_id(semester['id']))),
                            ),
                          )
                          .toList(),
                      onChanged: saving ? null : (value) => semesterId = value,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _dialogField(
                session,
                'Academic session',
                Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 12),
              _dateField(dialogContext, date, 'Examination date'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _timeDropdown(
                      'Starts',
                      start,
                      (value) => setDialogState(() => start = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeDropdown(
                      'Ends',
                      end,
                      (value) => setDialogState(() => end = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dialogField(
                      room,
                      'Room',
                      Icons.meeting_room_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dialogField(
                      building,
                      'Building',
                      Icons.apartment_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _dialogField(
                      maxMarks,
                      'Maximum marks',
                      Icons.score_outlined,
                      number: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dialogField(
                      passingMarks,
                      'Passing marks',
                      Icons.task_alt_outlined,
                      number: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    name.dispose();
    session.dispose();
    date.dispose();
    room.dispose();
    building.dispose();
    maxMarks.dispose();
    passingMarks.dispose();
  }

  Future<void> _showInvoiceDialog() async {
    final studentId = _id(_selectedStudent?['id']);
    if (studentId == null) return;
    final session = TextEditingController(
      text: _text(
        _selectedStudent?['academic_session'],
        _defaultAcademicSession(),
      ),
    );
    final dueDate = TextEditingController(
      text: _date(DateTime.now().add(const Duration(days: 30))),
    );
    final lines = <_InvoiceLineDraft>[_InvoiceLineDraft()];
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _operationDialog(
          icon: Icons.post_add_outlined,
          color: _coral,
          title: 'Create student invoice',
          subtitle: 'Generate a payable fee record for ${_studentName()}.',
          saving: saving,
          saveLabel: 'Generate invoice',
          onSave: () async {
            final invoiceItems = <Map<String, dynamic>>[];
            for (final line in lines) {
              final parsedAmount = double.tryParse(line.amount.text.trim());
              if (parsedAmount == null || parsedAmount <= 0) {
                _message(
                  'Every invoice item needs a valid amount greater than zero.',
                  error: true,
                );
                return;
              }
              invoiceItems.add({
                'fee_type': line.feeType,
                'description': _optional(line.description.text),
                'amount': parsedAmount,
              });
            }
            if (session.text.trim().isEmpty) {
              _message('Enter the academic session.', error: true);
              return;
            }
            setDialogState(() => saving = true);
            try {
              await UniSphereApiService.createInvoice(
                studentId: studentId,
                academicSession: session.text.trim(),
                semester: _id(_selectedStudent?['current_semester']) ?? 1,
                dueDate: _optional(dueDate.text),
                items: invoiceItems,
              );
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              await _afterSave('Invoice created successfully.');
            } on ApiException catch (error) {
              setDialogState(() => saving = false);
              _message(error.message, error: true);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _formSectionLabel(
                'Invoice items',
                'Add one or more charges to this statement.',
              ),
              const SizedBox(height: 12),
              ...lines.asMap().entries.map((entry) {
                final index = entry.key;
                final line = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E7FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: _indigo,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Text(
                              'Fee line',
                              style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (lines.length > 1)
                            IconButton(
                              tooltip: 'Remove fee line',
                              onPressed: saving
                                  ? null
                                  : () {
                                      setDialogState(() {
                                        lines.removeAt(index).dispose();
                                      });
                                    },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: _coral,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: line.feeType,
                              decoration: const InputDecoration(
                                labelText: 'Fee type',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: _feeTypes
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    ),
                                  )
                                  .toList(),
                              onChanged: saving
                                  ? null
                                  : (value) => setDialogState(
                                      () => line.feeType = value ?? 'Tuition',
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dialogField(
                              line.amount,
                              'Amount',
                              Icons.currency_rupee,
                              number: true,
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _dialogField(
                        line.description,
                        'Description',
                        Icons.notes_outlined,
                        hint: 'What is this charge for?',
                      ),
                    ],
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: saving
                    ? null
                    : () =>
                          setDialogState(() => lines.add(_InvoiceLineDraft())),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add another fee'),
              ),
              const SizedBox(height: 24),
              _formSectionLabel(
                'Billing details',
                'Confirm the period and payment deadline.',
              ),
              const SizedBox(height: 12),
              _dialogField(
                session,
                'Academic session',
                Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 12),
              _dateField(dialogContext, dueDate, 'Payment due date'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: _indigo),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${lines.length} fee ${lines.length == 1 ? 'item' : 'items'} | Semester ${_selectedStudent?['current_semester'] ?? 1}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Invoice total',
                            style: TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _money(
                        lines.fold<double>(
                          0,
                          (total, line) =>
                              total +
                              (double.tryParse(line.amount.text.trim()) ?? 0),
                        ),
                      ),
                      style: const TextStyle(
                        color: _indigo,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    session.dispose();
    dueDate.dispose();
    for (final line in lines) {
      line.dispose();
    }
  }

  Widget _formSectionLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
      ],
    );
  }

  Widget _operationDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget child,
    required bool saving,
    required Future<void> Function() onSave,
    String saveLabel = 'Save',
  }) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 820),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(22, 20, 14, 20),
              color: _navy,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STUDENT 360  /  ${_studentName().toUpperCase()}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: child,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E7EF))),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 7),
                  const Expanded(
                    child: Text(
                      'Changes are saved to the live student record.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: saving ? null : onSave,
                    style: FilledButton.styleFrom(backgroundColor: _indigo),
                    icon: saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(saving ? 'Saving...' : saveLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    bool number = false,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      onChanged: onChanged,
    );
  }

  Widget _dateField(
    BuildContext dialogContext,
    TextEditingController controller,
    String label, {
    bool optional = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: optional ? 'Optional' : null,
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear date',
                onPressed: () => controller.clear(),
                icon: const Icon(Icons.clear, size: 18),
              ),
      ),
      onTap: () async {
        final selected = await showDatePicker(
          context: dialogContext,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
          initialDate: DateTime.tryParse(controller.text) ?? DateTime.now(),
        );
        if (selected != null) controller.text = _date(selected);
      },
    );
  }

  Widget _timeDropdown(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.schedule_outlined),
      ),
      items: _timeSlots
          .map((time) => DropdownMenuItem(value: time, child: Text(time)))
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44, color: _coral),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _loadWorkspace,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _afterSave(String message) async {
    _message(message);
    await _loadWorkspace();
  }

  void _message(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: error ? _coral : _teal),
    );
  }

  Map<String, dynamic>? _course(int? id) {
    final matches = _courses.where((item) => _id(item['id']) == id);
    return matches.isEmpty ? null : matches.first;
  }

  String _offeringLabel(Map<String, dynamic> offering) {
    final course = _course(_id(offering['course_id']));
    return '${_text(course?['code'], 'Course')} - ${_text(course?['name'], 'Offering')} | ${_semesterLabel(_id(offering['semester_id']))}';
  }

  String _enrollmentLabel(Map<String, dynamic> enrollment) {
    final course = _course(_id(enrollment['course_id']));
    return '${_text(enrollment['course_code'] ?? course?['code'], 'Course')} - ${_text(enrollment['course_name'] ?? course?['name'], 'Enrolled course')}';
  }

  String _semesterLabel(int? id) {
    final matches = _semesters.where((item) => _id(item['id']) == id);
    if (matches.isEmpty) return 'Semester ${id ?? '-'}';
    final semester = matches.first;
    return _text(
      semester['name'],
      'Semester ${semester['number'] ?? id ?? '-'}',
    );
  }

  int? _matchingSemesterId() {
    final current = _id(_selectedStudent?['current_semester']);
    final matches = _semesters.where((item) => _id(item['number']) == current);
    return matches.isEmpty ? null : _id(matches.first['id']);
  }

  String _studentName() =>
      _text(_selectedStudent?['full_name'], 'this student');

  String _defaultAcademicSession() {
    final now = DateTime.now();
    final startYear = now.month >= 7 ? now.year : now.year - 1;
    final endYear = (startYear + 1).toString().substring(2);
    return '$startYear-$endYear';
  }

  static List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static int? _id(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _optional(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  static String _initials(Object? value) {
    final parts = value
        ?.toString()
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts == null || parts.isEmpty) return '--';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _label(String value) {
    return value
        .split('_')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  static String _dayName(int? day) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    if (day == null || day < 1 || day > 7) return 'Day not set';
    return days[day - 1];
  }

  static String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _money(double value) => 'INR ${value.toStringAsFixed(2)}';

  static const _feeTypes = [
    'Tuition',
    'Examination',
    'Transport',
    'Hostel',
    'Library',
    'Other',
  ];

  static const _timeSlots = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
  ];
}

class _InvoiceLineDraft {
  _InvoiceLineDraft();

  String feeType = 'Tuition';
  final TextEditingController description = TextEditingController();
  final TextEditingController amount = TextEditingController();

  void dispose() {
    description.dispose();
    amount.dispose();
  }
}
