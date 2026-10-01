import 'package:flutter/material.dart';

import '../../services/unispher_api_service.dart';
import '../student/student_data_list_screen.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentDataListScreen(
      title: 'Timetable',
      emptyMessage: 'No timetable entries are available.',
      loader: UniSphereApiService.getTimetable,
    );
  }
}
