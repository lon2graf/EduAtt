import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/supabase/supabase_config.dart';

import 'package:edu_att/data/remote/shared_preferences_service.dart';
import 'package:edu_att/data/services/personal_mode_service.dart';
import 'package:edu_att/providers/personal_mode_provider.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/theme/theme_provider.dart';
import 'package:edu_att/theme/app_theme.dart';
import 'package:edu_att/utils/app_logger.dart';

import 'package:edu_att/router/app_router.dart';

/// Роутер инициализируется в main() с корректным initialLocation —
/// до runApp, чтобы не было мелькания MainMenuScreen перед онбордингом.
late final GoRouter appRouter;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    await SupabaseConfig.init();
  } catch (e, stackTrace) {
    AppLogger.error('Ошибка при инициализации', e, stackTrace, 'main');
  }

  final onboardingSeen = await SharedPreferencesService.isOnboardingSeen();
  appRouter = createAppRouter(onboardingSeen ? '/' : '/onboarding');

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
    try {
      final userType = await SharedPreferencesService.getUserType();

      bool loginSuccess = false;

      if (userType == 'student') {
        loginSuccess = await _tryAutoLoginStudent();
      } else if (userType == 'teacher') {
        loginSuccess = await _tryAutoLoginTeacher();
      } else if (userType == 'personal') {
        loginSuccess = await _tryAutoLoginPersonal();
      }

      if (mounted) {
        setState(() {
          _isCheckingSession = false;
          _shouldRedirectToHome = loginSuccess;
          _userType = userType ?? '';
        });
      }
    } catch (e, stack) {
      AppLogger.error('Ошибка при проверке сессии', e, stack, 'main');
      if (mounted) setState(() => _isCheckingSession = false);
    }
  }

  Future<bool> _tryAutoLoginPersonal() async {
    try {
      final roleStr = await SharedPreferencesService.getPersonalRole();
      final role = PersonalRoleExt.fromString(roleStr);
      if (role == null) return false;

      final service = ref.read(personalModeServiceProvider);
      await service.initializeIfNeeded(role);

      ref.read(personalModeProvider.notifier).activate(role);

      if (role == PersonalRole.teacher) {
        ref.read(teacherProvider.notifier).loginPersonal(service.buildTeacherModel());
      } else {
        ref.read(currentStudentProvider.notifier).loginPersonal(service.buildStudentModel(role));
      }
      return true;
    } catch (e) {
      AppLogger.error('Ошибка автовхода в личный режим', e, null, 'main');
      return false;
    }
  }

  Future<bool> _tryAutoLoginStudent() async {
    try {
      final credentials = await SharedPreferencesService.getStudentCredentials();
      if (credentials != null) {
        return await ref
            .read(currentStudentProvider.notifier)
            .autoLogin(
              institutionId: credentials['institutionId']!,
              email: credentials['login']!,
              password: credentials['password']!,
            );
      }
      return false;
    } catch (e) {
      AppLogger.error('Ошибка автовхода студента', e, null, 'main');
      return false;
    }
  }

  Future<bool> _tryAutoLoginTeacher() async {
    try {
      final credentials = await SharedPreferencesService.getTeacherCredentials();
      if (credentials != null) {
        return await ref
            .read(teacherProvider.notifier)
            .autoLogin(
              email: credentials['login']!,
              password: credentials['password']!,
              institutionId: credentials['institutionId']!,
            );
      }
      return false;
    } catch (e) {
      AppLogger.error('Ошибка автовхода преподавателя', e, null, 'main');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appThemeType = ref.watch(themeProvider);

    if (_shouldRedirectToHome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Используем глобальную переменную appRouter
        if (_userType == 'student') {
          appRouter.go('/student/home');
        } else if (_userType == 'teacher') {
          appRouter.go('/teacher/home');
        } else if (_userType == 'personal') {
          final role = ref.read(personalModeProvider).role;
          appRouter.go(role == PersonalRole.teacher ? '/teacher/home' : '/student/home');
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
