import 'package:flutter/material.dart';

import '../../services/unispher_api_service.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  bool loading = true;
  String status = 'Connecting...';
  Map<String, dynamic>? student;
  List<dynamic>? attendance;
  Map<String, dynamic>? fees;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        UniSphereApiService.getStudent(),
        UniSphereApiService.getAttendance(),
        UniSphereApiService.getFeeSummary(),
      ]);

      if (!mounted) return;

      setState(() {
        student = Map<String, dynamic>.from(results[0] as Map);
        attendance = List<dynamic>.from(results[1] as List);
        fees = Map<String, dynamic>.from(results[2] as Map);
        status = 'Connected to UniSphere API';
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        status = 'API Error: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Integration Test')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  Text(
                    status,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (student != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Student',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('Name: ${student!['full_name']}'),
                            Text('Uni-ID: ${student!['uni_id']}'),
                            Text('Programme: ${student!['programme']}'),
                            Text('Semester: ${student!['current_semester']}'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (attendance != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Attendance records: ${attendance!.length}',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (fees != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fee Summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Outstanding: ₹${fees!['outstanding_amount']}',
                            ),
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
