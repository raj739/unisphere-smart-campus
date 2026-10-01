import '../models/analytics.dart';
import '../models/audit_log.dart';

import '../models/student_identity.dart';
import '../models/student_lifecycle.dart';

import 'package:unisphere_mobile/core/network/api_client.dart';
import 'package:unisphere_mobile/core/network/api_config.dart';

class UniSphereApiService {
  static Future<List<Map<String, dynamic>>> getObjectList(
    String endpoint,
  ) async {
    final data = await ApiClient.get(endpoint);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<Map<String, dynamic>> getRecommendations() async {
    final response = await ApiClient.get(ApiConfig.recommendations);

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> chatWithAI(
    String message, {
    String? sessionId,
    String language = 'auto',
  }) async {
    final response = await ApiClient.post(
      ApiConfig.aiV2Chat,
      body: {'message': message, 'session_id': sessionId, 'language': language},
    );

    return Map<String, dynamic>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getAIHistory() =>
      getObjectList(ApiConfig.aiV2History);

  static Future<List<Map<String, dynamic>>> getKnowledgeDocuments() =>
      getObjectList(ApiConfig.aiKnowledge);

  static Future<Map<String, dynamic>> createKnowledgeDocument({
    required String title,
    required String category,
    required String content,
    String? source,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      ApiConfig.aiKnowledge,
      body: {
        'title': title,
        'category': category,
        'content': content,
        'source': source,
      },
    ),
  );

  static Future<Map<String, dynamic>> deactivateKnowledgeDocument(
    int documentId,
  ) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.aiKnowledge}/$documentId/deactivate',
      body: {},
    ),
  );

  static Future<Map<String, dynamic>> getStudent() async {
    final data = await ApiClient.get(ApiConfig.studentMe);

    return Map<String, dynamic>.from(data);
  }

