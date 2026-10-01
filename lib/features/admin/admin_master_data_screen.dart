import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

enum MasterDataType { university, department, programme, academicSession }

class AdminMasterDataScreen extends StatefulWidget {
  const AdminMasterDataScreen({super.key, required this.type});

  final MasterDataType type;

  @override
  State<AdminMasterDataScreen> createState() => _AdminMasterDataScreenState();
}

class _AdminMasterDataScreenState extends State<AdminMasterDataScreen> {
  List<Map<String, dynamic>> _records = const [];
  List<Map<String, dynamic>> _universities = const [];
  List<Map<String, dynamic>> _departments = const [];
  List<Map<String, dynamic>> _students = const [];
  List<Map<String, dynamic>> _programmes = const [];
  String _query = '';
  String? _error;
  bool _loading = true;

  String get _title => switch (widget.type) {
    MasterDataType.university => 'Universities',
    MasterDataType.department => 'Departments',
    MasterDataType.programme => 'Programmes',
    MasterDataType.academicSession => 'Academic Sessions',
  };

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
      final results = await Future.wait<dynamic>([
        switch (widget.type) {
          MasterDataType.university => UniSphereApiService.getUniversities(),
          MasterDataType.department => UniSphereApiService.getDepartments(),
          MasterDataType.programme => UniSphereApiService.getProgrammes(),
          MasterDataType.academicSession =>
            UniSphereApiService.getAcademicSessions(),
        },
        UniSphereApiService.getUniversities(),
        UniSphereApiService.getDepartments(),
        UniSphereApiService.getAdminStudents(),
        UniSphereApiService.getProgrammes(),
      ]);
      if (!mounted) return;
      setState(() {
        _records = List<Map<String, dynamic>>.from(results[0] as List);
        _universities = List<Map<String, dynamic>>.from(results[1] as List);
        _departments = List<Map<String, dynamic>>.from(results[2] as List);
        _students = (results[3] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _programmes = List<Map<String, dynamic>>.from(results[4] as List);
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load ${_title.toLowerCase()}.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered => _records.where((record) {
    final query = _query.trim().toLowerCase();
    return query.isEmpty ||
        record.values.any(
          (value) => value.toString().toLowerCase().contains(query),
        );
  }).toList();

  Future<void> _showCreateDialog() async {
    if (widget.type == MasterDataType.department && _universities.isEmpty) {
      _showMessage('Create a university before creating a department.');
      return;
    }
    if (widget.type == MasterDataType.programme && _departments.isEmpty) {
      _showMessage('Create a department before creating a programme.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final code = TextEditingController();
    final city = TextEditingController();
    final state = TextEditingController();
    final startYear = TextEditingController(
      text: DateTime.now().year.toString(),
    );
    final endYear = TextEditingController(
      text: (DateTime.now().year + 1).toString(),
    );
    int? universityId = _universities.isEmpty
        ? null
        : _universities.first['id'] as int;
    int? departmentId = _departments.isEmpty
        ? null
        : _departments.first['id'] as int;
    int duration = 3;
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Create ${_title.substring(0, _title.length - 1)}'),
          content: SizedBox(
            width: 460,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _formFields(
                    name: name,
                    code: code,
                    city: city,
                    state: state,
                    startYear: startYear,
                    endYear: endYear,
                    universityId: universityId,
                    departmentId: departmentId,
                    duration: duration,
                    saving: saving,
                    onUniversityChanged: (value) =>
                        setDialogState(() => universityId = value),
                    onDepartmentChanged: (value) =>
                        setDialogState(() => departmentId = value),
                    onDurationChanged: (value) =>
                        setDialogState(() => duration = value ?? duration),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      try {
                        await _create(
                          name: name.text.trim(),
                          code: code.text.trim(),
                          city: _optional(city.text),
                          state: _optional(state.text),
                          universityId: universityId,
                          departmentId: departmentId,
                          duration: duration,
                          startYear: int.parse(startYear.text),
                          endYear: int.parse(endYear.text),
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _load();
                        _showMessage('$_title updated successfully.');
                      } on ApiException catch (error) {
                        setDialogState(() => saving = false);
                        _showMessage(error.message);
                      } catch (_) {
                        setDialogState(() => saving = false);
                        _showMessage(
                          'Unable to create ${_title.toLowerCase()}.',
                        );
                      }
                    },
              icon: const Icon(Icons.add),
              label: Text(saving ? 'Saving...' : 'Create'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    code.dispose();
    city.dispose();
    state.dispose();
    startYear.dispose();
    endYear.dispose();
  }

  List<Widget> _formFields({
    required TextEditingController name,
    required TextEditingController code,
    required TextEditingController city,
    required TextEditingController state,
    required TextEditingController startYear,
    required TextEditingController endYear,
    required int? universityId,
    required int? departmentId,
    required int duration,
    required bool saving,
    required ValueChanged<int?> onUniversityChanged,
    required ValueChanged<int?> onDepartmentChanged,
    required ValueChanged<int?> onDurationChanged,
  }) {
    if (widget.type == MasterDataType.academicSession) {
      return [
        _field(name, 'Session name'),
        _field(startYear, 'Start year', numeric: true),
        _field(endYear, 'End year', numeric: true),
      ];
    }
    final fields = <Widget>[_field(name, 'Name'), _field(code, 'Code')];
    if (widget.type == MasterDataType.university) {
      fields.addAll([
        _field(city, 'City', required: false),
        _field(state, 'State', required: false),
      ]);
    }
    if (widget.type == MasterDataType.department) {
      fields.add(
        DropdownButtonFormField<int>(
          initialValue: universityId,
          decoration: const InputDecoration(labelText: 'University'),
          items: _universities
              .map(
                (item) => DropdownMenuItem(
                  value: item['id'] as int,
                  child: Text(item['name']?.toString() ?? 'University'),
                ),
              )
              .toList(),
          onChanged: saving ? null : onUniversityChanged,
          validator: (value) => value == null ? 'Select a university' : null,
        ),
      );
    }
    if (widget.type == MasterDataType.programme) {
      fields.addAll([
        DropdownButtonFormField<int>(
          initialValue: departmentId,
          decoration: const InputDecoration(labelText: 'Department'),
          items: _departments
              .map(
                (item) => DropdownMenuItem(
                  value: item['id'] as int,
                  child: Text(item['name']?.toString() ?? 'Department'),
                ),
              )
              .toList(),
          onChanged: saving ? null : onDepartmentChanged,
          validator: (value) => value == null ? 'Select a department' : null,
        ),
        DropdownButtonFormField<int>(
          initialValue: duration,
          decoration: const InputDecoration(labelText: 'Duration'),
          items: List.generate(10, (index) => index + 1)
              .map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text('$item years')),
              )
              .toList(),
          onChanged: saving ? null : onDurationChanged,
        ),
      ]);
    }
    return fields;
  }

  Future<void> _create({
    required String name,
    required String code,
    required String? city,
    required String? state,
    required int? universityId,
    required int? departmentId,
    required int duration,
    required int startYear,
    required int endYear,
  }) => switch (widget.type) {
    MasterDataType.university => UniSphereApiService.createUniversity(
      name: name,
      code: code,
      city: city,
      state: state,
    ),
    MasterDataType.department => UniSphereApiService.createDepartment(
      name: name,
      code: code,
      universityId: universityId!,
    ),
    MasterDataType.programme => UniSphereApiService.createProgramme(
      name: name,
      code: code,
      departmentId: departmentId!,
      durationYears: duration,
    ),
    MasterDataType.academicSession => UniSphereApiService.createAcademicSession(
      name: name,
      startYear: startYear,
      endYear: endYear,
    ),
  };

  void _showMessage(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Widget _programmeCard(Map<String, dynamic> record) {
    final rawSpecializations = record['specializations'];
    final specializations = rawSpecializations is List
        ? rawSpecializations.whereType<Map>().toList()
        : const <Map>[];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(Icons.school_outlined, color: Color(0xFF4F46E5)),
        ),
        title: Text(
          record['name']?.toString() ?? 'Programme',
          style: const TextStyle(
            color: Color(0xFF172554),
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${record['category'] ?? 'Uncategorized'}  |  ${_departmentName(record['department_id'] as int?)}  |  ${record['duration_years'] ?? '-'} years',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${specializations.length} options',
            style: const TextStyle(
              color: Color(0xFF0F766E),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
            color: const Color(0xFFF8FAFC),
            child: specializations.isEmpty
                ? const Text(
                    'No subjects or specializations configured.',
                    style: TextStyle(color: Color(0xFF64748B)),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specializations
                        .map(
                          (item) => Chip(
                            avatar: const Icon(
                              Icons.check_circle_outline,
                              size: 15,
                              color: Color(0xFF4F46E5),
                            ),
                            label: Text(item['name']?.toString() ?? '-'),
                            side: const BorderSide(color: Color(0xFFD7DDF0)),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  String _universityName(int? id) => _universities
      .where((item) => item['id'] == id)
      .map((item) => item['name']?.toString() ?? 'University')
      .firstOrNull ??
      'University not linked';

  String _departmentName(int? id) => _departments
      .where((item) => item['id'] == id)
      .map((item) => item['name']?.toString() ?? 'Academic unit')
      .firstOrNull ??
      'Academic unit not linked';

  int _studentCount(int departmentId) =>
      _students.where((item) => item['department_id'] == departmentId).length;

  int _programmeCount(int departmentId) =>
      _programmes.where((item) => item['department_id'] == departmentId).length;

  Widget _overview() {
    final options = _records.fold<int>(0, (total, record) {
      final values = record['specializations'];
      return total + (values is List ? values.length : 0);
    });
    final metrics = switch (widget.type) {
      MasterDataType.university => [
          ('Registered universities', _records.length, Icons.account_balance_outlined),
          ('Academic units', _departments.length, Icons.account_tree_outlined),
          ('Students', _students.length, Icons.people_outline),
        ],
      MasterDataType.department => [
          ('Academic units', _records.length, Icons.account_tree_outlined),
          ('Students mapped', _students.length, Icons.people_outline),
          ('Universities', _universities.length, Icons.account_balance_outlined),
        ],
      MasterDataType.programme => [
          ('Programme groups', _records.length, Icons.school_outlined),
          ('Subject / specialization options', options, Icons.category_outlined),
          ('Academic units', _departments.length, Icons.account_tree_outlined),
        ],
      MasterDataType.academicSession => [
          ('Sessions', _records.length, Icons.calendar_month_outlined),
          ('Active', _records.where((item) => item['is_active'] == true).length, Icons.check_circle_outline),
          ('Students', _students.length, Icons.people_outline),
        ],
    };
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics.map((metric) => Container(
        width: 220,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
        child: Row(children: [Icon(metric.$3, color: const Color(0xFF4F46E5)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${metric.$2}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(metric.$1, maxLines: 2, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))) ]))]),
      )).toList(),
    );
  }

  Widget _recordCard(Map<String, dynamic> record) {
    late final IconData icon;
    late final String title;
    late final String subtitle;
    late final List<String> details;
    switch (widget.type) {
      case MasterDataType.university:
        icon = Icons.account_balance_outlined;
        title = record['name']?.toString() ?? 'University';
        subtitle = '${record['city'] ?? 'City not set'}, ${record['state'] ?? 'State not set'}';
        details = ['Code ${record['code'] ?? '-'}', '${_departments.where((item) => item['university_id'] == record['id']).length} academic units', '${_students.length} students'];
      case MasterDataType.department:
        icon = Icons.account_tree_outlined;
        title = record['name']?.toString() ?? 'Academic unit';
        subtitle = _universityName(record['university_id'] as int?);
        details = ['Code ${record['code'] ?? '-'}', '${_programmeCount(record['id'] as int)} programmes', '${_studentCount(record['id'] as int)} students'];
      case MasterDataType.programme:
        return _programmeCard(record);
      case MasterDataType.academicSession:
        icon = Icons.calendar_month_outlined;
        title = record['name']?.toString() ?? 'Academic session';
        subtitle = '${record['start_year']} to ${record['end_year']}';
        details = [record['is_active'] == true ? 'Active session' : 'Inactive session', '${_students.where((item) => item['academic_session'] == record['name']).length} students'];
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(7)), child: Icon(icon, color: const Color(0xFF4F46E5))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF172554))), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Color(0xFF64748B)))])),
        Wrap(spacing: 7, children: details.map((detail) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)), child: Text(detail, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF475569))))).toList()),
      ]),
    );
  }

  static String? _optional(String value) =>
      value.trim().isEmpty ? null : value.trim();
  static Widget _field(
    TextEditingController controller,
    String label, {
    bool required = true,
    bool numeric = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: numeric ? TextInputType.number : null,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (required && (value == null || value.trim().isEmpty)) {
          return '$label is required';
        }
        if (numeric && int.tryParse(value ?? '') == null) {
          return 'Enter a valid number';
        }
        return null;
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
                FilledButton.icon(
                  onPressed: _loading ? null : _showCreateDialog,
                  icon: const Icon(Icons.add),
                  label: Text(
                    'Create ${_title.substring(0, _title.length - 1)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!_loading && _error == null) ...[
              _overview(),
              const SizedBox(height: 18),
            ],
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search records',
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
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 42),
                    const SizedBox(height: 12),
                    Text(_error!),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No records available. Create the first record to begin.',
                  ),
                ),
              )
            else
              ..._filtered.map(_recordCard),
          ],
        ),
      ),
    ),
  );
}
