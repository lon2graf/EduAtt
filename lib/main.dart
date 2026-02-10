import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/supabase/supabase_config.dart';

import 'package:edu_att/services/shared_preferences_service.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/theme/theme_provider.dart';
import 'package:edu_att/theme/app_theme.dart';

// Импортируем наш файл с роутером
import 'package:edu_att/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await SupabaseConfig.init();
  } catch (e, stackTrace) {
    print('Ошибка при инициализации: $e');
    print(stackTrace);
  }

  runApp(const ProviderScope(child: EduAttApp()));
}

class EduAttApp extends ConsumerStatefulWidget {
  const EduAttApp({super.key});

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

    if (mounted) {
      setState(() {
        _isCheckingSession = false;
        _shouldRedirectToHome = loginSuccess;
        _userType = userType ?? '';
      });
    }
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

      final teacher = ref.read(teacherProvider);
      return teacher != null;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final appThemeType = ref.watch(themeProvider);

    // Логика редиректа
    if (_shouldRedirectToHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Используем глобальную переменную appRouter
        if (_userType == 'student') {
          appRouter.go('/student/home');
        } else if (_userType == 'teacher') {
          appRouter.go('/teacher/home');
        }
        setState(() {
          _shouldRedirectToHome = false;
        });
      });
    }

    if (_isCheckingSession) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: appThemeType.themeMode,
        home: Scaffold(
          backgroundColor: AppTheme.primaryColor,
          body: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EduAtt',

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: appThemeType.themeMode,

      // Подключаем глобальный роутер
      routerConfig: appRouter,
    );
  }
}
