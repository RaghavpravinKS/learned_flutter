/// Centralized route names for the application
class AppRoutes {
  // Base routes
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';
  static const String selectUserType = '/select-user-type';

  // Student routes
  static const String student = '/student';
  static const String studentDashboard = '$student/dashboard';
  static const String studentProfile = '$student/profile';
  static const String studentProfileEdit = '$student/profile/edit';
  static const String studentClasses = '$student/classes';
  static const String studentClassDetails = '$student/class';
  static const String studentAssignments = '$student/assignments';
  static const String studentAssignmentDetails = '$student/assignment';
  static const String studentSchedule = '$student/schedule';
  static const String studentProgress = '$student/progress';
  static const String studentSettings = '$student/settings';
  static const String studentNotifications = '$student/notifications';
  static const String studentHelp = '$student/help';
  static const String studentSessionJoin = '$student/session/join';
  static const String studentSessionActive = '$student/session/active';
  static const String studentSessionFeedback = '$student/session/feedback';

  // Teacher routes
  static const String teacher = '/teacher';
  static const String teacherDashboard = '$teacher/dashboard';
  static const String teacherClasses = '$teacher/classes';
  static const String teacherStudents = '$teacher/students';
  static const String teacherSchedule = '$teacher/schedule';

  // Admin routes
  static const String admin = '/admin';
  static const String adminDashboard = '$admin/dashboard';
  static const String adminUsers = '$admin/users';
  static const String adminClasses = '$admin/classes';
  static const String adminSettings = '$admin/settings';

  // Utility method to create a route with parameters
  static String withParams(String baseRoute, Map<String, String> params) {
    final uri = Uri(path: baseRoute, queryParameters: params);
    return uri.toString();
  }
}
