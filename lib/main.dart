import 'package:edu_att/screens/student/lesson_attendance_mark_screen.dart';
import 'package:flutter/material.dart';
import 'package:edu_att/supabase/supabase_config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/screens/menu_screen.dart';
import 'package:edu_att/screens/student/login_student_screen.dart';
import 'package:edu_att/screens/student/home_screen.dart';

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
        path: '/login',
        builder: (context, state) => const StudentLoginScreen(),
      ),
      GoRoute(
        path: '/student/home',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/student/mark',
        builder: (context, state) => const AttendanceMarkScreen(),
      ),
    ],
  );

  runApp(ProviderScope(child: EduAttApp(router: appRouter)));
}

class EduAttApp extends StatelessWidget {
  final GoRouter router;

  const EduAttApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EduAtt',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
