import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../models/student_identity.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/academics/academic_screen.dart';
import '../features/ai/ai_screen.dart';
import '../features/ai/campus_assistant.dart';
import '../features/services/services_screen.dart';
import '../features/passport/passport_screen.dart';
import '../features/timeline/timeline_screen.dart';
import '../features/hostel/hostel_screen.dart';
import '../features/helpdesk/helpdesk_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/transport/transport_screen.dart';
import '../features/certificates/certificates_screen.dart';
import '../features/student/student_data_list_screen.dart';
import '../features/student/student_success_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../services/unispher_api_service.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedIndex = 0;
  StudentIdentity? _student;
  bool _identityLoading = true;
  String? _identityError;

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    setState(() {
      _identityLoading = true;
      _identityError = null;
    });

    try {
      final student = await UniSphereApiService.getStudentIdentity();
      if (!mounted) return;
      setState(() {
        _student = student;
        _identityLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _identityLoading = false;
        _identityError = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _identityLoading = false;
        _identityError = 'Unable to load your profile.';
      });
    }
  }

  final List<IconData> menuIcons = [
    Icons.dashboard_outlined,
    Icons.school_outlined,
    Icons.fact_check_outlined,
    Icons.assessment_outlined,
    Icons.calendar_month_outlined,
    Icons.assignment_outlined,
    Icons.insights_outlined,
    Icons.auto_awesome_outlined,
    Icons.badge_outlined,
    Icons.apps_outlined,
    Icons.hotel_outlined,
    Icons.directions_bus_outlined,
    Icons.workspace_premium_outlined,
    Icons.timeline_outlined,
    Icons.support_agent_outlined,
    Icons.person_outline,
    Icons.notifications_none_outlined,
  ];
  final List<String> pageTitles = [
    'Dashboard',
    'Academics',
    'Attendance',
    'Results',
    'Timetable',
    'Examinations',
    'Student Success',
    'AI Assistant',
    'Passport',
    'Services',
    'Hostel',
    'Transport',
    'Certificates',
    'Timeline',
    'Helpdesk',
    'Profile',
    'Notifications',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      floatingActionButton: const CampusAssistantButton(),
      body: Row(
        children: [
          // =========================
          // SIDEBAR
          // =========================
          Container(
            width: 250,
            color: const Color(0xFF172554),
            child: Column(
              children: [
                // LOGO
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'UNISPHERE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // MENU
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: menuIcons.length,
                    itemBuilder: (context, index) {
                      final bool selected = selectedIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 13,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  menuIcons[index],
                                  size: 20,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 13),
                                Text(
                                  pageTitles[index],
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFFCBD5E1),
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // BOTTOM MENU
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      _bottomItem(
                        Icons.notifications_none_outlined,
                        'Notifications',
                        onTap: () => setState(() => selectedIndex = 16),
                      ),
                      _bottomItem(
                        Icons.settings_outlined,
                        'Profile & Settings',
                        onTap: () => setState(() => selectedIndex = 15),
                      ),

                      const SizedBox(height: 10),

                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() {
                            selectedIndex = 15;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 19,
                                backgroundColor: const Color(0xFF6366F1),
                                child: Text(
                                  _student?.initials ??
                                      (_identityLoading ? '..' : '--'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _student?.fullName ??
                                          (_identityLoading
                                              ? 'Loading profile...'
                                              : 'Student'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _student?.academicLabel ??
                                          _identityError ??
                                          'Profile unavailable',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // =========================
          // MAIN AREA
          // =========================
          Expanded(
            child: Column(
              children: [
                // HEADER
                Container(
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        pageTitles[selectedIndex],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),

                      const Spacer(),

                      IconButton(
                        tooltip: 'Notifications',
                        onPressed: () => setState(() => selectedIndex = 16),
                        icon: const Icon(Icons.notifications_none_outlined),
                      ),

                      const SizedBox(width: 8),

                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFE0E7FF),
                        child: Text(
                          _student?.initials ??
                              (_identityLoading ? '..' : '--'),
                          style: const TextStyle(
                            color: Color(0xFF3730A3),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _student?.fullName ??
                                (_identityLoading
                                    ? 'Loading profile...'
                                    : 'Student'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            _student?.academicLabel ??
                                _identityError ??
                                'Profile unavailable',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // PAGE CONTENT
                Expanded(child: _buildPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomItem(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 19),
            const SizedBox(width: 13),
            Text(
              title,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage() {
    switch (selectedIndex) {
      case 0:
        return const DashboardScreen();

      case 1:
        return const AcademicScreen();

      case 2:
        return StudentDataListScreen(
          title: 'Attendance',
          emptyMessage: 'No attendance records are available.',
          loader: UniSphereApiService.getAttendance,
        );

      case 3:
        return StudentDataListScreen(
          title: 'Results',
          emptyMessage: 'No result records are available.',
          loader: UniSphereApiService.getResults,
        );

      case 4:
        return StudentDataListScreen(
          title: 'Timetable',
          emptyMessage: 'No timetable entries are available.',
          loader: UniSphereApiService.getTimetable,
        );

      case 5:
        return StudentDataListScreen(
          title: 'Examinations',
          emptyMessage: 'No examination registrations are available.',
          loader: UniSphereApiService.getExaminations,
        );

      case 6:
        return const StudentSuccessScreen();

      case 7:
        return const AiScreen();

      case 8:
        return const PassportScreen();

      case 9:
        return const ServicesScreen();

      case 10:
        return const HostelScreen();

      case 11:
        return const TransportScreen();

      case 12:
        return const CertificatesScreen();

      case 13:
        return TimelineScreen(student: _student);

      case 14:
        return const HelpdeskScreen();

      case 15:
        return ProfileScreen(
          student: _student,
          isLoading: _identityLoading,
          error: _identityError,
          onRefresh: _loadIdentity,
        );
      case 16:
        return const NotificationsScreen();

      default:
        return Center(
          child: Text(
            pageTitles[selectedIndex],
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xFFCBD5E1),
            ),
          ),
        );
    }
  }
}
