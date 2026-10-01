import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

class AcademicScreen extends StatefulWidget {
  const AcademicScreen({super.key});

  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen> {
  List<Map<String, dynamic>> _courses = const [];
  List<Map<String, dynamic>> _results = const [];
  List<Map<String, dynamic>> _examinations = const [];
  Map<String, dynamic> _identity = const {};
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
      final data = await Future.wait<dynamic>([
        UniSphereApiService.getCourses(),
        UniSphereApiService.getResults(),
        UniSphereApiService.getExaminations(),
        UniSphereApiService.getStudent(),
      ]);
      if (mounted) {
        setState(() {
          _courses = (data[0] as List<dynamic>)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _results = (data[1] as List<dynamic>)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _examinations = (data[2] as List<dynamic>)
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
          _identity = Map<String, dynamic>.from(data[3] as Map);
        });
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load academic records.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FB),
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(28),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Academic Center',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your enrolled curriculum, credits and published outcomes.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _errorState()
            else ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF172554),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_outlined, color: Colors.white),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _identity['programme']?.toString() ??
                                'Academic plan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_identity['academic_session'] ?? 'Session pending'}  |  Semester ${_identity['current_semester'] ?? '-'}',
                            style: const TextStyle(color: Color(0xFFCBD5E1)),
                          ),
                        ],
                      ),
                    ),
                    _AcademicMetric(
                      label: 'COURSES',
                      value: '${_courses.length}',
                    ),
                    const SizedBox(width: 10),
                    _AcademicMetric(
                      label: 'CREDITS',
                      value:
                          '${_courses.fold<int>(0, (sum, item) => sum + (item['credits'] as int? ?? 0))}',
                    ),
                    const SizedBox(width: 10),
                    _AcademicMetric(
                      label: 'EXAMS',
                      value: '${_examinations.length}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'My Courses (${_courses.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (_courses.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No courses are currently enrolled.'),
                  ),
                )
              else
                ..._courses.map(
                  (course) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: Text(
                        course['course_name']?.toString() ??
                            course['name']?.toString() ??
                            '-',
                      ),
                      subtitle: Text(
                        '${course['course_code'] ?? course['code'] ?? '-'}  |  Section ${course['section'] ?? '-'}  |  ${course['faculty_name'] ?? 'Faculty allocation pending'}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${course['credits'] ?? '-'} credits',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            course['enrollment_status']
                                    ?.toString()
                                    .toUpperCase() ??
                                'ENROLLED',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Published Results (${_results.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (_results.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('No results have been published.'),
                  ),
                )
              else
                ..._results.map(
                  (result) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.assessment_outlined),
                      title: Text(result['course_name']?.toString() ?? '-'),
                      subtitle: Text(
                        '${result['course_code'] ?? '-'} | Semester ${result['semester_id'] ?? '-'}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(result['grade']?.toString() ?? '-'),
                          Text('Marks: ${result['marks'] ?? '-'}'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
  );

  Widget _errorState() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 42),
        const SizedBox(height: 12),
        Text(_error!),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

class _AcademicMetric extends StatelessWidget {
  const _AcademicMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    width: 76,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
