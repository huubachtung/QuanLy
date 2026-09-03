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
  static const String workflowTransition = '/api/workflow/transition';

  // Attendance
  static const String attendanceReport = '/api/attendance/report';

  // Requests (Leave & OT)
  static const String leaveRequests = '/api/leave-requests';
  static const String overtimeRequests = '/api/overtime-requests';
  static const String overtimeMonthlySheet =
      '/api/overtime-requests/monthly-sheet';
  static const String overtimeBulk = '/api/overtime-requests/bulk';
  static String overtimeApprove(String id) =>
      '/api/overtime-requests/$id/approve';

  // Assets
  static const String assets = '/api/assets';

  // Notifications
  static const String notifications = '/api/notifications';
}
