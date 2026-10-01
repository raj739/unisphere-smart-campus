import 'package:flutter/material.dart';

import '../../services/unispher_api_service.dart';
import '../student/student_data_list_screen.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentDataListScreen(
      title: 'Attendance',
      emptyMessage: 'No attendance records are available.',
      loader: UniSphereApiService.getAttendance,
    );
  }
}
