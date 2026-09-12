class ApiConstants {
  static const String baseUrl = 'https://chaos.io.vn';

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  // Auth
  static const String login = '/api/login';
  static const String signup = '/api/signup';
  static const String logout = '/api/logout';
  static const String refreshToken = '/api/refresh-token';
  static const String changePassword = '/api/change-password';
  static const String forgotPassword = '/api/forgot-password';

  // Users
  static const String users = '/api/users';
  static String userProfile(String id) => '/api/users/$id/profile';

  // Projects & Tasks
  static const String projects = '/api/projects';
  static const String projectSchedules = '/api/project-schedules';
  static const String tasks = '/api/tasks';
  static const String timeline = '/api/timeline';

  // Workflow
  static const String workflows = '/api/workflows';
  static String workflowDetail(String id) => '/api/workflow/$id';
  static const String workflowTransition = '/api/workflow/transition';
  static String availableTransitions(String scopeType, String scopeId) =>
      '/api/workflow/available-transitions/$scopeType/$scopeId';
  static String workflowHistories(String scopeType, String scopeId) =>
      '/api/workflow-histories/$scopeType/$scopeId';

  // Attendance
  static const String attendanceReport = '/api/attendance/report';

  // Requests (Leave & OT & Attendance Correction)
  static const String leaveRequests = '/api/leave-requests';
  static const String overtimeRequests = '/api/overtime-requests';
  static const String overtimeMonthlySheet =
      '/api/overtime-requests/monthly-sheet';
  static const String overtimeBulk = '/api/overtime-requests/bulk';
  static String overtimeApprove(String id) =>
      '/api/overtime-requests/$id/approve';
  static const String attendanceCorrection = '/api/attendance-correction';

  // Assets
  static const String assets = '/api/assets';

  // Notifications
  static const String notifications = '/api/notifications';
}
