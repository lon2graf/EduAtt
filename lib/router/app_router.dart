import 'package:go_router/go_router.dart';

// Импорты экранов
import 'package:edu_att/screens/menu_screen.dart';
import 'package:edu_att/screens/student/login_student_screen.dart';
import 'package:edu_att/screens/student/home_screen.dart';
import 'package:edu_att/screens/teacher/login_teacher_screen.dart';
import 'package:edu_att/screens/teacher/home_screen.dart';
import 'package:edu_att/screens/student/lesson_attendance_mark_screen.dart';
import 'package:edu_att/screens/teacher/teacher_attendance_mark_screen.dart';
import 'package:edu_att/screens/student/subject_absences_screen.dart';
import 'package:edu_att/screens/lesson_chat_screen.dart';
import 'package:edu_att/screens/schedule_screen.dart';
import 'package:edu_att/screens/teacher/teacher_group_analytics_screen.dart';
import 'package:edu_att/screens/personal/personal_role_select_screen.dart';
import 'package:edu_att/screens/personal/personal_manage_screen.dart';
import 'package:edu_att/screens/onboarding_screen.dart';
import 'package:edu_att/screens/student/qr_scanner_screen.dart';
import 'package:edu_att/screens/student/subject_stats_screen.dart';
import 'package:edu_att/screens/teacher/lesson_history_screen.dart';
import 'package:edu_att/screens/teacher/lesson_history_detail_screen.dart';
import 'package:edu_att/models/lesson_model.dart';

/// Создаёт роутер с нужным начальным маршрутом.
/// [initialLocation] — `/onboarding` при первом запуске, `/` иначе.
GoRouter createAppRouter(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', builder: (context, state) => const MainMenuScreen()),
    GoRoute(
      path: '/login_student',
      builder: (context, state) => const StudentLoginScreen(),
    ),
    GoRoute(
      path: '/login_teacher',
      builder: (context, state) => const TeacherLoginScreen(),
    ),
    GoRoute(
      path: '/student/home',
      builder: (context, state) => const StudentHomeScreen(),
    ),
    GoRoute(
      path: '/teacher/home',
      builder: (context, state) => const TeacherHomeScreen(),
    ),
    GoRoute(
      path: '/student/mark',
      builder: (context, state) => const AttendanceMarkScreen(),
    ),
    GoRoute(
      path: '/teacher/mark',
      builder: (context, state) => const TeacherAttendanceMarkScreen(),
    ),
    GoRoute(
      path: '/student/subject_absences',
      builder: (context, state) {
        final subjectName = state.uri.queryParameters['subject'] ?? 'Предмет';
        return SubjectAbsencesScreen(subjectName: subjectName);
      },
    ),
    GoRoute(
      path: '/lesson_chat',
      builder: (context, state) => const LessonChatScreen(),
    ),
    GoRoute(
      path: '/schedule',
      builder: (context, state) => const ScheduleScreen(),
    ),
    GoRoute(
      path: '/teacher/analytics',
      builder: (context, state) {
        final groupId = state.uri.queryParameters['group'] ?? '';
        final groupName = state.uri.queryParameters['name'] ?? '';
        return TeacherGroupAnalyticsScreen(
          groupId: groupId,
          groupName: groupName,
        );
      },
    ),
    GoRoute(
      path: '/personal/setup',
      builder: (context, state) => const PersonalRoleSelectScreen(),
    ),
    GoRoute(
      path: '/personal/manage',
      builder: (context, state) => const PersonalManageScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/student/qr_scan',
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/student/subject_stats',
      builder: (context, state) => const SubjectStatsScreen(),
    ),
    GoRoute(
      path: '/teacher/history',
      builder: (context, state) => const LessonHistoryScreen(),
    ),
    GoRoute(
      path: '/teacher/history/detail',
      builder: (context, state) {
        final lesson = state.extra as LessonModel;
        return LessonHistoryDetailScreen(lesson: lesson);
      },
    ),
  ],
);
