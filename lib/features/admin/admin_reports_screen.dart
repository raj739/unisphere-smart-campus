import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _working = false;
  String? _message;

  Future<void> _generate(String format) async {
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final students = await UniSphereApiService.getAdminStudents();
      final rows = students.whereType<Map>().map((item) {
        final student = Map<String, dynamic>.from(item);
        return <String, dynamic>{
          'Uni-ID': student['uni_id'],
          'Name': student['full_name'],
          'Programme': student['programme'],
          'Semester': student['current_semester'],
          'Enrollment': student['enrollment_number'],
        };
      }).toList();
      final data = await UniSphereApiService.generateReport(
        format: format,
        title: 'Student Directory',
        rows: rows,
      );
      final directory = await getApplicationDocumentsDirectory();
      final filename = 'unisphere_student_directory.${format == 'pdf' ? 'pdf' : 'xlsx'}';
      final file = File('${directory.path}${Platform.pathSeparator}$filename');
      await file.writeAsBytes(data, flush: true);
      if (mounted) setState(() => _message = 'Saved $filename in ${directory.path}.');
    } on ApiException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted) setState(() => _message = 'Unable to generate the report.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Reports', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Generate an authorized student directory report from live backend data.'),
                const SizedBox(height: 20),
                Wrap(spacing: 12, runSpacing: 12, children: [
                  FilledButton.icon(onPressed: _working ? null : () => _generate('pdf'), icon: const Icon(Icons.picture_as_pdf_outlined), label: const Text('Save PDF')),
                  OutlinedButton.icon(onPressed: _working ? null : () => _generate('excel'), icon: const Icon(Icons.table_chart_outlined), label: const Text('Save Excel')),
                ]),
                if (_working) const Padding(padding: EdgeInsets.only(top: 20), child: LinearProgressIndicator()),
                if (_message != null) Padding(padding: const EdgeInsets.only(top: 20), child: Text(_message!)),
              ]),
            )),
          ),
        ))),
      );
}
