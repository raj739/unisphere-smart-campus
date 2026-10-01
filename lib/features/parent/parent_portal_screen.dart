import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/auth_service.dart';
import '../../services/unispher_api_service.dart';
import '../ai/campus_assistant.dart';

const _navy = Color(0xFF172554);
const _ink = Color(0xFF14213D);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFDDE4EE);
const _surface = Color(0xFFFFFFFF);
const _page = Color(0xFFF4F7FA);
const _teal = Color(0xFF0F8A7E);
const _amber = Color(0xFFD97706);
const _red = Color(0xFFDC2626);
const _green = Color(0xFF15803D);

class ParentPortalScreen extends StatefulWidget {
  const ParentPortalScreen({super.key});

  @override
  State<ParentPortalScreen> createState() => _ParentPortalScreenState();
}

class _ParentPortalScreenState extends State<ParentPortalScreen> {
  Map<String, dynamic> _profile = const {};
  List<Map<String, dynamic>> _students = const [];
  Map<String, dynamic>? _dashboard;
  int? _selectedStudentId;
  String? _error;
  bool _loading = true;
  bool _switchingStudent = false;

  @override
  void initState() {
    super.initState();
    _loadPortal();
  }

  Future<void> _loadPortal() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        UniSphereApiService.getParentProfileV2(),
        UniSphereApiService.getParentStudentsV2(),
      ]);
      final profile = Map<String, dynamic>.from(results[0] as Map);
      final students = (results[1] as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final selectedId =
          students.any((student) => student['student_id'] == _selectedStudentId)
          ? _selectedStudentId
          : students.firstOrNull?['student_id'] as int?;
      final dashboard = selectedId == null
          ? null
          : await UniSphereApiService.getParentDashboardV2(selectedId);

      if (!mounted) return;
      setState(() {
        _profile = profile;
        _students = students;
        _selectedStudentId = selectedId;
        _dashboard = dashboard;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to load the parent portal.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectStudent(int? studentId) async {
    if (studentId == null || studentId == _selectedStudentId) return;
    setState(() {
      _selectedStudentId = studentId;
      _switchingStudent = true;
      _error = null;
    });
    try {
      final dashboard = await UniSphereApiService.getParentDashboardV2(
        studentId,
      );
      if (mounted) setState(() => _dashboard = dashboard);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load this student.');
    } finally {
      if (mounted) setState(() => _switchingStudent = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      floatingActionButton: const CampusAssistantButton(),
      body: SafeArea(
        child: Column(
          children: [
            _PortalHeader(
              parentName: _profile['full_name']?.toString(),
              relationship: _profile['relationship_type']?.toString(),
              loading: _loading,
              onRefresh: _loadPortal,
              onLogout: _logout,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadPortal,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                  children: [
                    if (_loading)
                      const SizedBox(
                        height: 420,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null && _dashboard == null)
                      _ErrorState(message: _error!, onRetry: _loadPortal)
                    else if (_students.isEmpty)
                      const _EmptyState()
                    else ...[
                      _PageIntro(
                        students: _students,
                        selectedStudentId: _selectedStudentId,
                        onStudentChanged: _selectStudent,
                      ),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _InlineError(message: _error!),
                        ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: _switchingStudent
                            ? const SizedBox(
                                height: 360,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : _Dashboard(
                                key: ValueKey(_selectedStudentId),
                                data: _dashboard ?? const {},
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalHeader extends StatelessWidget {
  const _PortalHeader({
    required this.parentName,
    required this.relationship,
    required this.loading,
    required this.onRefresh,
    required this.onLogout,
  });

  final String? parentName;
  final String? relationship;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 680;
    return Container(
      height: 74,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _line)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.family_restroom, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compact ? 'Parent Portal' : 'UniSphere Parent Portal',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!compact)
                  Text(
                    [?parentName, ?relationship].join('  |  '),
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: loading ? null : onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (compact)
            IconButton(
              tooltip: 'Sign out',
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
            )
          else
            TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
            ),
        ],
      ),
    );
  }
}

class _PageIntro extends StatelessWidget {
  const _PageIntro({
    required this.students,
    required this.selectedStudentId,
    required this.onStudentChanged,
  });

  final List<Map<String, dynamic>> students;
  final int? selectedStudentId;
  final ValueChanged<int?> onStudentChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family overview',
              style: TextStyle(
                color: _ink,
                fontSize: compact ? 25 : 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Live academic and administrative status for linked students.',
              style: TextStyle(color: _muted, fontSize: 14),
            ),
          ],
        );
        final selector = SizedBox(
          width: compact ? double.infinity : 330,
          child: DropdownButtonFormField<int>(
            initialValue: selectedStudentId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Viewing student',
              prefixIcon: Icon(Icons.person_search_outlined),
              border: OutlineInputBorder(),
            ),
            items: students
                .map(
                  (student) => DropdownMenuItem<int>(
                    value: student['student_id'] as int?,
                    child: Text(
                      student['full_name']?.toString() ?? 'Linked student',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: onStudentChanged,
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 18), selector],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: title),
            selector,
          ],
        );
      },
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({super.key, required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final student = _map(data['student']);
    final attendance = _map(data['attendance']);
    final fees = _map(data['fees']);
    final examinations = _map(data['examinations']);
    final attendanceValue = _number(attendance['overall_percentage']);
    final outstanding = _number(fees['outstanding_amount']);
    final registrations = _integer(examinations['registrations']);
    final pendingExams = _integer(examinations['pending']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StudentBand(student: student),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1080
                ? 4
                : constraints.maxWidth >= 620
                ? 2
                : 1;
            final width =
                (constraints.maxWidth - ((columns - 1) * 12)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricTile(
                  width: width,
                  label: 'Attendance',
                  value: '${attendanceValue.toStringAsFixed(1)}%',
                  detail: _statusLabel(attendance['status']),
                  icon: Icons.fact_check_outlined,
                  color: _statusColor(attendance['status']),
                ),
                _MetricTile(
                  width: width,
                  label: 'Outstanding fees',
                  value: _money(outstanding),
                  detail: _statusLabel(fees['status']),
                  icon: Icons.account_balance_wallet_outlined,
                  color: outstanding > 0 ? _amber : _green,
                ),
                _MetricTile(
                  width: width,
                  label: 'Exam registrations',
                  value: '$registrations',
                  detail: '$pendingExams pending',
                  icon: Icons.assignment_outlined,
                  color: pendingExams > 0 ? _amber : _teal,
                ),
                _MetricTile(
                  width: width,
                  label: 'Current semester',
                  value: '${student['current_semester'] ?? '-'}',
                  detail:
                      student['academic_session']?.toString() ?? 'Session -',
                  icon: Icons.calendar_month_outlined,
                  color: const Color(0xFF4F46E5),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final primary = Column(
              children: [
                _AttendancePanel(data: attendance),
                const SizedBox(height: 14),
                _FeesPanel(data: fees),
              ],
            );
            final secondary = Column(
              children: [
                _AttentionPanel(
                  attendance: attendance,
                  fees: fees,
                  examinations: examinations,
                ),
                const SizedBox(height: 14),
                _ExamPanel(data: examinations),
              ],
            );
            if (!wide) {
              return Column(
                children: [primary, const SizedBox(height: 14), secondary],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: primary),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: secondary),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StudentBand extends StatelessWidget {
  const _StudentBand({required this.student});

  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 24,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF24366F),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school_outlined, color: Colors.white),
          ),
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['full_name']?.toString() ?? 'Linked student',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student['programme']?.toString() ?? 'Programme not assigned',
                  style: const TextStyle(color: Color(0xFFCBD5E1)),
                ),
              ],
            ),
          ),
          _IdentityItem(label: 'UNI-ID', value: student['uni_id']),
          _IdentityItem(
            label: 'ENROLLMENT',
            value: student['enrollment_number'],
          ),
          _IdentityItem(
            label: 'UNIVERSITY ID',
            value: student['university_id'],
          ),
        ],
      ),
    );
  }
}