  static Future<StudentIdentity> getStudentIdentity() async {
    final data = await ApiClient.get(ApiConfig.identityMe);
    return StudentIdentity.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<StudentLifecycle> getMyLifecycle() async {
    final data = await ApiClient.get(ApiConfig.lifecycleMe);
    return StudentLifecycle.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<List<StudentLifecycleEvent>> getMyLifecycleHistory() async {
    final data = await ApiClient.get(ApiConfig.lifecycleHistoryMe);
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map(
          (event) =>
              StudentLifecycleEvent.fromJson(Map<String, dynamic>.from(event)),
        )
        .toList();
  }

  static Future<List<dynamic>> getCourses() async {
    final data = await ApiClient.get('${ApiConfig.enrollment}/me');

    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> getAttendance() async {
    final data = await ApiClient.get('${ApiConfig.attendanceV2}/me');

    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> getResults() async {
    final data = await ApiClient.get(ApiConfig.results);

    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> getTimetable() async {
    final data = await ApiClient.get('${ApiConfig.timetableV2}/me');

    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> getExaminations() async {
    final data = await ApiClient.get('${ApiConfig.examinationsV2}/me');

    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> getFees() async {
    final data = await ApiClient.get(ApiConfig.fees);

    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> getPayments() async {
    final data = await ApiClient.get('${ApiConfig.paymentsV2}/me');

    return List<dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getFeeSummary() async {
    final invoices = await getObjectList('${ApiConfig.feesV2}/me');
    return {
      'total_amount': invoices.fold<double>(
        0,
        (sum, item) => sum + ((item['total_amount'] as num?)?.toDouble() ?? 0),
      ),
      'paid_amount': invoices.fold<double>(
        0,
        (sum, item) => sum + ((item['paid_amount'] as num?)?.toDouble() ?? 0),
      ),
      'outstanding_amount': invoices.fold<double>(
        0,
        (sum, item) =>
            sum + ((item['outstanding_amount'] as num?)?.toDouble() ?? 0),
      ),
      'invoice_count': invoices.length,
      'invoices': invoices,
    };
  }

  static Future<List<Map<String, dynamic>>> getCertificates() =>
      getObjectList(ApiConfig.certificates);

  static Future<List<Map<String, dynamic>>> getCertificateTypes() =>
      getObjectList('${ApiConfig.certificates}/types');

  static Future<List<Map<String, dynamic>>> getMyCertificateRequests() =>
      getObjectList('${ApiConfig.certificates}/requests/me');

  static Future<Map<String, dynamic>> requestCertificate({
    required String certificateType,
    required String purpose,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.certificates}/requests',
      body: {
        'certificate_type': certificateType,
        'purpose': purpose,
        'delivery_mode': 'digital',
      },
    ),
  );

  static Future<Map<String, dynamic>> cancelCertificateRequest(
    int requestId,
  ) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.certificates}/requests/$requestId/cancel',
      body: {},
    ),
  );

  static Future<Map<String, dynamic>> getAdminCertificateOverview() async =>
      Map<String, dynamic>.from(
        await ApiClient.get('${ApiConfig.certificates}/admin/overview'),
      );

  static Future<Map<String, dynamic>> reviewCertificateRequest({
    required int requestId,
    required String action,
    String? remarks,
  }) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.certificates}/requests/$requestId/review',
      body: {'action': action, 'remarks': remarks},
    ),
  );

  static Future<Map<String, dynamic>> issueCertificate(int requestId) async =>
      Map<String, dynamic>.from(
        await ApiClient.post(
          '${ApiConfig.certificates}/requests/$requestId/issue',
          body: {},
        ),
      );

  static Future<Map<String, dynamic>> revokeCertificate(
    int certificateId,
  ) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.certificates}/issued/$certificateId/revoke',
      body: {},
    ),
  );

  static Future<Map<String, dynamic>> verifyCertificate(
    String certificateNumber,
  ) async => Map<String, dynamic>.from(
    await ApiClient.get(
      '${ApiConfig.certificates}/verify/$certificateNumber',
      authenticated: false,
    ),
  );

  static Future<List<int>> downloadCertificatePdf(int certificateId) =>
      ApiClient.getBytes('${ApiConfig.certificates}/issued/$certificateId/pdf');

  static Future<Map<String, dynamic>> getHostel() async {
    final data = await ApiClient.get(ApiConfig.hostel);

    return Map<String, dynamic>.from(data);
  }

  static Future<List<dynamic>> getHostelComplaints() async {
    final data = await ApiClient.get(ApiConfig.hostelComplaints);

    return List<dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getTransport() async {
    final data = await ApiClient.get(ApiConfig.transport);

    return Map<String, dynamic>.from(data);
  }

  static Future<List<dynamic>> getTransportIssues() async {
    final data = await ApiClient.get(ApiConfig.transportIssues);

    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> getHelpdeskTickets() async {
    final data = await ApiClient.get(ApiConfig.helpdesk);

    return List<dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> createHelpdeskTicket({
    required String subject,
    required String description,
    required String category,
    String priority = 'Medium',
  }) async {
    final data = await ApiClient.post(
      ApiConfig.helpdesk,
      body: {
        'subject': subject,
        'description': description,
        'category': category,
        'priority': priority,
      },
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final data = await ApiClient.get(ApiConfig.adminDashboard);

    return Map<String, dynamic>.from(data);
  }

  static Future<List<dynamic>> getAdminStudents() async {
    final data = await ApiClient.get(ApiConfig.adminStudents);

    return List<dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> registerStudent({
    required String fullName,
    required String email,
    required String password,
    required int departmentId,
    required String programme,
    required int currentSemester,
    String? universityId,
    String? enrollmentNumber,
    String? academicSession,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.adminStudents,
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'department_id': departmentId,
        'programme': programme,
        'current_semester': currentSemester,
        'university_id': universityId,
        'enrollment_number': enrollmentNumber,
        'academic_session': academicSession,
      },
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getUniversities() =>
      getObjectList('${ApiConfig.masterData}/universities');

  static Future<List<Map<String, dynamic>>> getDepartments() =>
      getObjectList('${ApiConfig.masterData}/departments');

  static Future<List<Map<String, dynamic>>> getProgrammes() =>
      getObjectList('${ApiConfig.masterData}/programmes');

  static Future<List<Map<String, dynamic>>> getAcademicSessions() =>
      getObjectList('${ApiConfig.masterData}/academic-sessions');

  static Future<List<Map<String, dynamic>>> getCurricula({
    int? programmeId,
    int? specializationId,
  }) {
    final query = <String>[];
    if (programmeId != null) query.add('programme_id=$programmeId');
    if (specializationId != null) {
      query.add('specialization_id=$specializationId');
    }
    final suffix = query.isEmpty ? '' : '?${query.join('&')}';
    return getObjectList('${ApiConfig.curricula}$suffix');
  }

  static Future<Map<String, dynamic>> getStudentAcademicPlan(
    int studentId,
  ) async => Map<String, dynamic>.from(
    await ApiClient.get('${ApiConfig.academicAdmin}/students/$studentId/plan'),
  );

  static Future<Map<String, dynamic>> assignStudentAcademicPlan({
    required int studentId,
    required int programmeId,
    required int? specializationId,
    required int curriculumId,
    required int academicSessionId,
    required int currentSemester,
    String section = 'A',
    bool autoEnroll = true,
    bool createStandardTimetable = false,
    bool createDemoExamPlan = false,
    bool createFeeInvoice = true,
  }) async => Map<String, dynamic>.from(
    await ApiClient.put(
      '${ApiConfig.academicAdmin}/students/$studentId/plan',
      body: {
        'programme_id': programmeId,
        'specialization_id': specializationId,
        'curriculum_id': curriculumId,
        'academic_session_id': academicSessionId,
        'current_semester': currentSemester,
        'section': section,
        'auto_enroll': autoEnroll,
        'create_standard_timetable': createStandardTimetable,
        'create_demo_exam_plan': createDemoExamPlan,
        'create_fee_invoice': createFeeInvoice,
      },
    ),
  );

  static Future<Map<String, dynamic>> publishStudentResult({
    required int studentId,
    required int courseId,
    required int semesterId,
    required double marks,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.academicAdmin}/students/$studentId/results',
      body: {'course_id': courseId, 'semester_id': semesterId, 'marks': marks},
    ),
  );

  static Future<Map<String, dynamic>> createUniversity({
    required String name,
    required String code,
    String? city,
    String? state,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.masterData}/universities',
      body: {'name': name, 'code': code, 'city': city, 'state': state},
    ),
  );

  static Future<Map<String, dynamic>> createDepartment({
    required String name,
    required String code,
    required int universityId,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.masterData}/departments',
      body: {'name': name, 'code': code, 'university_id': universityId},
    ),
  );

  static Future<Map<String, dynamic>> createProgramme({
    required String name,
    required String code,
    required int departmentId,
    required int durationYears,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.masterData}/programmes',
      body: {
        'name': name,
        'code': code,
        'department_id': departmentId,
        'duration_years': durationYears,
      },
    ),
  );

  static Future<Map<String, dynamic>> createAcademicSession({
    required String name,
    required int startYear,
    required int endYear,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.masterData}/academic-sessions',
      body: {'name': name, 'start_year': startYear, 'end_year': endYear},
    ),
  );

  static Future<List<dynamic>> getRiskStudents() async {
    final data = await ApiClient.get(ApiConfig.riskStudents);

    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> getInterventions() async {
    final data = await ApiClient.get(ApiConfig.interventions);

    return List<dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> createIntervention({
    required String uniId,
    required String interventionType,
    String? assignedTo,
    String priority = 'Medium',
    String? reason,
    String? dueDate,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.interventions,
      body: {
        'uni_id': uniId,
        'intervention_type': interventionType,
        'assigned_to': assignedTo,
        'priority': priority,
        'reason': reason,
        'due_date': dueDate,
      },
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> updateInterventionStatus({
    required int interventionId,
    required String status,
  }) async {
    final data = await ApiClient.patch(
      '${ApiConfig.interventions}/$interventionId/status',
      body: {'status': status},
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getParentStudent() async {
    final data = await ApiClient.get(ApiConfig.parentStudent);

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getParentAcademic() async {
    final data = await ApiClient.get(ApiConfig.parentAcademic);

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getParentFees() async {
    final data = await ApiClient.get(ApiConfig.parentFees);

    return Map<String, dynamic>.from(data);
  }

  static Future<List<dynamic>> getParentAlerts() async {
    final data = await ApiClient.get(ApiConfig.parentAlerts);

    return List<dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getParentOverview() async {
    final data = await ApiClient.get(ApiConfig.parentOverview);

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getParentProfileV2() async {
    final data = await ApiClient.get('${ApiConfig.parentV2}/profile');
    return Map<String, dynamic>.from(data);
  }

  static Future<List<dynamic>> getParentStudentsV2() async {
    final data = await ApiClient.get('${ApiConfig.parentV2}/students');
    return List<dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getParentDashboardV2(
    int studentId,
  ) async {
    final data = await ApiClient.get(
      '${ApiConfig.parentV2}/students/$studentId/dashboard',
    );
    return Map<String, dynamic>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getAdminParentAccounts() async {
    final data = await ApiClient.get('${ApiConfig.parentV2}/admin/accounts');
    return List<dynamic>.from(data)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> createParentAccount({
    required String fullName,
    required String email,
    required String password,
    required String relationshipType,
    required int studentId,
    String? phone,
  }) async {
    final data = await ApiClient.post(
      '${ApiConfig.parentV2}/admin/accounts',
      body: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'relationship_type': relationshipType,
        'student_id': studentId,
        'is_primary': true,
      },
    );
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> linkParentStudent({
    required int parentUserId,
    required int studentId,
    required String relationshipType,
    bool isPrimary = false,
  }) async {
    final data = await ApiClient.post(
      '${ApiConfig.parentV2}/links',
      body: {
        'parent_user_id': parentUserId,
        'student_id': studentId,
        'relationship_type': relationshipType,
        'is_primary': isPrimary,
      },
    );
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> voiceChat({
    required String transcript,
    String? sessionId,
    String language = 'en-IN',
  }) async {
    final response = await ApiClient.post(
      ApiConfig.voiceV2Chat,
      body: {
        'transcript': transcript,
        'session_id': sessionId,
        'language': language,
      },
    );

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> getMyRisk() async {
    final data = await ApiClient.get(ApiConfig.myRisk);
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getMyPredictiveResult() async {
    final data = await ApiClient.get(ApiConfig.myPredictiveResult);
    return Map<String, dynamic>.from(data);
  }

  static Future<List<dynamic>> getRiskAssessments() async {
    final data = await ApiClient.get(ApiConfig.riskAssessments);
    return List<dynamic>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getPredictiveRiskDashboard() =>
      getObjectList(ApiConfig.predictiveRiskDashboard);

  static Future<Map<String, dynamic>> recalculatePredictiveRisk() async =>
      Map<String, dynamic>.from(
        await ApiClient.post(ApiConfig.recalculatePredictiveRisk, body: {}),
      );

  static Future<Map<String, dynamic>> calculateRisk({
    required double attendance,
    required double academicPercentage,
    required double feeDue,
    required double engagement,
  }) async {
    final data = await ApiClient.post(
      '/api/v1/risk/calculate',
      body: {
        'attendance': attendance,
        'academic_percentage': academicPercentage,
        'fee_due': feeDue,
        'engagement': engagement,
      },
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<List<dynamic>> getMyEarlyWarnings() async {
    final data = await ApiClient.get(ApiConfig.earlyWarningsMine);
    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> getAllEarlyWarnings() async {
    final data = await ApiClient.get(ApiConfig.earlyWarnings);
    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> generateEarlyWarnings({
    required double attendance,
    required double academicPercentage,
    required double feeDue,
    required double engagement,
  }) async {
    final data = await ApiClient.post(
      '${ApiConfig.earlyWarnings}/generate',
      body: {
        'attendance': attendance,
        'academic_percentage': academicPercentage,
        'fee_due': feeDue,
        'engagement': engagement,
      },
    );
    return List<dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> resolveEarlyWarning(int warningId) async {
    final data = await ApiClient.patch(
      '${ApiConfig.earlyWarnings}/$warningId/resolve',
      body: {},
    );
    return Map<String, dynamic>.from(data);
  }

  static Future<List<dynamic>> getInterventionsV2({String? status}) async {
    final path = status == null
        ? ApiConfig.interventionsV2
        : '${ApiConfig.interventionsV2}?status=$status';

    final data = await ApiClient.get(path);
    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> getMyInterventionsV2() async {
    final data = await ApiClient.get('${ApiConfig.interventionsV2}/me');
    return List<dynamic>.from(data);
  }

  static Future<List<dynamic>> getStudentInterventionsV2(String uniId) async {
    final data = await ApiClient.get(
      '${ApiConfig.interventionsV2}/student/$uniId',
    );
    return List<dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> createInterventionV2({
    required String uniId,
    required String interventionType,
    String? assignedTo,
    String priority = 'Medium',
    String? reason,
    String? dueDate,
    int? warningId,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.interventionsV2,
      body: {
        'uni_id': uniId,
        'intervention_type': interventionType,
        'assigned_to': assignedTo,
        'priority': priority,
        'reason': reason,
        'due_date': dueDate,
        'warning_id': warningId,
      },
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> updateInterventionV2Status({
    required int interventionId,
    required String status,
    String? assignedTo,
    String? dueDate,
    String? notes,
    String? outcome,
  }) async {
    final data = await ApiClient.patch(
      '${ApiConfig.interventionsV2}/$interventionId/status',
      body: {
        'status': status,
        'assigned_to': assignedTo,
        'due_date': dueDate,
        'notes': notes,
        'outcome': outcome,
      },
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> reconcileInterventionWarnings() async {
    final data = await ApiClient.post(
      '${ApiConfig.interventionsV2}/reconcile-warnings',
      body: {},
    );
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> getAcademicPassport() async {
    final data = await ApiClient.get('${ApiConfig.academicPassport}/me');
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> generateAcademicPassport() async {
    final data = await ApiClient.post(
      '${ApiConfig.academicPassport}/generate',
      body: {},
    );
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> regenerateAcademicPassport() async {
    final data = await ApiClient.post(
      '${ApiConfig.academicPassport}/regenerate',
      body: {},
    );
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> verifyAcademicPassport(
    String verificationToken,
  ) async {
    final data = await ApiClient.get(
      '${ApiConfig.academicPassport}/verify/$verificationToken',
    );
    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> createPassportShareConsent({
    required String recipientName,
    String? recipientEmail,
    required String purpose,
    String scope = 'identity,academic',
    String? expiresAt,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.passportSharing,
      body: {
        'recipient_name': recipientName,
        'recipient_email': recipientEmail,
        'purpose': purpose,
        'scope': scope,
        'expires_at': expiresAt,
      },
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getMyPassportShareConsents() async {
    final data = await ApiClient.get('${ApiConfig.passportSharing}/me');

    return List<Map<String, dynamic>>.from(
      (data as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  static Future<Map<String, dynamic>> revokePassportShareConsent(
    int consentId,
  ) async {
    final data = await ApiClient.patch(
      '${ApiConfig.passportSharing}/$consentId/revoke',
      body: {},
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> verifyPassportShare(
    String shareToken,
  ) async {
    final data = await ApiClient.get(
      '${ApiConfig.passportSharing}/verify/$shareToken',
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<List<String>> getMyPermissions() async {
    final data = await ApiClient.get('${ApiConfig.rbac}/me');

    return List<String>.from(data as List);
  }

  static Future<List<Map<String, dynamic>>> getRbacPermissions() async {
    final data = await ApiClient.get('${ApiConfig.rbac}/permissions');

    return List<Map<String, dynamic>>.from(
      (data as List).map((item) => Map<String, dynamic>.from(item)),
    );
  }

  static Future<Map<String, dynamic>> initializeRbac() async {
    final data = await ApiClient.post('${ApiConfig.rbac}/initialize', body: {});

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> checkPermission(
    String permissionCode,
  ) async {
    final data = await ApiClient.post(
      '${ApiConfig.rbac}/check',
      body: {'permission_code': permissionCode},
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> assignRolePermission({
    required String role,
    required String permissionCode,
  }) async {
    final data = await ApiClient.post(
      '${ApiConfig.rbac}/role-permission',
      body: {'role': role, 'permission_code': permissionCode},
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> assignUserPermission({
    required int userId,
    required String permissionCode,
    required bool granted,
  }) async {
    final data = await ApiClient.post(
      '${ApiConfig.rbac}/user-permission',
      body: {
        'user_id': userId,
        'permission_code': permissionCode,
        'granted': granted,
      },
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<AuditLogListResponse> getMyAuditLogs({
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await ApiClient.get(
      '${ApiConfig.audit}/me?limit=$limit&offset=$offset',
    );

    return AuditLogListResponse.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<AuditLogListResponse> getAuditLogs({
    int limit = 50,
    int offset = 0,
    String? module,
    String? action,
    bool? success,
    int? userId,
    String? entityType,
  }) async {
    final params = <String, String>{'limit': '$limit', 'offset': '$offset'};

    if (module != null && module.isNotEmpty) {
      params['module'] = module;
    }

    if (action != null && action.isNotEmpty) {
      params['action'] = action;
    }

    if (success != null) {
      params['success'] = success.toString();
    }

    if (userId != null) {
      params['user_id'] = '$userId';
    }

    if (entityType != null && entityType.isNotEmpty) {
      params['entity_type'] = entityType;
    }

    final query = params.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');

    final data = await ApiClient.get('${ApiConfig.audit}?$query');

    return AuditLogListResponse.fromJson(Map<String, dynamic>.from(data));
  }

  static Future<Map<String, dynamic>> publishRealtimeEvent({
    required String channel,
    required String event,
    Map<String, dynamic> data = const {},
  }) async {
    final response = await ApiClient.post(
      '${ApiConfig.realtime}/publish',
      body: {'channel': channel, 'event': event, 'data': data},
    );

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> getRealtimeStatus() async {
    final response = await ApiClient.get('${ApiConfig.realtime}/status');

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> sendStudentRealtimeNotification({
    required String uniId,
    required String title,
    required String message,
    String notificationType = 'general',
    Map<String, dynamic> data = const {},
  }) async {
    final response = await ApiClient.post(
      '${ApiConfig.baseUrl}/events/student-notification',
      body: {
        'uni_id': uniId,
        'title': title,
        'message': message,
        'notification_type': notificationType,
        'data': data,
      },
    );

    return Map<String, dynamic>.from(response);
  }

  static Future<Map<String, dynamic>> sendAdminRealtimeNotification({
    required String title,
    required String message,
    String notificationType = 'system',
    Map<String, dynamic> data = const {},
  }) async {
    final response = await ApiClient.post(
      '${ApiConfig.baseUrl}/events/admin-notification',
      body: {
        'title': title,
        'message': message,
        'notification_type': notificationType,
        'data': data,
      },
    );

    return Map<String, dynamic>.from(response);
  }

  static Future<UniversityOverview> getUniversityAnalyticsOverview() async {
    final response = await ApiClient.get('${ApiConfig.analytics}/overview');

    return UniversityOverview.fromJson(Map<String, dynamic>.from(response));
  }

  static Future<List<RoleDistribution>> getAnalyticsRoleDistribution() async {
    final response = await ApiClient.get(
      '${ApiConfig.analytics}/role-distribution',
    );

    return (response as List<dynamic>)
        .map(
          (item) =>
              RoleDistribution.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  static Future<SystemHealth> getAnalyticsSystemHealth() async {
    final response = await ApiClient.get('${ApiConfig.analytics}/health');

    return SystemHealth.fromJson(Map<String, dynamic>.from(response));
  }

  static Future<Map<String, dynamic>> getRbacCoverage() async {
    final response = await ApiClient.get('${ApiConfig.rbac}/coverage');
    return Map<String, dynamic>.from(response);
  }

  static Future<List<int>> generateReport({
    required String format,
    required String title,
    required List<Map<String, dynamic>> rows,
  }) {
    return ApiClient.postBytes(
      '${ApiConfig.reports}/$format',
      body: {
        'title': title,
        'rows': rows,
        'metadata': {'source': 'admin_students'},
      },
    );
  }
  // ── Admin academic / operations APIs ────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSemesters() =>
      getObjectList(ApiConfig.semesters);

  static Future<List<Map<String, dynamic>>> getAdminTimetableEntries() =>
      getObjectList('${ApiConfig.timetableV2}/entries');

  static Future<List<Map<String, dynamic>>> getAdminStudentTimetable(
    int studentId,
  ) => getObjectList('${ApiConfig.timetableV2}/students/$studentId');

  static Future<Map<String, dynamic>> createTimetableEntry({
    required int courseOfferingId,
    required int dayOfWeek,
    required String startTime,
    required String endTime,
    String? room,
    String? building,
    String? facultyName,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.timetableV2}/entries',
      body: {
        'course_offering_id': courseOfferingId,
        'day_of_week': dayOfWeek,
        'start_time': startTime,
        'end_time': endTime,
        'room': room,
        'building': building,
        'faculty_name': facultyName,
      },
    ),
  );

  static Future<List<Map<String, dynamic>>> getAdminExaminations() =>
      getObjectList(ApiConfig.examinationsV2);

  static Future<List<Map<String, dynamic>>> getAdminExamRegistrations() =>
      getObjectList('${ApiConfig.examinationsV2}/registrations');

  static Future<List<Map<String, dynamic>>> getExaminationSchedules(
    int examinationId,
  ) => getObjectList('${ApiConfig.examinationsV2}/$examinationId/schedules');

  static Future<Map<String, dynamic>> updateExaminationRegistrationStatus({
    required int registrationId,
    required String status,
  }) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.examinationsV2}/registrations/$registrationId/status',
      body: {'status': status},
    ),
  );

  static Future<Map<String, dynamic>> setExaminationRegistrationLock({
    required int examinationId,
    required bool locked,
  }) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.examinationsV2}/$examinationId/registration-lock',
      body: {'locked': locked},
    ),
  );

  static Future<Map<String, dynamic>> lockExamination(
    int examinationId,
  ) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.examinationsV2}/$examinationId/lock',
      body: {'locked': true},
    ),
  );

  static Future<Map<String, dynamic>> createExamination({
    required String name,
    required String examType,
    required String academicSession,
    required int semesterId,
    String? startDate,
    String? endDate,
    String? registrationStart,
    String? registrationEnd,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      ApiConfig.examinationsV2,
      body: {
        'name': name,
        'exam_type': examType,
        'academic_session': academicSession,
        'semester_id': semesterId,
        'start_date': startDate,
        'end_date': endDate,
        'registration_start': registrationStart,
        'registration_end': registrationEnd,
      },
    ),
  );

  static Future<List<Map<String, dynamic>>> getAdminHelpdeskTickets() =>
      getObjectList('${ApiConfig.helpdeskV2}/tickets/admin/all');

  static Future<Map<String, dynamic>> createSemester({
    required int number,
    required String name,
    String? academicYear,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      ApiConfig.semesters,
      body: {'number': number, 'name': name, 'academic_year': academicYear},
    ),
  );

  static Future<List<Map<String, dynamic>>> getAdminCourses() =>
      getObjectList(ApiConfig.adminCourses);

  static Future<Map<String, dynamic>> createCourse({
    required String code,
    required String name,
    required int credits,
    int? departmentId,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      ApiConfig.adminCourses,
      body: {
        'code': code,
        'name': name,
        'credits': credits,
        'department_id': departmentId,
      },
    ),
  );

  static Future<List<Map<String, dynamic>>> getCourseOfferings() =>
      getObjectList('${ApiConfig.enrollment}/offerings');

  static Future<Map<String, dynamic>> createCourseOffering({
    required int courseId,
    required int semesterId,
    required String academicSession,
    String? section,
    String? facultyName,
    int? capacity,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.enrollment}/offerings',
      body: {
        'course_id': courseId,
        'semester_id': semesterId,
        'academic_session': academicSession,
        'section': section,
        'faculty_name': facultyName,
        'capacity': capacity,
      },
    ),
  );

  static Future<Map<String, dynamic>> enrollStudent({
    required int studentId,
    required int courseOfferingId,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.enrollment}/enroll',
      body: {'student_id': studentId, 'course_offering_id': courseOfferingId},
    ),
  );

  static Future<Map<String, dynamic>> updateEnrollmentStatus({
    required int enrollmentId,
    required String status,
  }) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.enrollment}/$enrollmentId/status',
      body: {'status': status},
    ),
  );

  static Future<List<Map<String, dynamic>>> getStudentCoursesAdmin(
    int studentId,
  ) async => getObjectList('${ApiConfig.enrollment}/students/$studentId');

  static Future<List<Map<String, dynamic>>> getAttendanceSessions() =>
      getObjectList('${ApiConfig.attendanceV2}/sessions');

  static Future<List<Map<String, dynamic>>> getAttendanceRoster(
    int sessionId,
  ) => getObjectList('${ApiConfig.attendanceV2}/sessions/$sessionId/roster');

  static Future<List<Map<String, dynamic>>> getAdminStudentAttendance(
    int studentId,
  ) => getObjectList('${ApiConfig.attendanceV2}/students/$studentId');

  static Future<Map<String, dynamic>> createAttendanceSession({
    required int courseOfferingId,
    required String sessionDate,
    String? startTime,
    String? endTime,
    String? topic,
    String? facultyName,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.attendanceV2}/sessions',
      body: {
        'course_offering_id': courseOfferingId,
        'session_date': sessionDate,
        'start_time': startTime,
        'end_time': endTime,
        'topic': topic,
        'faculty_name': facultyName,
      },
    ),
  );

  static Future<List<Map<String, dynamic>>> recordAttendanceBulk({
    required int sessionId,
    required List<Map<String, dynamic>> records,
  }) async => List<Map<String, dynamic>>.from(
    (await ApiClient.post(
      '${ApiConfig.attendanceV2}/sessions/$sessionId/bulk',
      body: {'records': records},
    ) as List).map((item) => Map<String, dynamic>.from(item as Map)),
  );

  static Future<Map<String, dynamic>> lockAttendanceSession(
    int sessionId,
  ) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.attendanceV2}/sessions/$sessionId/lock',
      body: {},
    ),
  );

  static Future<List<Map<String, dynamic>>> getFeeStructures() =>
      getObjectList('${ApiConfig.feesV2}/structures');

  static Future<Map<String, dynamic>> createFeeStructure({
    required int programmeId,
    required int semester,
    required String academicSession,
    required String feeType,
    required double amount,
    bool mandatory = true,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.feesV2}/structures',
      body: {
        'programme_id': programmeId,
        'semester': semester,
        'academic_session': academicSession,
        'fee_type': feeType,
        'amount': amount,
        'mandatory': mandatory,
      },
    ),
  );

  static Future<List<Map<String, dynamic>>> getAdminInvoices({
    int? studentId,
  }) => getObjectList(
    studentId == null
        ? '${ApiConfig.feesV2}/admin/invoices'
        : '${ApiConfig.feesV2}/admin/invoices?student_id=$studentId',
  );

  static Future<List<Map<String, dynamic>>> getAdminPaymentTransactions() =>
      getObjectList('${ApiConfig.paymentsV2}/admin/transactions');

  static Future<List<Map<String, dynamic>>> getAdminDocuments() =>
      getObjectList('${ApiConfig.documents}/admin/all');

  static Future<Map<String, dynamic>> createDigitalDocument({
    required int studentId,
    required String documentType,
    required String title,
    required String issueDate,
    String? validUntil,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      ApiConfig.documents,
      body: {
        'student_id': studentId,
        'document_type': documentType,
        'title': title,
        'issue_date': issueDate,
        'valid_until': validUntil,
      },
    ),
  );

  static Future<Map<String, dynamic>> updateDigitalDocumentStatus({
    required int documentId,
    required String status,
  }) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.documents}/$documentId/status',
      body: {'status': status},
    ),
  );

  static Future<Map<String, dynamic>> createExaminationSchedule({
    required int examinationId,
    required int courseId,
    required String examDate,
    required String startTime,
    required String endTime,
    String? room,
    String? building,
    int maxMarks = 100,
    int passingMarks = 40,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.examinationsV2}/schedules',
      body: {
        'examination_id': examinationId,
        'course_id': courseId,
        'exam_date': examDate,
        'start_time': startTime,
        'end_time': endTime,
        'room': room,
        'building': building,
        'max_marks': maxMarks,
        'passing_marks': passingMarks,
      },
    ),
  );

  static Future<Map<String, dynamic>> registerStudentForExamination({
    required int studentId,
    required int examinationId,
    required List<int> scheduleIds,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.examinationsV2}/admin/register',
      body: {
        'student_id': studentId,
        'examination_id': examinationId,
        'schedule_ids': scheduleIds,
      },
    ),
  );

  static Future<Map<String, dynamic>> createInvoice({
    required int studentId,
    required String academicSession,
    required int semester,
    String? dueDate,
    required List<Map<String, dynamic>> items,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.feesV2}/invoices',
      body: {
        'student_id': studentId,
        'academic_session': academicSession,
        'semester': semester,
        'due_date': dueDate,
        'items': items,
      },
    ),
  );

  static Future<Map<String, dynamic>> addFeeAdjustment({
    required int invoiceId,
    required String adjustmentType,
    required double amount,
    required String reason,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.feesV2}/invoices/$invoiceId/adjustments',
      body: {
        'adjustment_type': adjustmentType,
        'amount': amount,
        'reason': reason,
      },
    ),
  );

  static Future<Map<String, dynamic>> recordFeePayment({
    required int invoiceId,
    required double amount,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.feesV2}/invoices/$invoiceId/record-payment',
      body: {'amount': amount},
    ),
  );

  static Future<List<Map<String, dynamic>>> getHostelBuildings() =>
      getObjectList('${ApiConfig.hostelV2}/buildings');

  static Future<List<Map<String, dynamic>>> getHostelRooms() =>
      getObjectList('${ApiConfig.hostelV2}/rooms');

  static Future<List<Map<String, dynamic>>> getHostelAllocations() =>
      getObjectList('${ApiConfig.hostelV2}/allocations');

  static Future<Map<String, dynamic>> getAdminHostelOverview() async =>
      Map<String, dynamic>.from(
        await ApiClient.get('${ApiConfig.hostelV2}/admin/overview'),
      );

  static Future<List<Map<String, dynamic>>> getMyHostelAllocations() =>
      getObjectList('${ApiConfig.hostelV2}/me');

  static Future<List<Map<String, dynamic>>> getMyHostelComplaints() =>
      getObjectList('${ApiConfig.hostelV2}/complaints/me');

  static Future<List<Map<String, dynamic>>> getAdminHostelComplaints() =>
      getObjectList('${ApiConfig.hostelV2}/complaints/admin');

  static Future<Map<String, dynamic>> createHostelBuilding({
    required String name,
    required String code,
    String hostelType = 'general',
    String? gender,
    String? address,
    int? totalFloors,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.hostelV2}/buildings',
      body: {
        'name': name,
        'code': code,
        'hostel_type': hostelType,
        'gender': gender,
        'address': address,
        'total_floors': totalFloors,
      },
    ),
  );

  static Future<Map<String, dynamic>> createHostelRoom({
    required int buildingId,
    required String roomNumber,
    int? floorNumber,
    String roomType = 'shared',
    int capacity = 2,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.hostelV2}/rooms',
      body: {
        'building_id': buildingId,
        'room_number': roomNumber,
        'floor_number': floorNumber,
        'room_type': roomType,
        'capacity': capacity,
      },
    ),
  );

  static Future<Map<String, dynamic>> createHostelAllocation({
    required int studentId,
    required int roomId,
    String? remarks,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.hostelV2}/allocations',
      body: {'student_id': studentId, 'room_id': roomId, 'remarks': remarks},
    ),
  );

  static Future<Map<String, dynamic>> resolveHostelComplaint({
    required int complaintId,
    required String resolution,
  }) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.hostelV2}/complaints/$complaintId/resolve',
      body: {'resolution': resolution},
    ),
  );

  static Future<List<Map<String, dynamic>>> getTransportRoutes() =>
      getObjectList('${ApiConfig.transportV2}/routes');

  static Future<List<Map<String, dynamic>>> getTransportRouteStops(
    int routeId,
  ) => getObjectList('${ApiConfig.transportV2}/routes/$routeId/stops');

  static Future<List<Map<String, dynamic>>> getTransportVehicles() =>
      getObjectList('${ApiConfig.transportV2}/vehicles');

  static Future<List<Map<String, dynamic>>> getTransportAssignments() =>
      getObjectList('${ApiConfig.transportV2}/assignments');

  static Future<List<Map<String, dynamic>>> getTransportAllocations() =>
      getObjectList('${ApiConfig.transportV2}/allocations');

  static Future<Map<String, dynamic>> getAdminTransportOverview() async =>
      Map<String, dynamic>.from(
        await ApiClient.get('${ApiConfig.transportV2}/admin/overview'),
      );

  static Future<List<Map<String, dynamic>>> getMyTransportAllocations() =>
      getObjectList('${ApiConfig.transportV2}/me');

  static Future<List<Map<String, dynamic>>> getMyTransportIssues() =>
      getObjectList('${ApiConfig.transportV2}/issues/me');

  static Future<List<Map<String, dynamic>>> getAdminTransportIssues() =>
      getObjectList('${ApiConfig.transportV2}/issues/admin');

  static Future<Map<String, dynamic>> createTransportRoute({
    required String name,
    required String code,
    String? description,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.transportV2}/routes',
      body: {'name': name, 'code': code, 'description': description},
    ),
  );

  static Future<Map<String, dynamic>> createTransportStop({
    required int routeId,
    required String name,
    required int sequenceNumber,
    String? pickupTime,
    String? landmark,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.transportV2}/stops',
      body: {
        'route_id': routeId,
        'name': name,
        'sequence_number': sequenceNumber,
        'pickup_time': pickupTime,
        'landmark': landmark,
      },
    ),
  );

  static Future<Map<String, dynamic>> createTransportVehicle({
    required String vehicleNumber,
    String vehicleType = 'bus',
    int capacity = 40,
    String? driverName,
    String? driverContact,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.transportV2}/vehicles',
      body: {
        'vehicle_number': vehicleNumber,
        'vehicle_type': vehicleType,
        'capacity': capacity,
        'driver_name': driverName,
        'driver_contact': driverContact,
      },
    ),
  );

  static Future<Map<String, dynamic>> createTransportAssignment({
    required int routeId,
    required int vehicleId,
    required String academicSession,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.transportV2}/assignments',
      body: {
        'route_id': routeId,
        'vehicle_id': vehicleId,
        'academic_session': academicSession,
      },
    ),
  );

  static Future<Map<String, dynamic>> createTransportAllocation({
    required int studentId,
    required int routeId,
    required int stopId,
    required String academicSession,
    String? remarks,
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.transportV2}/allocations',
      body: {
        'student_id': studentId,
        'route_id': routeId,
        'stop_id': stopId,
        'academic_session': academicSession,
        'remarks': remarks,
      },
    ),
  );

  static Future<Map<String, dynamic>> resolveTransportIssue({
    required int issueId,
    required String resolution,
  }) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.transportV2}/issues/$issueId/resolve',
      body: {'resolution': resolution},
    ),
  );

  static Future<List<Map<String, dynamic>>> getNotificationTemplates() =>
      getObjectList('${ApiConfig.notificationsV2}/templates');

  static Future<List<Map<String, dynamic>>> getAdminNotificationDeliveries() =>
      getObjectList('${ApiConfig.notificationsV2}/admin/deliveries');

  static Future<Map<String, dynamic>> sendNotification({
    required int recipientUserId,
    required String category,
    required String title,
    required String message,
    String priority = 'normal',
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.notificationsV2}/send',
      body: {
        'recipient_user_id': recipientUserId,
        'category': category,
        'title': title,
        'message': message,
        'priority': priority,
      },
    ),
  );

  static Future<List<Map<String, dynamic>>> broadcastNotification({
    required List<int> recipientUserIds,
    required String category,
    required String title,
    required String message,
    String priority = 'normal',
  }) async => List<Map<String, dynamic>>.from(
    (await ApiClient.post(
      '${ApiConfig.notificationsV2}/broadcast',
      body: {
        'recipient_user_ids': recipientUserIds,
        'category': category,
        'title': title,
        'message': message,
        'priority': priority,
      },
    ) as List).map((item) => Map<String, dynamic>.from(item as Map)),
  );

  static Future<List<Map<String, dynamic>>> getAdminEarlyWarnings() =>
      getObjectList('${ApiConfig.earlyWarning}/students');

  static Future<Map<String, dynamic>> resolveAdminEarlyWarning(
    int warningId,
  ) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.earlyWarning}/$warningId/resolve',
      body: {},
    ),
  );

  static Future<List<Map<String, dynamic>>> getMyNotifications() =>
      getObjectList('${ApiConfig.notificationsV2}/me');

  static Future<Map<String, dynamic>> markNotificationRead(
    int notificationId,
  ) async => Map<String, dynamic>.from(
    await ApiClient.patch(
      '${ApiConfig.notificationsV2}/$notificationId/read',
      body: {},
    ),
  );

  static Future<Map<String, dynamic>> createHostelComplaint({
    required String category,
    required String title,
    required String description,
    String priority = 'normal',
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.hostelV2}/complaints',
      body: {
        'category': category,
        'title': title,
        'description': description,
        'priority': priority,
      },
    ),
  );

  static Future<Map<String, dynamic>> createTransportIssue({
    required String category,
    required String title,
    required String description,
    String priority = 'normal',
  }) async => Map<String, dynamic>.from(
    await ApiClient.post(
      '${ApiConfig.transportV2}/issues',
      body: {
        'category': category,
        'title': title,
        'description': description,
        'priority': priority,
      },
    ),
  );
}
