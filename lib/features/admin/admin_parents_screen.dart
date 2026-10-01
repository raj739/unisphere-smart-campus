import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

const _ink = Color(0xFF14213D);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFDDE4EE);
const _navy = Color(0xFF172554);
const _teal = Color(0xFF0F8A7E);

class AdminParentsScreen extends StatefulWidget {
  const AdminParentsScreen({super.key});

  @override
  State<AdminParentsScreen> createState() => _AdminParentsScreenState();
}

class _AdminParentsScreenState extends State<AdminParentsScreen> {
  List<Map<String, dynamic>> _parents = const [];
  List<Map<String, dynamic>> _students = const [];
  String _query = '';
  String? _error;
  bool _loading = true;

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
        UniSphereApiService.getAdminParentAccounts(),
        UniSphereApiService.getAdminStudents(),
      ]);
      if (!mounted) return;
      setState(() {
        _parents = List<Map<String, dynamic>>.from(results[0] as List);
        _students = (results[1] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load parent accounts.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredParents {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _parents;
    return _parents.where((parent) {
      final links = _links(parent);
      return [
        parent['full_name'],
        parent['email'],
        parent['phone'],
        ...links.expand(
          (link) => [link['student_name'], link['uni_id'], link['programme']],
        ),
      ].any(
        (value) => value?.toString().toLowerCase().contains(query) ?? false,
      );
    }).toList();
  }

  int get _activeLinks => _parents.fold<int>(
    0,
    (total, parent) =>
        total +
        _links(parent).where((link) => link['is_active'] == true).length,
  );

  Future<void> _showCreateParent() async {
    if (_students.isEmpty) {
      _message('Register a student before creating a parent account.');
      return;
    }
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final email = TextEditingController();
    final phone = TextEditingController();
    final password = TextEditingController();
    var relationship = 'Father';
    int? studentId = _students.first['id'] as int?;
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.family_restroom_outlined, color: _navy),
              SizedBox(width: 10),
              Text('Register parent'),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(
                      controller: name,
                      label: 'Parent full name',
                      icon: Icons.person_outline,
                    ),
                    _field(
                      controller: email,
                      label: 'Parent email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter a valid email address'
                          : null,
                    ),
                    _field(
                      controller: phone,
                      label: 'Phone number (optional)',
                      icon: Icons.phone_outlined,
                      required: false,
                      keyboardType: TextInputType.phone,
                    ),
                    _field(
                      controller: password,
                      label: 'Temporary password',
                      icon: Icons.lock_outline,
                      obscureText: true,
                      validator: (value) => (value?.length ?? 0) < 8
                          ? 'Use at least 8 characters'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: relationship,
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                        prefixIcon: Icon(Icons.diversity_1_outlined),
                      ),
                      items: const ['Father', 'Mother', 'Guardian']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: submitting
                          ? null
                          : (value) => setDialogState(
                              () => relationship = value ?? 'Guardian',
                            ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: studentId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Link to student',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: _students
                          .map(
                            (student) => DropdownMenuItem<int>(
                              value: student['id'] as int?,
                              child: Text(
                                '${student['full_name']} | ${student['uni_id']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: submitting
                          ? null
                          : (value) => setDialogState(() => studentId = value),
                      validator: (value) =>
                          value == null ? 'Select a student' : null,
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
                          studentId == null) {
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        await UniSphereApiService.createParentAccount(
                          fullName: name.text.trim(),
                          email: email.text.trim(),
                          password: password.text,
                          phone: _optional(phone.text),
                          relationshipType: relationship,
                          studentId: studentId!,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _load();
                        _message('Parent account created and linked.');
                      } on ApiException catch (error) {
                        setDialogState(() => submitting = false);
                        _message(error.message);
                      } catch (_) {
                        setDialogState(() => submitting = false);
                        _message('Unable to register the parent account.');
                      }
                    },
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(submitting ? 'Creating...' : 'Create account'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
  }

  Future<void> _showLinkStudent(Map<String, dynamic> parent) async {
    final linkedIds = _links(parent)
        .where((link) => link['is_active'] == true)
        .map((link) => link['student_id'])
        .toSet();
    final available = _students
        .where((student) => !linkedIds.contains(student['id']))
        .toList();
    if (available.isEmpty) {
      _message('All available students are already linked to this parent.');
      return;
    }
    var relationship = parent['relationship_type']?.toString() ?? 'Guardian';
    int? studentId = available.first['id'] as int?;
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Link student to ${parent['full_name']}'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: studentId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Student',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: available
                      .map(
                        (student) => DropdownMenuItem<int>(
                          value: student['id'] as int?,
                          child: Text(
                            '${student['full_name']} | ${student['uni_id']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: submitting
                      ? null
                      : (value) => setDialogState(() => studentId = value),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue:
                      ['Father', 'Mother', 'Guardian'].contains(relationship)
                      ? relationship
                      : 'Guardian',
                  decoration: const InputDecoration(
                    labelText: 'Relationship',
                    prefixIcon: Icon(Icons.diversity_1_outlined),
                  ),
                  items: const ['Father', 'Mother', 'Guardian']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: submitting
                      ? null
                      : (value) => setDialogState(
                          () => relationship = value ?? 'Guardian',
                        ),
                ),
              ],
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
                      if (studentId == null) return;
                      setDialogState(() => submitting = true);
                      try {
                        await UniSphereApiService.linkParentStudent(
                          parentUserId: parent['user_id'] as int,
                          studentId: studentId!,
                          relationshipType: relationship,
                        );
                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        await _load();
                        _message('Student linked successfully.');
                      } on ApiException catch (error) {
                        setDialogState(() => submitting = false);
                        _message(error.message);
                      }
                    },
              icon: const Icon(Icons.link),
              label: Text(submitting ? 'Linking...' : 'Link student'),
            ),
          ],
        ),
      ),
    );
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredParents;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 80),
        children: [
          _Header(onAdd: _showCreateParent),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _Summary(
                icon: Icons.family_restroom_outlined,
                label: 'Parent accounts',
                value: '${_parents.length}',
                color: _navy,
              ),
              _Summary(
                icon: Icons.link_outlined,
                label: 'Active links',
                value: '$_activeLinks',
                color: _teal,
              ),
              _Summary(
                icon: Icons.school_outlined,
                label: 'Students available',
                value: '${_students.length}',
                color: const Color(0xFF4F46E5),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'Search parent, student, Uni-ID, or programme',
              prefixIcon: Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 18),
          if (_loading)
            const SizedBox(
              height: 340,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _ErrorState(message: _error!, onRetry: _load)
          else if (filtered.isEmpty)
            const _EmptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1080 ? 2 : 1;
                final width =
                    (constraints.maxWidth - ((columns - 1) * 14)) / columns;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: filtered
                      .map(
                        (parent) => SizedBox(
                          width: width,
                          child: _ParentTile(
                            parent: parent,
                            onLink: () => _showLinkStudent(parent),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 14,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const SizedBox(
          width: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parent accounts',
                style: TextStyle(
                  color: _ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Register verified guardians and control their student access.',
                style: TextStyle(color: _muted),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Register parent'),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      height: 92,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 13),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ParentTile extends StatelessWidget {
  const _ParentTile({required this.parent, required this.onLink});

  final Map<String, dynamic> parent;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    final links = _links(parent)
        .where((item) => item['is_active'] == true)
        .toList();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline, color: _navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent['full_name']?.toString() ?? 'Parent',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      parent['email']?.toString() ?? '-',
                      style: const TextStyle(color: _muted),
                    ),
                  ],
                ),
              ),
              _Badge(
                text: parent['is_active'] == true ? 'Active' : 'Inactive',
                color: parent['is_active'] == true ? _teal : _muted,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _Meta(
                icon: Icons.diversity_1_outlined,
                text: parent['relationship_type']?.toString() ?? 'Guardian',
              ),
              _Meta(
                icon: Icons.phone_outlined,
                text: parent['phone']?.toString() ?? 'No phone added',
              ),
              _Meta(
                icon: Icons.link_outlined,
                text:
                    '${links.length} linked student${links.length == 1 ? '' : 's'}',
              ),
            ],
          ),
          const Divider(height: 28),
          const Text(
            'Linked students',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (links.isEmpty)
            const Text(
              'No active student links.',
              style: TextStyle(color: _muted),
            )
          else
            ...links.map(
              (link) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, size: 19, color: _teal),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            link['student_name']?.toString() ?? 'Student',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${link['uni_id'] ?? '-'} | ${link['programme'] ?? '-'}',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (link['is_primary'] == true)
                      const _Badge(text: 'Primary', color: Color(0xFF4F46E5)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onLink,
              icon: const Icon(Icons.link),
              label: const Text('Link another student'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: _muted),
      const SizedBox(width: 5),
      Text(text, style: const TextStyle(color: _muted, fontSize: 12)),
    ],
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 300,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 42, color: _muted),
          const SizedBox(height: 12),
          Text(message),
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 300,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.family_restroom_outlined, size: 44, color: _muted),
          SizedBox(height: 12),
          Text(
            'No parent accounts match this search.',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

Widget _field({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool required = true,
  bool obscureText = false,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator:
          validator ??
          (value) => required && (value == null || value.trim().isEmpty)
              ? 'This field is required'
              : null,
    ),
  );
}

List<Map<String, dynamic>> _links(Map<String, dynamic> parent) {
  final value = parent['links'];
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String? _optional(String value) => value.trim().isEmpty ? null : value.trim();