class _IdentityItem extends StatelessWidget {
  const _IdentityItem({required this.label, required this.value});

  final String label;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? '-',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.width,
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: const TextStyle(color: _muted)),
                const SizedBox(height: 3),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  detail,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendancePanel extends StatelessWidget {
  const _AttendancePanel({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final percentage = _number(data['overall_percentage']);
    final attended = _integer(data['attended_classes']);
    final total = _integer(data['total_classes']);
    final status = data['status'];
    final color = _statusColor(status);
    return _Panel(
      title: 'Attendance health',
      icon: Icons.fact_check_outlined,
      trailing: _StatusBadge(label: _statusLabel(status), color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '$attended of $total classes attended',
                  style: const TextStyle(color: _muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: (percentage / 100).clamp(0, 1),
              color: color,
              backgroundColor: const Color(0xFFE8EDF3),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            total == 0
                ? 'Attendance will appear after faculty records a class.'
                : percentage < 75
                ? 'Attendance is below the university target of 75%.'
                : 'Attendance currently meets the university target.',
            style: const TextStyle(color: _muted),
          ),
        ],
      ),
    );
  }
}

class _FeesPanel extends StatelessWidget {
  const _FeesPanel({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final total = _number(data['total_amount']);
    final paid = _number(data['paid_amount']);
    final outstanding = _number(data['outstanding_amount']);
    return _Panel(
      title: 'Fee position',
      icon: Icons.receipt_long_outlined,
      trailing: _StatusBadge(
        label: _statusLabel(data['status']),
        color: outstanding > 0 ? _amber : _green,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _Amount(label: 'Total invoiced', value: total, color: _ink),
          _Amount(label: 'Paid', value: paid, color: _green),
          _Amount(label: 'Outstanding', value: outstanding, color: _amber),
        ],
      ),
    );
  }
}

