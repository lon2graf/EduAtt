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

// Глобальная переменная роутера
final GoRouter appRouter = GoRouter(
  initialLocation: '/', // Начальный маршрут
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
  ],
);
