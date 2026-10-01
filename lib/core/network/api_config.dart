class ApiConfig {
  static String _baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  static String get baseUrl => _baseUrl;

  static set baseUrl(String url) {
    if (url.endsWith('/')) {
      _baseUrl = url.substring(0, url.length - 1);
    } else {
      _baseUrl = url;
    }
  }

  static String get login => '$baseUrl/auth/login';
  static String get studentMe => '$baseUrl/students/me';
  static String get identityMe => '$baseUrl/identity/me';
  static String get lifecycleMe => '$baseUrl/lifecycle/me';
  static String get lifecycleHistoryMe => '$baseUrl/lifecycle/me/history';
  static String get courses => '$baseUrl/academic/courses';
  static String get attendance => '$baseUrl/academic/attendance';
  static String get results => '$baseUrl/academic/results';
  static String get timetable => '$baseUrl/academic/timetable';
  static String get timetableV2 => '$baseUrl/timetable-v2';
  static String get examinations => '$baseUrl/academic/examinations';
  static String get examinationsV2 => '$baseUrl/examinations-v2';
  static String get fees => '$baseUrl/fees';
  static String get feePayments => '$baseUrl/fees/payments';
  static String get feeSummary => '$baseUrl/fees/summary';
  static String get certificates => '$baseUrl/certificates';
  static String get hostel => '$baseUrl/hostel';
  static String get hostelComplaints => '$baseUrl/hostel/complaints';
  static String get transport => '$baseUrl/transport';
  static String get transportIssues => '$baseUrl/transport/issues';
  static String get helpdesk => '$baseUrl/helpdesk';
  static String get helpdeskV2 => '$baseUrl/helpdesk-v2';
  static String get adminDashboard => '$baseUrl/admin/dashboard';
  static String get adminStudents => '$baseUrl/admin/students';
  static String get masterData => '$baseUrl/master-data';
  static String get documents => '$baseUrl/documents';
  static String get notifications => '$baseUrl/notifications-v2/me';
  static String get reports => '$baseUrl/reports';
  static String get riskStudents => '$baseUrl/risk/students';
  static String get interventions => '$baseUrl/interventions';
  static String get parentStudent => '$baseUrl/parent/student';
  static String get parentAcademic => '$baseUrl/parent/academic';
  static String get parentFees => '$baseUrl/parent/fees';
  static String get parentAlerts => '$baseUrl/parent/alerts';
  static String get parentOverview => '$baseUrl/parent/overview';
  static String get parentV2 => '$baseUrl/parent-v2';
  static String get aiChat => '$baseUrl/ai/chat';
  static String get aiKnowledge => '$baseUrl/ai/knowledge';
  static String get aiV2Chat => '$baseUrl/ai-v2/chat';
  static String get aiV2History => '$baseUrl/ai-v2/history';
  static String get voiceV2Chat => '$baseUrl/voice-v2/chat';
  static String get recommendations => '$baseUrl/recommendations/me';
  static String get myRisk => '$baseUrl/risk/me';
  static String get myPredictiveResult => '$baseUrl/risk/me/prediction';
  static String get riskAssessments => '$baseUrl/risk/students';
  static String get predictiveRiskDashboard => '$baseUrl/risk/dashboard';
  static String get recalculatePredictiveRisk => '$baseUrl/risk/recalculate-all';
  static String get earlyWarningsMine => '$baseUrl/early-warning/me';
  static String get earlyWarnings => '$baseUrl/early-warning/students';
  static String get interventionsV2 => '$baseUrl/interventions-v2';
  static String get academicPassport => '$baseUrl/academic-passport';
  static String get passportSharing => '$baseUrl/passport-sharing';
  static String get rbac => '$baseUrl/rbac';
  static String get audit => '$baseUrl/audit';
  static String get realtime => '$baseUrl/realtime';
  static String get analytics => '$baseUrl/analytics';
  static String get semesters => '$baseUrl/master-data/semesters';
  static String get adminCourses => '$baseUrl/master-data/courses';
  static String get enrollment => '$baseUrl/enrollment';
  static String get curricula => '$baseUrl/curricula';
  static String get academicAdmin => '$baseUrl/academic-admin';
  static String get attendanceV2 => '$baseUrl/attendance-v2';
  static String get feesV2 => '$baseUrl/fees-v2';
  static String get paymentsV2 => '$baseUrl/payments-v2';
  static String get hostelV2 => '$baseUrl/hostel-v2';
  static String get transportV2 => '$baseUrl/transport-v2';
  static String get notificationsV2 => '$baseUrl/notifications-v2';
  static String get earlyWarning => '$baseUrl/early-warning';
}
