import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:learned_flutter/features/auth/screens/email_verification_screen.dart';
import 'package:learned_flutter/features/auth/screens/forgot_password_screen.dart';
import 'package:learned_flutter/features/auth/screens/user_type_selection_screen.dart';
import 'package:learned_flutter/features/auth/screens/login_screen.dart';
import 'package:learned_flutter/features/auth/screens/reset_password_screen.dart';
import 'package:learned_flutter/features/auth/screens/register_screen.dart';
import 'package:learned_flutter/features/auth/screens/welcome_screen.dart';
import 'package:learned_flutter/features/splash/screens/splash_screen.dart';
import 'package:learned_flutter/features/student/screens/student_dashboard_screen.dart';
import 'package:learned_flutter/features/student/screens/classroom_list_screen.dart';
import 'package:learned_flutter/features/student/screens/classroom_detail_screen.dart';
import 'package:learned_flutter/features/student/screens/student_profile_screen.dart';
import 'package:learned_flutter/features/student/screens/edit_profile_screen.dart';
import 'package:learned_flutter/features/student/screens/my_classes_screen.dart';
import 'package:learned_flutter/features/student/screens/session_details_screen.dart';
import 'package:learned_flutter/features/student/screens/assignments_screen.dart';
import 'package:learned_flutter/features/student/screens/schedule_screen.dart';
import 'package:learned_flutter/features/student/screens/join_session_screen.dart';
import 'package:learned_flutter/features/student/screens/active_session_screen.dart';
import 'package:learned_flutter/features/student/screens/session_feedback_screen.dart';
import 'package:learned_flutter/features/student/screens/progress_screen.dart';
import 'package:learned_flutter/features/student/screens/learning_materials_screen.dart';
import 'package:learned_flutter/features/student/screens/material_viewer_screen.dart';
import 'package:learned_flutter/features/student/screens/payment_screen.dart';
import 'package:learned_flutter/features/student/models/assignment_model.dart';
import 'package:learned_flutter/features/debug/screens/database_test_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // Classrooms route
    // Classrooms routes
    GoRoute(
      path: '/classrooms',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const ClassroomListScreen()),
      routes: [
        // Classroom detail route
        GoRoute(
          path: ':classroomId',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: ClassroomDetailScreen(classroomId: state.pathParameters['classroomId']!),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const SplashScreen()),
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const WelcomeScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const LoginScreen()),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) {
        final userType = state.uri.queryParameters['type'];
        return MaterialPage(
          key: state.pageKey,
          child: RegisterScreen(userType: userType),
        );
      },
    ),
    GoRoute(
      path: '/forgot-password',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const ForgotPasswordScreen()),
    ),
    GoRoute(
      path: '/reset-password',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const ResetPasswordScreen()),
    ),
    GoRoute(
      path: '/verify-email',
      pageBuilder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return MaterialPage(
          key: state.pageKey,
          child: EmailVerificationScreen(email: email),
        );
      },
    ),
    GoRoute(
      path: '/select-user-type',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const UserTypeSelectionScreen()),
    ),
    // Student routes
    GoRoute(
      path: '/student',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const StudentDashboardScreen()),
      routes: [
        // Dashboard
        GoRoute(
          path: 'dashboard',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const StudentDashboardScreen()),
        ),
        // My Sessions
        GoRoute(
          path: 'sessions',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const MyClassesScreen()),
          routes: [
            // Session Details
            GoRoute(
              path: ':sessionId',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: SessionDetailsScreen(sessionId: state.pathParameters['sessionId']!),
              ),
            ),
            // Join Class
            GoRoute(
              path: 'join',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: Scaffold(
                  appBar: AppBar(title: const Text('Join a Class')),
                  body: const Center(child: Text('Join Class Screen - Coming Soon')),
                ),
              ),
            ),

            // Calendar View
            GoRoute(
              path: 'calendar',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: Scaffold(
                  appBar: AppBar(title: const Text('Class Calendar')),
                  body: const Center(child: Text('Calendar View - Coming Soon')),
                ),
              ),
            ),
          ],
        ),
        // Schedule
        GoRoute(
          path: 'schedule',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const ScheduleScreen()),
          routes: [
            // Join Session
            GoRoute(
              path: 'session/join/:sessionId',
              pageBuilder: (context, state) {
                final sessionId = state.pathParameters['sessionId']!;
                final sessionData = state.extra as Map<String, dynamic>?;
                return MaterialPage(
                  key: state.pageKey,
                  child: JoinSessionScreen(sessionId: sessionId, sessionData: sessionData),
                );
              },
              routes: [
                // Active Session
                GoRoute(
                  path: 'active',
                  pageBuilder: (context, state) {
                    final sessionId = state.pathParameters['sessionId']!;
                    final sessionData = state.extra as Map<String, dynamic>?;
                    return MaterialPage(
                      key: state.pageKey,
                      child: ActiveSessionScreen(sessionId: sessionId, sessionData: sessionData),
                    );
                  },
                  routes: [
                    // Session Feedback
                    GoRoute(
                      path: 'feedback',
                      pageBuilder: (context, state) {
                        final sessionId = state.pathParameters['sessionId']!;
                        final sessionData = state.extra as Map<String, dynamic>?;
                        return MaterialPage(
                          key: state.pageKey,
                          child: SessionFeedbackScreen(sessionId: sessionId, sessionData: sessionData),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Progress
        GoRoute(
          path: 'progress',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const ProgressScreen()),
        ),

        // Learning Materials
        GoRoute(
          path: 'materials',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const LearningMaterialsScreen()),
          routes: [
            // Material Viewer
            GoRoute(
              path: ':materialId',
              pageBuilder: (context, state) {
                final materialId = state.pathParameters['materialId']!;
                final materialData = state.extra as Map<String, dynamic>?;
                return MaterialPage(
                  key: state.pageKey,
                  child: MaterialViewerScreen(materialId: materialId, materialData: materialData),
                );
              },
            ),
          ],
        ),

        // Assignments
        GoRoute(
          path: 'assignments',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const AssignmentsScreen()),
          routes: [
            // Assignment submission route
            GoRoute(
              path: 'submit',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: Scaffold(
                  appBar: AppBar(title: const Text('Submit Assignment')),
                  body: const Center(child: Text('Assignment submission form will be implemented here')),
                ),
              ),
            ),
            // Assignment details route
            GoRoute(
              path: ':assignmentId',
              pageBuilder: (context, state) {
                final assignment = state.extra as Assignment?;
                return MaterialPage(
                  key: state.pageKey,
                  child: Scaffold(
                    appBar: AppBar(title: const Text('Assignment Details')),
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (assignment != null) ...[
                            Text(assignment.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Text('Status: ${assignment.status}'),
                            const SizedBox(height: 24),
                            if (state.matchedLocation.endsWith('/submit'))
                              ElevatedButton(
                                onPressed: () {
                                  // Handle submission
                                },
                                child: const Text('Submit Assignment'),
                              ),
                          ] else
                            const Text('Assignment not found'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        // Profile
        GoRoute(
          path: 'profile',
          pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const StudentProfileScreen()),
          routes: [
            // Edit Profile
            GoRoute(
              path: 'edit',
              pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const EditProfileScreen()),
            ),
            // Session
            GoRoute(
              path: 'session/join',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: Scaffold(
                  appBar: AppBar(title: const Text('Join Session')),
                  body: const Center(child: Text('Join Session - Coming Soon')),
                ),
              ),
            ),
            GoRoute(
              path: 'session/active/:sessionId',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: Scaffold(
                  appBar: AppBar(title: const Text('Active Session')),
                  body: Center(child: Text('Active Session ID: ${state.pathParameters['sessionId']}')),
                ),
              ),
            ),
            GoRoute(
              path: 'session/feedback/:sessionId',
              pageBuilder: (context, state) => MaterialPage(
                key: state.pageKey,
                child: Scaffold(
                  appBar: AppBar(title: const Text('Session Feedback')),
                  body: Center(child: Text('Feedback for Session ID: ${state.pathParameters['sessionId']}')),
                ),
              ),
            ),
          ],
        ),
        // Notifications
        GoRoute(
          path: 'notifications',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const Scaffold(body: Center(child: Text('Notifications Screen - Coming Soon'))),
          ),
        ),
        // Settings
        GoRoute(
          path: 'settings',
          pageBuilder: (context, state) => MaterialPage(
            key: state.pageKey,
            child: const Scaffold(body: Center(child: Text('Settings Screen - Coming Soon'))),
          ),
        ),
      ],
    ),

    // Home route (redirects to student dashboard for now)
    GoRoute(path: '/home', redirect: (context, state) => '/student'),

    // Payment route
    GoRoute(
      path: '/payment',
      pageBuilder: (context, state) {
        final extraData = state.extra as Map<String, dynamic>?;
        final classroom = extraData?['classroom'] as Map<String, dynamic>?;
        final action = extraData?['action'] as String? ?? 'enrollment';

        if (classroom == null) {
          return MaterialPage(
            key: state.pageKey,
            child: const Scaffold(body: Center(child: Text('Invalid payment request'))),
          );
        }

        return MaterialPage(
          key: state.pageKey,
          child: PaymentScreen(classroom: classroom, action: action),
        );
      },
    ),

    // Debug routes
    GoRoute(
      path: '/debug/db-test',
      pageBuilder: (context, state) => MaterialPage(key: state.pageKey, child: const DatabaseTestScreen()),
    ),
  ],
  errorPageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    child: Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
  ),
);
