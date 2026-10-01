import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/unispher_api_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_data_list_screen.dart';
import 'admin_master_data_screen.dart';
import 'admin_reports_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'admin_ai_screen.dart';
import '../ai/campus_assistant.dart';
import 'intervention_screen.dart';
import 'risk_analytics_screen.dart';
import 'student_management_screen.dart';
import 'student_360_screen.dart';
import 'admin_operations_screen.dart';
import 'admin_hostel_screen.dart';
import 'admin_transport_screen.dart';
import 'admin_certificates_screen.dart';
import 'admin_documents_screen.dart';
import 'admin_academic_plans_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_examinations_screen.dart';
import 'admin_early_warning_screen.dart';
import 'admin_parents_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<_AdminModule> _modules = [
    _AdminModule(
      'Dashboard',
      Icons.dashboard_outlined,
      const AdminDashboardScreen(),
    ),
    _AdminModule(
      'Students',
      Icons.people_outline,
      const StudentManagementScreen(),
    ),
    _AdminModule('Student 360', Icons.hub_outlined, const Student360Screen()),
    _AdminModule(
      'Academic Planning',
      Icons.auto_awesome_motion_outlined,
      const AdminAcademicPlansScreen(),
    ),
    _AdminModule(
      'University',
      Icons.account_balance_outlined,
      const AdminMasterDataScreen(type: MasterDataType.university),
    ),
    _AdminModule(
      'Departments',
      Icons.account_tree_outlined,
      const AdminMasterDataScreen(type: MasterDataType.department),
    ),
    _AdminModule(
      'Programmes',
      Icons.school_outlined,
      const AdminMasterDataScreen(type: MasterDataType.programme),
    ),
    _AdminModule(
      'Academic Sessions',
      Icons.calendar_month_outlined,
      const AdminMasterDataScreen(type: MasterDataType.academicSession),
    ),
    _AdminModule(
      'Semesters',
      Icons.date_range_outlined,
      const AdminOperationsScreen(section: AdminOpsSection.semesters),
    ),
    _AdminModule(
      'Courses',
      Icons.menu_book_outlined,
      const AdminOperationsScreen(section: AdminOpsSection.courses),
    ),
    _AdminModule(
      'Enrollment',
      Icons.how_to_reg_outlined,
      const AdminOperationsScreen(section: AdminOpsSection.enrollment),
    ),
    _AdminModule(
      'Timetable',
      Icons.schedule_outlined,
      const AdminOperationsScreen(section: AdminOpsSection.timetable),
    ),
    _AdminModule(
      'Attendance',
      Icons.fact_check_outlined,
      const AdminAttendanceScreen(),
    ),
    _AdminModule(
      'Examinations',
      Icons.assignment_outlined,
      const AdminExaminationsScreen(),
    ),
    _AdminModule(
      'Documents',
      Icons.folder_outlined,
      const AdminDocumentsScreen(),
    ),
    _AdminModule(
      'Certificates',
      Icons.workspace_premium_outlined,
      const AdminCertificatesScreen(),
    ),
    _AdminModule(
      'Fees',
      Icons.account_balance_wallet_outlined,
      const AdminOperationsScreen(section: AdminOpsSection.fees),
    ),
    _AdminModule(
      'Payments',
      Icons.payments_outlined,
      const AdminOperationsScreen(section: AdminOpsSection.payments),
    ),
    _AdminModule('Hostel', Icons.hotel_outlined, const AdminHostelScreen()),
    _AdminModule(
      'Transport',
      Icons.directions_bus_outlined,
      const AdminTransportScreen(),
    ),
    _AdminModule(
      'Helpdesk',
      Icons.support_agent_outlined,
      AdminDataListScreen(
        title: 'Helpdesk',
        loader: UniSphereApiService.getAdminHelpdeskTickets,
      ),
    ),
    _AdminModule.unavailable('Grievance', Icons.feedback_outlined),
    _AdminModule(
      'Parents',
      Icons.family_restroom_outlined,
      const AdminParentsScreen(),
    ),
    _AdminModule(
      'Notifications',
      Icons.notifications_outlined,
      const AdminOperationsScreen(section: AdminOpsSection.notifications),
    ),
    _AdminModule('AI', Icons.auto_awesome_outlined, const AdminAiScreen()),
    _AdminModule.unavailable('Voice Assistant', Icons.mic_outlined),
    _AdminModule(
      'Risk',
      Icons.warning_amber_outlined,
      const RiskAnalyticsScreen(),
    ),
    _AdminModule(
      'Early Warning',
      Icons.crisis_alert_outlined,
      const AdminEarlyWarningScreen(),
    ),
    _AdminModule(
      'Interventions',
      Icons.volunteer_activism_outlined,
      const InterventionScreen(),
    ),
    _AdminModule.unavailable('Academic Passport', Icons.badge_outlined),
    _AdminModule.unavailable('Secure Sharing', Icons.share_outlined),
    _AdminModule.unavailable(
      'RBAC & Permissions',
      Icons.admin_panel_settings_outlined,
    ),
    _AdminModule.unavailable('Audit Logs', Icons.history_outlined),
    _AdminModule.unavailable('Realtime', Icons.sensors_outlined),
    _AdminModule(
      'Analytics',
      Icons.analytics_outlined,
      const AnalyticsDashboardScreen(),
    ),
    _AdminModule(
      'Reports',
      Icons.summarize_outlined,
      const AdminReportsScreen(),
    ),
    _AdminModule.unavailable('System Settings', Icons.settings_outlined),
  ];

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    final current = _modules[_selectedIndex];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: const CampusAssistantButton(),
      appBar: compact
          ? AppBar(title: Text(current.title), actions: [_accountButton()])
          : null,
      drawer: compact ? Drawer(child: _navigation()) : null,
      body: Row(
        children: [
          if (!compact) SizedBox(width: 268, child: _navigation()),
          Expanded(
            child: Column(
              children: [
                if (!compact) _header(current.title),
                Expanded(child: current.screen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navigation() => ColoredBox(
    color: const Color(0xFF172554),
    child: SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Icon(Icons.school_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'UNISPHERE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'COMMAND CENTER',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _modules.length,
              itemBuilder: (context, index) {
                final item = _modules[index];
                final selected = index == _selectedIndex;
                return ListTile(
                  dense: true,
                  selected: selected,
                  selectedTileColor: Colors.white12,
                  leading: Icon(
                    item.icon,
                    size: 20,
                    color: selected ? Colors.white : const Color(0xFF94A3B8),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFFCBD5E1),
                      fontSize: 13,
                    ),
                  ),
                  trailing: item.unavailable
                      ? const Icon(
                          Icons.lock_outline,
                          size: 15,
                          color: Color(0xFF64748B),
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
                      Navigator.pop(context);
                    }
                  },
                );
              },
            ),
          ),
          const Divider(color: Color(0xFF334155)),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFCBD5E1)),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Color(0xFFCBD5E1)),
            ),
            onTap: _logout,
          ),
        ],
      ),
    ),
  );

  Widget _header(String title) => Container(
    height: 68,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    color: Colors.white,
    child: Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        _accountButton(),
      ],
    ),
  );

  Widget _accountButton() => IconButton(
    tooltip: 'Administrator account',
    onPressed: () {},
    icon: const Icon(Icons.admin_panel_settings_outlined),
  );
}

class _AdminModule {
  const _AdminModule(this.title, this.icon, this.screen) : unavailable = false;
  const _AdminModule.unavailable(this.title, this.icon)
    : unavailable = true,
      screen = const AdminDataListScreen(
        title: 'Module unavailable',
        loader: null,
        unavailableReason: 'A supported backend workflow is not available for this module yet.',
      );

  final String title;
  final IconData icon;
  final Widget screen;
  final bool unavailable;
}
