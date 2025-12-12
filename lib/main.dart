import 'package:edu_att/screens/student/lesson_attendance_mark_screen.dart';
import 'package:edu_att/screens/teacher/login_teacher_screen.dart';
import 'package:flutter/material.dart';
import 'package:edu_att/supabase/supabase_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/screens/menu_screen.dart';
import 'package:edu_att/screens/student/login_student_screen.dart';
import 'package:edu_att/screens/student/home_screen.dart';
import 'package:edu_att/screens/teacher/home_screen.dart';
import 'package:edu_att/screens/teacher/teacher_attendance_mark_screen.dart';
import 'package:edu_att/services/shared_preferences_service.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/screens/student/subject_absences_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print(dotenv.env['SUPABASE_URL']);
    print(dotenv.env['SUPABASE_ANON_KEY']);
    await SupabaseConfig.init();
  } catch (e, stackTrace) {
    print('Ошибка при инициализации: $e');
    print(stackTrace);
  }

  final GoRouter appRouter = GoRouter(
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
    ],
  );

  runApp(ProviderScope(child: EduAttApp(router: appRouter)));
}

class EduAttApp extends ConsumerStatefulWidget {
  final GoRouter router;

  const EduAttApp({super.key, required this.router});

  @override
  ConsumerState<EduAttApp> createState() => _EduAttAppState();
}

class _EduAttAppState extends ConsumerState<EduAttApp> {
  bool _isCheckingSession = true;
  bool _shouldRedirectToHome = false;
  String _userType = '';

  @override
  void initState() {
    super.initState();
    _checkAndAutoLogin();
  }

  Future<void> _checkAndAutoLogin() async {
    final userType = await SharedPreferencesService.getUserType();
    bool loginSuccess = false;

    if (userType == 'student') {
      loginSuccess = await _tryAutoLoginStudent();
    } else if (userType == 'teacher') {
      loginSuccess = await _tryAutoLoginTeacher();
    }

    setState(() {
      _isCheckingSession = false;
      _shouldRedirectToHome = loginSuccess;
      _userType = userType ?? '';
    });
  }

  Future<bool> _tryAutoLoginStudent() async {
    final credentials = await SharedPreferencesService.getStudentCredentials();
    if (credentials != null) {
      final success = await ref
          .read(currentStudentProvider.notifier)
          .login(
            credentials['institutionId']!,
            credentials['login']!,
            credentials['password']!,
          );
      return success;
    }
    return false;
  }

  Future<bool> _tryAutoLoginTeacher() async {
    final credentials = await SharedPreferencesService.getTeacherCredentials();
    if (credentials != null) {
      await ref
          .read(teacherProvider.notifier)
          .loginTeacher(
            email: credentials['login']!,
            password: credentials['password']!,
            institutionId: credentials['institutionId']!,
          );

      // Проверяем успешность входа
      final teacher = ref.read(teacherProvider);
      return teacher != null;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Если нужно сделать редирект - делаем его
    if (_shouldRedirectToHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_userType == 'student') {
          widget.router.go('/student/home');
        } else if (_userType == 'teacher') {
          widget.router.go('/teacher/home');
        }
        // Сбрасываем флаг после редиректа
        setState(() {
          _shouldRedirectToHome = false;
        });
      });
    }

    // Пока проверяем сессию, показываем загрузку
    if (_isCheckingSession) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.deepPurple,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Проверка сессии...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // После проверки показываем основное приложение
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EduAtt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: widget.router,
    );
  }
}
