import 'package:flutter/material.dart';

import '../../models/student_identity.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.student,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  final StudentIdentity? student;
  final bool isLoading;
  final String? error;
  final Future<void> Function() onRefresh;

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile & Settings',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF172554),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your verified account and academic identity.',
                      style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh profile',
                onPressed: isLoading ? null : onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (isLoading && student == null)
            const _LoadingState()
          else if (student == null)
            _ErrorState(
              message: error ?? 'Your student profile is not available.',
              onRetry: onRefresh,
            )
          else ...[
            _ProfileHeader(student: student!),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = constraints.maxWidth < 760;
                final width = stacked
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 20) / 2;
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    SizedBox(
                      width: width,
                      child: _InformationPanel(
                        title: 'Account',
                        icon: Icons.person_outline,
                        rows: [
                          ('Full name', student!.fullName),
                          ('Email', student!.email),
                          ('Role', _titleCase(student!.role)),
                          (
                            'Account status',
                            student!.isActive ? 'Active' : 'Inactive',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: _InformationPanel(
                        title: 'Academic Identity',
                        icon: Icons.school_outlined,
                        rows: [
                          ('Programme', _value(student!.programme)),
                          ('Current semester', '${student!.currentSemester}'),
                          ('Uni-ID', _value(student!.uniId)),
                          ('University ID', _value(student!.universityId)),
                          (
                            'Enrollment number',
                            _value(student!.enrollmentNumber),
                          ),
                          (
                            'Academic session',
                            _value(student!.academicSession),
                          ),
                          ('Department ID', '${student!.departmentId}'),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Color(0xFFDC2626)),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign out',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'End this session on the current device.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Sign Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _value(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Not available' : text;
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return 'Not available';
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.student});

  final StudentIdentity student;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF172554),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF6366F1),
            child: Text(
              student.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  student.academicLabel,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.uniId,
                  style: const TextStyle(
                    color: Color(0xFFA5B4FC),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(active: student.isActive),
        ],
      ),
    );
  }
}

class _InformationPanel extends StatelessWidget {
  const _InformationPanel({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1D4ED8)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF172554),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final row in rows) _InfoRow(label: row.$1, value: row.$2),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        active ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          color: active ? const Color(0xFF166534) : const Color(0xFF991B1B),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 280,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: Color(0xFF64748B),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
