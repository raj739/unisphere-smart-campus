import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<Map<String, dynamic>> _students = const [];
  List<Map<String, dynamic>> _departments = const [];
  List<Map<String, dynamic>> _programmes = const [];
  List<Map<String, dynamic>> _curricula = const [];
  List<Map<String, dynamic>> _academicSessions = const [];
  String _query = '';
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        UniSphereApiService.getAdminStudents(),
        UniSphereApiService.getDepartments(),
        UniSphereApiService.getProgrammes(),
        UniSphereApiService.getCurricula(),
        UniSphereApiService.getAcademicSessions(),
      ]);
      final data = results[0] as List<dynamic>;
      final departments = results[1] as List<Map<String, dynamic>>;
      final programmes = results[2] as List<Map<String, dynamic>>;
      if (!mounted) return;
      setState(() {
        _students = data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _departments = departments;
        _programmes = programmes;
        _curricula = List<Map<String, dynamic>>.from(results[3] as List);
        _academicSessions = List<Map<String, dynamic>>.from(results[4] as List);
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load students.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  Future<void> _showRegistrationDialog() async {
    if (_departments.isEmpty || _programmes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Import or create programmes and departments before registering a student.',
          ),
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final fullName = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final universityId = TextEditingController();
    final enrollment = TextEditingController();
    int? programmeId = _programmes.first['id'] as int;
    int? departmentId = _programmes.first['department_id'] as int;
    final initialSpecializations = _specializationsFor(programmeId);
    int? specializationId = initialSpecializations.isEmpty
        ? null
        : initialSpecializations.first['id'] as int;
    var availableCurricula = _curriculaFor(programmeId, specializationId);
    int? curriculumId = availableCurricula.firstOrNull?['id'] as int?;
    int? academicSessionId =
        _academicSessions
                .where((item) => item['is_active'] == true)
                .firstOrNull?['id']
            as int? ??
        _academicSessions.firstOrNull?['id'] as int?;
    int semester = 1;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Register Student'),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(fullName, 'Full name'),
                    _field(
                      email,
                      'University email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _field(password, 'Temporary password', obscureText: true),
                    DropdownButtonFormField<int>(
                      initialValue: programmeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Programme',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: _programmes
                          .map(
                            (item) => DropdownMenuItem<int>(
                              value: item['id'] as int,
                              child: Text(
                                '[${item['category'] ?? 'Programme'}] ${item['name']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: submitting
                          ? null
                          : (value) {
                              final selected = _programme(value);
                              final options = _specializationsFor(value);
                              setDialogState(() {
                                programmeId = value;
                                departmentId =
                                    selected?['department_id'] as int?;
                                specializationId = options.isEmpty
                                    ? null
                                    : options.first['id'] as int;
                                availableCurricula = _curriculaFor(
                                  programmeId,
                                  specializationId,
                                );
                                curriculumId =
                                    availableCurricula.firstOrNull?['id']
                                        as int?;
                                semester = 1;
                              });
                            },
                      validator: (value) =>
                          value == null ? 'Select a programme' : null,
                    ),
                    const SizedBox(height: 12),
                    if (_specializationsFor(programmeId).isNotEmpty) ...[
                      DropdownButtonFormField<int>(
                        key: ValueKey(programmeId),
                        initialValue: specializationId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Subject / specialization',
                          prefixIcon: Icon(Icons.account_tree_outlined),
                        ),
                        items: _specializationsFor(programmeId)
                            .map(
                              (item) => DropdownMenuItem<int>(
                                value: item['id'] as int,
                                child: Text(
                                  item['name']?.toString() ?? 'Specialization',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: submitting
                            ? null
                            : (value) => setDialogState(() {
                                specializationId = value;
                                availableCurricula = _curriculaFor(
                                  programmeId,
                                  specializationId,
                                );
                                curriculumId =
                                    availableCurricula.firstOrNull?['id']
                                        as int?;
                                semester = 1;
                              }),
                        validator: (value) => value == null
                            ? 'Select a subject or specialization'
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    DropdownButtonFormField<int>(
                      key: ValueKey(
                        'curriculum-$programmeId-$specializationId',
                      ),
                      initialValue: curriculumId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Curriculum',
                        prefixIcon: Icon(Icons.library_books_outlined),
                      ),
                      items: availableCurricula
                          .map(
                            (item) => DropdownMenuItem<int>(
                              value: item['id'] as int,
                              child: Text(
                                '${item['version']} | ${item['course_count']} papers',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: submitting
                          ? null
                          : (value) => setDialogState(() {
                              curriculumId = value;
                              semester = 1;
                            }),
                      validator: (value) =>
                          value == null ? 'Select a curriculum' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: academicSessionId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Academic session',
                        prefixIcon: Icon(Icons.calendar_month_outlined),
                      ),
                      items: _academicSessions
                          .map(
                            (item) => DropdownMenuItem<int>(
                              value: item['id'] as int,
                              child: Text(
                                '${item['name']}${item['is_active'] == true ? ' (Active)' : ''}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: submitting
                          ? null
                          : (value) =>
                                setDialogState(() => academicSessionId = value),
                      validator: (value) =>
                          value == null ? 'Select an academic session' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      key: ValueKey('department-$departmentId'),
                      initialValue: departmentId,
                      decoration: const InputDecoration(
                        labelText: 'Owning department',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                      items: _departments
                          .map(
                            (department) => DropdownMenuItem<int>(
                              value: department['id'] as int,
                              child: Text(
                                department['name']?.toString() ?? 'Department',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      key: ValueKey('semester-$programmeId'),
                      initialValue: semester,
                      decoration: const InputDecoration(
                        labelText: 'Current semester',
                      ),
                      items:
                          List.generate(
                                ((_programme(programmeId)?['duration_years']
                                            as int?) ??
                                        3) *
                                    2,
                                (index) => index + 1,
                              )
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text('Semester $value'),
                                ),
                              )
                              .toList(),
                      onChanged: submitting
                          ? null
                          : (value) =>
                                setDialogState(() => semester = value ?? 1),
                    ),
                    _field(
                      universityId,
                      'University ID (optional)',
                      required: false,
                    ),
                    _field(
                      enrollment,
                      'Enrollment number (optional)',
                      required: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate() ||
                          departmentId == null ||
                          programmeId == null ||
                          curriculumId == null ||
                          academicSessionId == null) {
                        return;
                      }
                      final selectedProgramme = _programme(programmeId)!;
                      final selectedSpecialization = _specialization(
                        programmeId,
                        specializationId,
                      );
                      final programmeLabel =
                          selectedSpecialization == null ||
                              selectedSpecialization['name'] == 'Plain'
                          ? selectedProgramme['name'].toString()
                          : '${selectedProgramme['name']} - ${selectedSpecialization['name']}';
                      setDialogState(() => submitting = true);
                      try {
                        final academicSession = _academicSessions
                            .where((item) => item['id'] == academicSessionId)
                            .first;
                        final registration =
                            await UniSphereApiService.registerStudent(
                              fullName: fullName.text.trim(),
                              email: email.text.trim(),
                              password: password.text,
                              departmentId: departmentId!,
                              programme: programmeLabel,
                              currentSemester: semester,
                              universityId: _optional(universityId.text),
                              enrollmentNumber: _optional(enrollment.text),
                              academicSession: academicSession['name']
                                  ?.toString(),
                            );
                        await UniSphereApiService.assignStudentAcademicPlan(
                          studentId: registration['student_id'] as int,
                          programmeId: programmeId!,
                          specializationId: specializationId,
                          curriculumId: curriculumId!,
                          academicSessionId: academicSessionId!,
                          currentSemester: semester,
                          createStandardTimetable: true,
                          createFeeInvoice: true,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _loadStudents();
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Student registered successfully.'),
                            ),
                          );
                        }
                      } on ApiException catch (error) {
                        setDialogState(() => submitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      } catch (_) {
                        setDialogState(() => submitting = false);
                        if (mounted) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to register student.'),
                            ),
                          );
                        }
                      }
                    },
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(submitting ? 'Registering...' : 'Register'),
            ),
          ],
        ),
      ),
    );

    fullName.dispose();
    email.dispose();
    password.dispose();
    universityId.dispose();
    enrollment.dispose();
  }

  static String? _optional(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Map<String, dynamic>? _programme(int? id) {
    for (final programme in _programmes) {
      if (programme['id'] == id) return programme;
    }
    return null;
  }

  List<Map<String, dynamic>> _specializationsFor(int? programmeId) {
    final values = _programme(programmeId)?['specializations'];
    if (values is! List) return const [];
    return values
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item['is_active'] != false)
        .toList();
  }

  Map<String, dynamic>? _specialization(
    int? programmeId,
    int? specializationId,
  ) {
    for (final item in _specializationsFor(programmeId)) {
      if (item['id'] == specializationId) return item;
    }
    return null;
  }

  List<Map<String, dynamic>> _curriculaFor(
    int? programmeId,
    int? specializationId,
  ) => _curricula.where((item) {
    if (item['programme_id'] != programmeId) return false;
    return item['specialization_id'] == specializationId;
  }).toList();

  static Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
                ? '$label is required'
                : null
          : null,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStudents,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Students',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh students',
                    onPressed: _loading ? null : _loadStudents,
                    icon: const Icon(Icons.refresh),
                  ),
                  FilledButton.icon(
                    onPressed: _loading ? null : _showRegistrationDialog,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Register Student'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText:
                      'Search by name, Uni-ID, programme, or enrollment number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                _ErrorState(message: _error!, onRetry: _loadStudents)
              else if (_filteredStudents.isEmpty)
                const _EmptyState(
                  message: 'No students match the current search.',
                )
              else
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Student')),
                        DataColumn(label: Text('Uni-ID')),
                        DataColumn(label: Text('Programme')),
                        DataColumn(label: Text('Semester')),
                        DataColumn(label: Text('Enrollment')),
                      ],
                      rows: _filteredStudents
                          .map(
                            (student) => DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    student['full_name']?.toString() ??
                                        'Unknown',
                                  ),
                                ),
                                DataCell(
                                  Text(student['uni_id']?.toString() ?? '-'),
                                ),
                                DataCell(
                                  Text(student['programme']?.toString() ?? '-'),
                                ),
                                DataCell(
                                  Text(
                                    student['current_semester']?.toString() ??
                                        '-',
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    student['enrollment_number']?.toString() ??
                                        '-',
                                  ),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(40),
    child: Center(child: Text(message, textAlign: TextAlign.center)),
  );
}
