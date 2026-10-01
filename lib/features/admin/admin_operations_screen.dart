import 'package:flutter/material.dart';

import '../../core/network/api_exception.dart';
import '../../services/unispher_api_service.dart';

enum AdminOpsSection {
  semesters,
  courses,
  enrollment,
  timetable,
  attendance,
  examinations,
  fees,
  payments,
  hostel,
  transport,
  notifications,
  earlyWarning,
}

class AdminOperationsScreen extends StatefulWidget {
  const AdminOperationsScreen({super.key, required this.section});

  final AdminOpsSection section;

  @override
  State<AdminOperationsScreen> createState() => _AdminOperationsScreenState();
}

class _AdminOperationsScreenState extends State<AdminOperationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _courses = const [];
  List<Map<String, dynamic>> _semesters = const [];
  List<Map<String, dynamic>> _offerings = const [];
  List<Map<String, dynamic>> _students = const [];
  List<Map<String, dynamic>> _programmes = const [];
  List<Map<String, dynamic>> _departments = const [];
  String _query = '';

  String get _title => switch (widget.section) {
    AdminOpsSection.semesters => 'Semesters',
    AdminOpsSection.courses => 'Courses',
    AdminOpsSection.enrollment => 'Enrollment',
    AdminOpsSection.timetable => 'Timetable',
    AdminOpsSection.attendance => 'Attendance Management',
    AdminOpsSection.examinations => 'Examinations',
    AdminOpsSection.fees => 'Fees & Payments',
    AdminOpsSection.payments => 'Payment Transactions',
    AdminOpsSection.hostel => 'Hostel Administration',
    AdminOpsSection.transport => 'Transport Administration',
    AdminOpsSection.notifications => 'Notifications Management',
    AdminOpsSection.earlyWarning => 'Early Warning',
  };

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
      List<Map<String, dynamic>> data;
      switch (widget.section) {
        case AdminOpsSection.semesters:
          data = await UniSphereApiService.getSemesters();
        case AdminOpsSection.courses:
          data = await UniSphereApiService.getAdminCourses();
        case AdminOpsSection.enrollment:
          data = await UniSphereApiService.getCourseOfferings();
        case AdminOpsSection.timetable:
          data = await UniSphereApiService.getAdminTimetableEntries();
        case AdminOpsSection.attendance:
          data = await UniSphereApiService.getAttendanceSessions();
        case AdminOpsSection.examinations:
          data = await UniSphereApiService.getAdminExaminations();
        case AdminOpsSection.fees:
          data = await UniSphereApiService.getAdminInvoices();
        case AdminOpsSection.payments:
          data = await UniSphereApiService.getAdminPaymentTransactions();
        case AdminOpsSection.hostel:
          final results = await Future.wait([
            UniSphereApiService.getHostelBuildings(),
            UniSphereApiService.getHostelRooms(),
            UniSphereApiService.getHostelAllocations(),
            UniSphereApiService.getAdminHostelComplaints(),
          ]);
          data = [
            ..._tagRecords(results[0], 'Building'),
            ..._tagRecords(results[1], 'Room'),
            ..._tagRecords(results[2], 'Allocation'),
            ..._tagRecords(results[3], 'Complaint'),
          ];
        case AdminOpsSection.transport:
          final routes = await UniSphereApiService.getTransportRoutes();
          final stopGroups = await Future.wait(
            routes.map(
              (route) => UniSphereApiService.getTransportRouteStops(
                route['id'] as int,
              ),
            ),
          );
          final results = await Future.wait<List<Map<String, dynamic>>>([
            UniSphereApiService.getTransportVehicles(),
            UniSphereApiService.getTransportAssignments(),
            UniSphereApiService.getTransportAllocations(),
            UniSphereApiService.getAdminTransportIssues(),
          ]);
          data = [
            ..._tagRecords(routes, 'Route'),
            ..._tagRecords(
              stopGroups.expand((group) => group).toList(),
              'Stop',
            ),
            ..._tagRecords(results[0], 'Vehicle'),
            ..._tagRecords(results[1], 'Assignment'),
            ..._tagRecords(results[2], 'Allocation'),
            ..._tagRecords(results[3], 'Issue'),
          ];
        case AdminOpsSection.notifications:
          data = await UniSphereApiService.getNotificationTemplates();
        case AdminOpsSection.earlyWarning:
          data = await UniSphereApiService.getAdminEarlyWarnings();
      }
      final contextData = await Future.wait<dynamic>([
        UniSphereApiService.getAdminCourses(),
        UniSphereApiService.getSemesters(),
        UniSphereApiService.getCourseOfferings(),
        UniSphereApiService.getAdminStudents(),
        UniSphereApiService.getProgrammes(),
        UniSphereApiService.getDepartments(),
      ]);
      if (mounted) {
        setState(() {
          _items = data;
          _courses = List<Map<String, dynamic>>.from(contextData[0] as List);
          _semesters = List<Map<String, dynamic>>.from(contextData[1] as List);
          _offerings = List<Map<String, dynamic>>.from(contextData[2] as List);
          _students = (contextData[3] as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          _programmes = List<Map<String, dynamic>>.from(contextData[4] as List);
          _departments = List<Map<String, dynamic>>.from(
            contextData[5] as List,
          );
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Unable to load $_title.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _tagRecords(
    List<Map<String, dynamic>> records,
    String type,
  ) => records.map((record) => {...record, '_record_type': type}).toList();

  Future<void> _create() async {
    switch (widget.section) {
      case AdminOpsSection.semesters:
        await _createSemester();
      case AdminOpsSection.courses:
        await _createCourse();
      case AdminOpsSection.enrollment:
        await _createOfferingOrEnrollment();
      case AdminOpsSection.timetable:
        await _createTimetableEntry();
      case AdminOpsSection.attendance:
        await _createAttendance();
      case AdminOpsSection.examinations:
        await _createExamination();
      case AdminOpsSection.fees:
        await _createFee();
      case AdminOpsSection.payments:
        _message(
          'Payments are created from student invoices and appear here after initiation.',
        );
      case AdminOpsSection.hostel:
        await _createHostel();
      case AdminOpsSection.transport:
        await _createTransport();
      case AdminOpsSection.notifications:
        await _sendNotification();
      case AdminOpsSection.earlyWarning:
        _message(
          'Early warnings are generated from real student assessment/attendance data.',
        );
    }
  }

  Future<void> _createSemester() async {
    final f = await _form([
      'Semester number',
      'Name',
      'Academic year (optional)',
    ]);
    if (f == null) return;
    await _run(
      () => UniSphereApiService.createSemester(
        number: int.parse(f[0]),
        name: f[1],
        academicYear: f[2].isEmpty ? null : f[2],
      ),
    );
  }

  Future<void> _createCourse() async {
    final department = await _pickRecord(
      title: 'Select academic unit',
      items: _departments,
      label: (item) => item['name']?.toString() ?? 'Academic unit',
      subtitle: (item) => item['code']?.toString() ?? '',
    );
    if (department == null) return;
    final f = await _form(['Course code', 'Course name', 'Credits']);
    if (f == null) return;
    await _run(
      () => UniSphereApiService.createCourse(
        code: f[0],
        name: f[1],
        credits: int.parse(f[2]),
        departmentId: department['id'] as int,
      ),
    );
  }

  Future<void> _createOfferingOrEnrollment() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Enrollment'),
        content: const Text(
          'Create a course offering or enroll a student in an existing offering.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, 'offering'),
            child: const Text('Course offering'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, 'enroll'),
            child: const Text('Enroll student'),
          ),
        ],
      ),
    );
    if (choice == 'offering') {
      final course = await _pickRecord(
        title: 'Select course',
        items: _courses,
        label: (item) => '${item['code']}  ${item['name']}',
        subtitle: (item) => '${item['credits']} credits',
      );
      if (course == null) return;
      final semester = await _pickRecord(
        title: 'Select semester',
        items: _semesters,
        label: (item) =>
            item['name']?.toString() ?? 'Semester ${item['number']}',
        subtitle: (item) =>
            item['academic_year']?.toString() ?? 'Academic year not set',
      );
      if (semester == null) return;
      final f = await _form([
        'Academic session',
        'Section (optional)',
        'Faculty name (optional)',
        'Capacity (optional)',
      ]);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createCourseOffering(
          courseId: course['id'] as int,
          semesterId: semester['id'] as int,
          academicSession: f[0],
          section: f[1].isEmpty ? null : f[1],
          facultyName: f[2].isEmpty ? null : f[2],
          capacity: f[3].isEmpty ? null : int.parse(f[3]),
        ),
      );
    } else if (choice == 'enroll') {
      final student = await _pickRecord(
        title: 'Select student',
        items: _students,
        label: (item) => item['full_name']?.toString() ?? 'Student',
        subtitle: (item) => '${item['uni_id']}  |  ${item['programme']}',
      );
      if (student == null) return;
      final offering = await _pickRecord(
        title: 'Select course offering',
        items: _offerings,
        label: (item) =>
            _courseForItem(item)?['name']?.toString() ??
            'Offering #${item['id']}',
        subtitle: (item) =>
            '${item['academic_session']}  |  ${item['faculty_name'] ?? 'Faculty not assigned'}',
      );
      if (offering == null) return;
      await _run(
        () => UniSphereApiService.enrollStudent(
          studentId: student['id'] as int,
          courseOfferingId: offering['id'] as int,
        ),
      );
    }
  }

  Future<void> _createTimetableEntry() async {
    final offering = await _pickRecord(
      title: 'Select course offering',
      items: _offerings,
      label: (item) =>
          _courseForItem(item)?['name']?.toString() ??
          'Offering #${item['id']}',
      subtitle: (item) =>
          '${item['academic_session']}  |  ${item['faculty_name'] ?? 'Faculty not assigned'}',
    );
    if (offering == null) return;
    final f = await _form([
      'Day of week (1=Mon, 7=Sun)',
      'Start time (HH:MM)',
      'End time (HH:MM)',
      'Room (optional)',
      'Building (optional)',
      'Faculty name (optional)',
    ]);
    if (f == null) return;
    await _run(
      () => UniSphereApiService.createTimetableEntry(
        courseOfferingId: offering['id'] as int,
        dayOfWeek: int.parse(f[0]),
        startTime: f[1],
        endTime: f[2],
        room: f[3].isEmpty ? null : f[3],
        building: f[4].isEmpty ? null : f[4],
        facultyName: f[5].isEmpty ? null : f[5],
      ),
    );
  }

  Future<void> _createExamination() async {
    final semester = await _pickRecord(
      title: 'Select semester',
      items: _semesters,
      label: (item) => item['name']?.toString() ?? 'Semester ${item['number']}',
      subtitle: (item) =>
          item['academic_year']?.toString() ?? 'Academic year not set',
    );
    if (semester == null) return;
    final f = await _form([
      'Examination name',
      'Examination type',
      'Academic session',
      'Start date (optional)',
      'End date (optional)',
      'Registration start (optional)',
      'Registration end (optional)',
    ]);
    if (f == null) return;
    await _run(
      () => UniSphereApiService.createExamination(
        name: f[0],
        examType: f[1],
        academicSession: f[2],
        semesterId: semester['id'] as int,
        startDate: f[3].isEmpty ? null : f[3],
        endDate: f[4].isEmpty ? null : f[4],
        registrationStart: f[5].isEmpty ? null : f[5],
        registrationEnd: f[6].isEmpty ? null : f[6],
      ),
    );
  }

  Future<void> _createAttendance() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Attendance'),
        content: const Text(
          'Create a class session or record attendance for an existing session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, 'session'),
            child: const Text('New session'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, 'record'),
            child: const Text('Record attendance'),
          ),
        ],
      ),
    );
    if (choice == 'session') {
      final offering = await _pickRecord(
        title: 'Select course offering',
        items: _offerings,
        label: (item) =>
            _courseForItem(item)?['name']?.toString() ??
            'Offering #${item['id']}',
        subtitle: (item) =>
            '${item['academic_session']}  |  ${item['faculty_name'] ?? 'Faculty not assigned'}',
      );
      if (offering == null) return;
      final f = await _form([
        'Date (YYYY-MM-DD)',
        'Start time (optional)',
        'End time (optional)',
        'Topic (optional)',
        'Faculty (optional)',
      ]);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createAttendanceSession(
          courseOfferingId: offering['id'] as int,
          sessionDate: f[0],
          startTime: f[1].isEmpty ? null : f[1],
          endTime: f[2].isEmpty ? null : f[2],
          topic: f[3].isEmpty ? null : f[3],
          facultyName: f[4].isEmpty ? null : f[4],
        ),
      );
    } else if (choice == 'record') {
      final f = await _form([
        'Session ID',
        'Student ID',
        'Status (Present/Absent/Late/Excused)',
        'Remarks (optional)',
      ]);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.recordAttendanceBulk(
          sessionId: int.parse(f[0]),
          records: [
            {
              'student_id': int.parse(f[1]),
              'status': f[2],
              'remarks': f[3].isEmpty ? null : f[3],
            },
          ],
        ),
      );
    }
  }

  Future<void> _createFee() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Fees & Payments'),
        content: const Text(
          'Create a fee structure/invoice or record a payment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, 'structure'),
            child: const Text('Fee structure'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'invoice'),
            child: const Text('Invoice'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, 'payment'),
            child: const Text('Record payment'),
          ),
        ],
      ),
    );
    if (choice == 'structure') {
      final programme = await _pickRecord(
        title: 'Select programme',
        items: _programmes,
        label: (item) => item['name']?.toString() ?? 'Programme',
        subtitle: (item) =>
            '${item['category'] ?? 'Programme'}  |  ${item['duration_years']} years',
      );
      if (programme == null) return;
      final f = await _form([
        'Semester',
        'Academic session',
        'Fee type',
        'Amount',
      ]);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createFeeStructure(
          programmeId: programme['id'] as int,
          semester: int.parse(f[0]),
          academicSession: f[1],
          feeType: f[2],
          amount: double.parse(f[3]),
        ),
      );
    } else if (choice == 'invoice') {
      final student = await _pickRecord(
        title: 'Select student',
        items: _students,
        label: (item) => item['full_name']?.toString() ?? 'Student',
        subtitle: (item) => '${item['uni_id']}  |  ${item['programme']}',
      );
      if (student == null) return;
      final f = await _form([
        'Academic session',
        'Semester',
        'Fee type',
        'Description',
        'Amount',
        'Due date (optional)',
      ]);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createInvoice(
          studentId: student['id'] as int,
          academicSession: f[0],
          semester: int.parse(f[1]),
          dueDate: f[5].isEmpty ? null : f[5],
          items: [
            {
              'fee_type': f[2],
              'description': f[3].isEmpty ? null : f[3],
              'amount': double.parse(f[4]),
            },
          ],
        ),
      );
    } else if (choice == 'payment') {
      final invoice = await _pickRecord(
        title: 'Select invoice',
        items: _items
            .where((item) => (item['outstanding_amount'] as num? ?? 0) > 0)
            .toList(),
        label: (item) =>
            item['invoice_number']?.toString() ?? 'Invoice #${item['id']}',
        subtitle: (item) {
          final student = _students
              .where((value) => value['id'] == item['student_id'])
              .firstOrNull;
          return '${student?['full_name'] ?? 'Student'}  |  INR ${item['outstanding_amount']} outstanding';
        },
      );
      if (invoice == null) return;
      final f = await _form(['Payment amount']);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.recordFeePayment(
          invoiceId: invoice['id'] as int,
          amount: double.parse(f[0]),
        ),
      );
    }
  }

  Future<void> _createHostel() async {
    final choice = await _chooseOperation(
      title: 'Hostel administration',
      subtitle: 'Choose what you want to add.',
      options: const [
        ('building', 'Building', Icons.apartment_rounded),
        ('room', 'Room', Icons.meeting_room_rounded),
        ('allocation', 'Student allocation', Icons.bed_rounded),
      ],
    );
    if (choice == 'building') {
      final f = await _form([
        'Building name',
        'Code',
        'Hostel type',
        'Gender (optional)',
        'Address (optional)',
        'Floors (optional)',
      ]);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createHostelBuilding(
          name: f[0],
          code: f[1],
          hostelType: f[2].isEmpty ? 'general' : f[2],
          gender: f[3].isEmpty ? null : f[3],
          address: f[4].isEmpty ? null : f[4],
          totalFloors: f[5].isEmpty ? null : int.parse(f[5]),
        ),
      );
    } else if (choice == 'room') {
      final building = await _pickRecord(
        title: 'Select hostel building',
        items: await UniSphereApiService.getHostelBuildings(),
        label: (item) => item['name']?.toString() ?? 'Building #${item['id']}',
        subtitle: (item) => '${item['code']} | ${item['hostel_type']}',
      );
      if (building == null) return;
      final f = await _form([
        'Room number',
        'Floor (optional)',
        'Room type',
        'Capacity',
      ]);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createHostelRoom(
          buildingId: building['id'] as int,
          roomNumber: f[0],
          floorNumber: f[1].isEmpty ? null : int.parse(f[1]),
          roomType: f[2].isEmpty ? 'shared' : f[2],
          capacity: int.parse(f[3]),
        ),
      );
    } else if (choice == 'allocation') {
      final students = (await UniSphereApiService.getAdminStudents())
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final student = await _pickRecord(
        title: 'Select student',
        items: students,
        label: (item) =>
            item['full_name']?.toString() ?? 'Student #${item['id']}',
        subtitle: (item) =>
            '${item['uni_id'] ?? '-'} | ${item['programme'] ?? '-'}',
      );
      if (student == null) return;
      final room = await _pickRecord(
        title: 'Select available room',
        items: (await UniSphereApiService.getHostelRooms())
            .where(
              (item) =>
                  (item['occupied_count'] as num? ?? 0) <
                  (item['capacity'] as num? ?? 0),
            )
            .toList(),
        label: (item) => 'Room ${item['room_number']}',
        subtitle: (item) =>
            '${item['room_type']} | ${item['occupied_count']}/${item['capacity']} occupied',
      );
      if (room == null) return;
      final f = await _form(['Remarks (optional)']);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createHostelAllocation(
          studentId: student['id'] as int,
          roomId: room['id'] as int,
          remarks: f[0].isEmpty ? null : f[0],
        ),
      );
    }
  }

  Future<void> _createTransport() async {
    final choice = await _chooseOperation(
      title: 'Transport administration',
      subtitle: 'Build the route first, then add stops and a vehicle.',
      options: const [
        ('route', 'Route', Icons.route_rounded),
        ('stop', 'Route stop', Icons.pin_drop_rounded),
        ('vehicle', 'Vehicle', Icons.directions_bus_rounded),
        ('assignment', 'Route vehicle', Icons.sync_alt_rounded),
        ('allocation', 'Student allocation', Icons.badge_rounded),
      ],
    );
    if (choice == 'route') {
      final f = await _form(['Route name', 'Code', 'Description (optional)']);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createTransportRoute(
          name: f[0],
          code: f[1],
          description: f[2].isEmpty ? null : f[2],
        ),
      );
    } else if (choice == 'stop') {
      final route = await _pickRecord(
        title: 'Select route',
        items: await UniSphereApiService.getTransportRoutes(),
        label: (item) => item['name']?.toString() ?? 'Route #${item['id']}',
        subtitle: (item) => item['code']?.toString() ?? '',
      );
      if (route == null) return;
      final f = await _form([
        'Stop name',
        'Sequence number',
        'Pickup time (optional)',
        'Landmark (optional)',
      ]);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createTransportStop(
          routeId: route['id'] as int,
          name: f[0],
          sequenceNumber: int.parse(f[1]),
          pickupTime: f[2].isEmpty ? null : f[2],
          landmark: f[3].isEmpty ? null : f[3],
        ),
      );
    } else if (choice == 'vehicle') {
      final f = await _form([
        'Vehicle number',
        'Vehicle type',
        'Capacity',
        'Driver name (optional)',
        'Driver contact (optional)',
      ]);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createTransportVehicle(
          vehicleNumber: f[0],
          vehicleType: f[1].isEmpty ? 'bus' : f[1],
          capacity: int.parse(f[2]),
          driverName: f[3].isEmpty ? null : f[3],
          driverContact: f[4].isEmpty ? null : f[4],
        ),
      );
    } else if (choice == 'assignment') {
      final route = await _pickRecord(
        title: 'Select route',
        items: await UniSphereApiService.getTransportRoutes(),
        label: (item) => item['name']?.toString() ?? 'Route #${item['id']}',
        subtitle: (item) => item['code']?.toString() ?? '',
      );
      if (route == null) return;
      final vehicle = await _pickRecord(
        title: 'Select vehicle',
        items: await UniSphereApiService.getTransportVehicles(),
        label: (item) =>
            item['vehicle_number']?.toString() ?? 'Vehicle #${item['id']}',
        subtitle: (item) =>
            '${item['vehicle_type']} | Capacity ${item['capacity']}',
      );
      if (vehicle == null) return;
      final f = await _form(['Academic session']);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createTransportAssignment(
          routeId: route['id'] as int,
          vehicleId: vehicle['id'] as int,
          academicSession: f[0],
        ),
      );
    } else if (choice == 'allocation') {
      final students = (await UniSphereApiService.getAdminStudents())
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      final student = await _pickRecord(
        title: 'Select student',
        items: students,
        label: (item) =>
            item['full_name']?.toString() ?? 'Student #${item['id']}',
        subtitle: (item) =>
            '${item['uni_id'] ?? '-'} | ${item['programme'] ?? '-'}',
      );
      if (student == null) return;
      final route = await _pickRecord(
        title: 'Select route',
        items: await UniSphereApiService.getTransportRoutes(),
        label: (item) => item['name']?.toString() ?? 'Route #${item['id']}',
        subtitle: (item) => item['code']?.toString() ?? '',
      );
      if (route == null) return;
      final stop = await _pickRecord(
        title: 'Select boarding stop',
        items: await UniSphereApiService.getTransportRouteStops(
          route['id'] as int,
        ),
        label: (item) => item['name']?.toString() ?? 'Stop #${item['id']}',
        subtitle: (item) =>
            '${item['pickup_time'] ?? 'Time not set'} | Stop ${item['sequence_number']}',
      );
      if (stop == null) return;
      final f = await _form(['Academic session', 'Remarks (optional)']);
      if (f == null) return;
      await _run(
        () => UniSphereApiService.createTransportAllocation(
          studentId: student['id'] as int,
          routeId: route['id'] as int,
          stopId: stop['id'] as int,
          academicSession: f[0],
          remarks: f[1].isEmpty ? null : f[1],
        ),
      );
    }
  }

  Future<void> _sendNotification() async {
    final f = await _form([
      'Recipient user ID',
      'Category',
      'Title',
      'Message',
      'Priority',
    ]);
    if (f == null) return;
    await _run(
      () => UniSphereApiService.sendNotification(
        recipientUserId: int.parse(f[0]),
        category: f[1],
        title: f[2],
        message: f[3],
        priority: f[4].isEmpty ? 'normal' : f[4],
      ),
    );
  }

  Future<String?> _chooseOperation({
    required String title,
    required String subtitle,
    required List<(String, String, IconData)> options,
  }) => showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: options
                  .map(
                    (option) => SizedBox(
                      width: 158,
                      height: 82,
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext, option.$1),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(option.$3, size: 22),
                            const SizedBox(height: 7),
                            Text(
                              option.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );

  Future<Map<String, dynamic>?> _pickRecord({
    required String title,
    required List<Map<String, dynamic>> items,
    required String Function(Map<String, dynamic>) label,
    required String Function(Map<String, dynamic>) subtitle,
  }) async {
    if (items.isEmpty) {
      _message('No available records. Create the required record first.');
      return null;
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 520,
          height: items.length > 5 ? 430 : null,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final item = items[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 5,
                ),
                leading: CircleAvatar(
                  child: Text(item['id']?.toString() ?? '?'),
                ),
                title: Text(
                  label(item),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(subtitle(item)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pop(dialogContext, item),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<List<String>?> _form(List<String> labels) async {
    return showDialog<List<String>>(
      context: context,
      builder: (_) => _AdminOperationFormDialog(
        title: 'Create / Update $_title',
        labels: labels,
      ),
    );
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    try {
      await action();
      if (mounted) {
        _message('Saved successfully.');
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    } catch (e) {
      if (mounted) _message('Operation failed: $e');
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF172554),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Live administration through the UniSphere API.',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh),
                  ),
                  if (widget.section != AdminOpsSection.earlyWarning &&
                      widget.section != AdminOpsSection.payments)
                    FilledButton.icon(
                      onPressed: _loading ? null : _create,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (!_loading && _error == null) ...[
                _summaryStrip(),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search this workspace',
                  ),
                ),
                const SizedBox(height: 18),
              ],
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 40),
                        const SizedBox(height: 10),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filteredItems.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(28),
                    child: Center(
                      child: Text(
                        'No records match this view. Change the search or add a new record.',
                      ),
                    ),
                  ),
                )
              else
                ..._filteredItems.take(150).map(_recordCard),
              if (!_loading && _error == null && _filteredItems.length > 150)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Showing 150 of ${_filteredItems.length} records. Use search to find a specific record.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recordCard(Map<String, dynamic> item) {
    final id = item['id'];
    final recordType = item['_record_type']?.toString();
    var title =
        item['name'] ??
        item['title'] ??
        item['room_number'] ??
        item['vehicle_number'] ??
        item['code'] ??
        item['invoice_number'] ??
        item['complaint_number'] ??
        item['issue_number'] ??
        'Record #$id';
    var subtitle = <String?>[
      recordType,
      if (item['status'] != null) 'Status: ${item['status']}',
      if (item['academic_session'] != null)
        'Session: ${item['academic_session']}',
      if (item['student_id'] != null) 'Student: ${item['student_id']}',
      if (item['building_id'] != null) 'Building: ${item['building_id']}',
      if (item['route_id'] != null) 'Route: ${item['route_id']}',
      if (item['capacity'] != null) 'Capacity: ${item['capacity']}',
      if (item['course_offering_id'] != null)
        'Offering: ${item['course_offering_id']}',
      if (item['semester_id'] != null) 'Semester: ${item['semester_id']}',
      if (item['outstanding_amount'] != null)
        'Outstanding: ${item['outstanding_amount']}',
      if (item['severity'] != null) 'Severity: ${item['severity']}',
      if (item['message'] != null) item['message'].toString(),
    ].whereType<String>().join(' | ');

    final course = _courseForItem(item);
    final semester = _semesterForItem(item);
    final student = _students
        .where((value) => value['id'] == item['student_id'])
        .firstOrNull;
    final programme = _programmes
        .where((value) => value['id'] == item['programme_id'])
        .firstOrNull;
    final department = _departments
        .where((value) => value['id'] == item['department_id'])
        .firstOrNull;
    switch (widget.section) {
      case AdminOpsSection.semesters:
        title = item['name'] ?? 'Semester ${item['number']}';
        subtitle =
            'Semester ${item['number']}  |  ${item['academic_year'] ?? 'Academic year not set'}';
      case AdminOpsSection.courses:
        title = '${item['code'] ?? '-'}  ${item['name'] ?? 'Course'}';
        subtitle =
            '${item['credits'] ?? 0} credits  |  ${department?['name'] ?? 'University-wide course'}${item['code']?.toString().startsWith('DEMO-') == true ? '  |  Demo curriculum' : ''}';
      case AdminOpsSection.enrollment:
        title = course == null
            ? 'Course offering #${item['id']}'
            : '${course['code']}  ${course['name']}';
        subtitle =
            '${semester?['name'] ?? 'Semester ${item['semester_id']}'}  |  ${item['academic_session']}  |  ${item['faculty_name'] ?? 'Faculty not assigned'}  |  Capacity ${item['capacity'] ?? 'open'}';
      case AdminOpsSection.timetable:
        title = course == null
            ? 'Timetable entry #${item['id']}'
            : '${course['code']}  ${course['name']}';
        subtitle =
            '${_dayName(item['day_of_week'] as int?)}  ${item['start_time']} - ${item['end_time']}  |  ${item['building'] ?? 'Building not set'}, ${item['room'] ?? 'Room not set'}  |  ${item['faculty_name'] ?? 'Faculty not assigned'}';
      case AdminOpsSection.attendance:
        title = course == null
            ? (item['topic'] ?? 'Attendance session')
            : '${course['code']}  ${course['name']}';
        subtitle =
            '${item['session_date']}  |  ${item['topic'] ?? 'Topic not set'}  |  ${item['faculty_name'] ?? 'Faculty not assigned'}  |  ${item['is_locked'] == true ? 'Locked' : 'Open'}';
      case AdminOpsSection.examinations:
        title = item['name'] ?? 'Examination';
        subtitle =
            '${item['exam_type'] ?? 'Examination'}  |  ${semester?['name'] ?? 'Semester ${item['semester_id']}'}  |  ${item['academic_session']}  |  ${item['start_date'] ?? 'Dates not scheduled'}';
      case AdminOpsSection.fees:
        title = item['invoice_number'] ?? 'Fee invoice #${item['id']}';
        subtitle =
            '${student?['full_name'] ?? 'Student #${item['student_id']}'} (${student?['uni_id'] ?? '-'})  |  INR ${item['total_amount'] ?? 0}  |  Paid INR ${item['paid_amount'] ?? 0}  |  Outstanding INR ${item['outstanding_amount'] ?? 0}';
      case AdminOpsSection.payments:
        title = item['transaction_number'] ?? 'Transaction #${item['id']}';
        subtitle =
            '${student?['full_name'] ?? 'Student #${item['student_id']}'}  |  INR ${item['amount'] ?? 0}  |  ${item['payment_method'] ?? 'online'}  |  ${item['status'] ?? 'initiated'}';
      default:
        if (programme != null) subtitle = '${programme['name']}  |  $subtitle';
    }

    final icon = switch (recordType) {
      'Building' => Icons.apartment_rounded,
      'Room' => Icons.meeting_room_rounded,
      'Complaint' => Icons.support_agent_rounded,
      'Route' => Icons.route_rounded,
      'Stop' => Icons.pin_drop_rounded,
      'Vehicle' => Icons.directions_bus_rounded,
      'Assignment' => Icons.sync_alt_rounded,
      'Allocation' => Icons.badge_rounded,
      'Issue' => Icons.report_problem_outlined,
      _ => null,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: icon == null
              ? Text(id?.toString() ?? '?')
              : Icon(icon, size: 20),
        ),
        title: Text(
          title.toString(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle.isEmpty
              ? item.entries
                    .map((e) => '${e.key}: ${e.value}')
                    .take(5)
                    .join(' | ')
              : subtitle,
        ),
        trailing: widget.section == AdminOpsSection.earlyWarning && id is int
            ? TextButton(
                onPressed: () => _run(
                  () => UniSphereApiService.resolveAdminEarlyWarning(id),
                ),
                child: const Text('Resolve'),
              )
            : null,
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredItems {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return _items;
    return _items.where((item) {
      final course = _courseForItem(item);
      final student = _students
          .where((value) => value['id'] == item['student_id'])
          .firstOrNull;
      return [
        ...item.values,
        course?['name'],
        course?['code'],
        student?['full_name'],
        student?['uni_id'],
      ].any((value) => value.toString().toLowerCase().contains(needle));
    }).toList();
  }

  Map<String, dynamic>? _courseForItem(Map<String, dynamic> item) {
    int? courseId = item['course_id'] as int?;
    final offeringId = item['course_offering_id'] as int?;
    if (courseId == null && offeringId != null) {
      final offering = _offerings
          .where((value) => value['id'] == offeringId)
          .firstOrNull;
      courseId = offering?['course_id'] as int?;
    }
    return _courses.where((value) => value['id'] == courseId).firstOrNull;
  }

  Map<String, dynamic>? _semesterForItem(Map<String, dynamic> item) {
    int? semesterId = item['semester_id'] as int?;
    final offeringId = item['course_offering_id'] as int?;
    if (semesterId == null && offeringId != null) {
      final offering = _offerings
          .where((value) => value['id'] == offeringId)
          .firstOrNull;
      semesterId = offering?['semester_id'] as int?;
    }
    return _semesters.where((value) => value['id'] == semesterId).firstOrNull;
  }

  Widget _summaryStrip() {
    final labels = switch (widget.section) {
      AdminOpsSection.semesters => (
        'Configured semesters',
        'Academic sequence',
      ),
      AdminOpsSection.courses => (
        'Course catalogue',
        '${_courses.fold<int>(0, (sum, item) => sum + (item['credits'] as int? ?? 0))} total credits',
      ),
      AdminOpsSection.enrollment => (
        'Course offerings',
        '${_items.where((item) => item['is_active'] == true).length} active',
      ),
      AdminOpsSection.timetable => (
        'Scheduled classes',
        '${_items.map((item) => item['day_of_week']).toSet().length} teaching days',
      ),
      AdminOpsSection.attendance => (
        'Class sessions',
        '${_items.where((item) => item['is_locked'] == true).length} locked',
      ),
      AdminOpsSection.examinations => (
        'Examinations',
        '${_items.where((item) => item['is_registration_open'] == true).length} open for registration',
      ),
      AdminOpsSection.fees => (
        'Student invoices',
        'INR ${_items.fold<double>(0, (sum, item) => sum + (item['outstanding_amount'] as num? ?? 0).toDouble()).toStringAsFixed(0)} outstanding',
      ),
      AdminOpsSection.payments => (
        'Payment transactions',
        'INR ${_items.where((item) => item['status'] == 'success').fold<double>(0, (sum, item) => sum + (item['amount'] as num? ?? 0).toDouble()).toStringAsFixed(0)} successful',
      ),
      _ => ('Live records', 'Connected to UniSphere API'),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF172554),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights_outlined, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labels.$1,
                  style: const TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${_items.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            labels.$2,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _dayName(int? day) =>
      const {
        1: 'Monday',
        2: 'Tuesday',
        3: 'Wednesday',
        4: 'Thursday',
        5: 'Friday',
        6: 'Saturday',
        7: 'Sunday',
      }[day] ??
      'Day not set';
}

class _AdminOperationFormDialog extends StatefulWidget {
  const _AdminOperationFormDialog({required this.title, required this.labels});

  final String title;
  final List<String> labels;

  @override
  State<_AdminOperationFormDialog> createState() =>
      _AdminOperationFormDialogState();
}

class _AdminOperationFormDialogState extends State<_AdminOperationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.labels.length,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validate(String label, String? value) {
    final text = value?.trim() ?? '';
    final optional = label.contains('optional');
    if (text.isEmpty) return optional ? null : 'Required';

    final normalized = label.toLowerCase();
    if ((normalized.contains('name') || normalized == 'code') &&
        text.length < 2) {
      return 'Enter at least 2 characters';
    }

    final isInteger =
        normalized.contains('floors') ||
        normalized == 'floor' ||
        normalized.contains('capacity') ||
        normalized.contains('sequence number');
    if (isInteger) {
      final number = int.tryParse(text);
      if (number == null) return 'Enter a whole number';
      if (normalized.contains('floor') && !normalized.contains('floors')) {
        if (number < 0) return 'Floor cannot be negative';
      } else if (number < 1) {
        return 'Enter a number greater than zero';
      }
      final maximumCapacity = widget.title.contains('Hostel') ? 20 : 200;
      if (normalized.contains('capacity') && number > maximumCapacity) {
        return 'Capacity cannot exceed $maximumCapacity';
      }
    }

    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _controllers.map((controller) => controller.text.trim()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < widget.labels.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: _controllers[index],
                      decoration: InputDecoration(
                        labelText: widget.labels[index],
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          _validate(widget.labels[index], value),
                      onFieldSubmitted: (_) {
                        if (index == widget.labels.length - 1) _submit();
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }
}