class _Amount extends StatelessWidget {
  const _Amount({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            _money(value),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamPanel extends StatelessWidget {
  const _ExamPanel({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final registered = _integer(data['registrations']);
    final approved = _integer(data['approved']);
    final pending = _integer(data['pending']);
    return _Panel(
      title: 'Examination status',
      icon: Icons.assignment_turned_in_outlined,
      child: Column(
        children: [
          _DetailRow(label: 'Registrations', value: '$registered'),
          const Divider(height: 20),
          _DetailRow(label: 'Approved', value: '$approved', color: _green),
          const Divider(height: 20),
          _DetailRow(label: 'Pending review', value: '$pending', color: _amber),
        ],
      ),
    );
  }
}

class _AttentionPanel extends StatelessWidget {
  const _AttentionPanel({
    required this.attendance,
    required this.fees,
    required this.examinations,
  });

  final Map<String, dynamic> attendance;
  final Map<String, dynamic> fees;
  final Map<String, dynamic> examinations;

  @override
  Widget build(BuildContext context) {
    final items = <_AttentionItem>[];
    final attendanceValue = _number(attendance['overall_percentage']);
    final totalClasses = _integer(attendance['total_classes']);
    final outstanding = _number(fees['outstanding_amount']);
    final pending = _integer(examinations['pending']);

    if (totalClasses == 0) {
      items.add(
        const _AttentionItem(
          icon: Icons.info_outline,
          color: _teal,
          title: 'Attendance data pending',
          detail: 'No classes have been recorded for this student yet.',
        ),
      );
    } else if (attendanceValue < 75) {
      items.add(
        _AttentionItem(
          icon: Icons.warning_amber_rounded,
          color: attendanceValue < 60 ? _red : _amber,
          title: 'Attendance needs attention',
          detail:
              'Current attendance is ${attendanceValue.toStringAsFixed(1)}%.',
        ),
      );
    }
    if (outstanding > 0) {
      items.add(
        _AttentionItem(
          icon: Icons.account_balance_wallet_outlined,
          color: _amber,
          title: 'Fee payment pending',
          detail: '${_money(outstanding)} remains outstanding.',
        ),
      );
    }
    if (pending > 0) {
      items.add(
        _AttentionItem(
          icon: Icons.pending_actions_outlined,
          color: _amber,
          title: 'Exam approval pending',
          detail:
              '$pending registration${pending == 1 ? '' : 's'} awaiting review.',
        ),
      );
    }
    if (items.isEmpty) {
      items.add(
        const _AttentionItem(
          icon: Icons.verified_outlined,
          color: _green,
          title: 'Everything looks on track',
          detail: 'There are no active items requiring parent attention.',
        ),
      );
    }

    return _Panel(
      title: 'Needs attention',
      icon: Icons.notifications_active_outlined,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            items[index],
            if (index != items.length - 1) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}

class _AttentionItem extends StatelessWidget {
  const _AttentionItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(detail, style: const TextStyle(color: _muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _navy, size: 21),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: _muted)),
        ),
        Text(
          value,
          style: TextStyle(color: color ?? _ink, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: _red)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44, color: _muted),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 420,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_off_outlined, size: 46, color: _muted),
            SizedBox(height: 14),
            Text(
              'No student is linked to this parent account.',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 5),
            Text(
              'Contact the university office to verify the relationship.',
              style: TextStyle(color: _muted),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _map(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

double _number(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _integer(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _money(double amount) {
  final rounded = amount.round();
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final remaining = digits.length - index;
    buffer.write(digits[index]);
    if (remaining > 1 && (remaining - 1) % 3 == 0) buffer.write(',');
  }
  return '${rounded < 0 ? '-' : ''}₹$buffer';
}

String _statusLabel(dynamic value) {
  final status = value?.toString().trim().toLowerCase() ?? 'no_data';
  if (status == 'no_data') return 'No data';
  return status
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

Color _statusColor(dynamic value) {
  switch (value?.toString().toLowerCase()) {
    case 'critical':
      return _red;
    case 'warning':
    case 'pending':
    case 'partially_paid':
      return _amber;
    case 'good':
    case 'paid':
    case 'approved':
      return _green;
    default:
      return _teal;
  }
}
