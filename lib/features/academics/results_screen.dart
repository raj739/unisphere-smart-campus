import 'package:flutter/material.dart';

import '../../services/unispher_api_service.dart';
import '../student/student_data_list_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StudentDataListScreen(
      title: 'Results',
      emptyMessage: 'No result records are available.',
      loader: UniSphereApiService.getResults,
    );
  }
}
