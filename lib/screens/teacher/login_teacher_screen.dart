import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';

class TeacherLoginScreen extends ConsumerWidget {
  const TeacherLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    final institutionController = TextEditingController();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06)),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Вход преподавателя',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // institution id
                    _buildTextField(
                      controller: institutionController,
                      hintText: 'ID образовательной организации',
                    ),
                    const SizedBox(height: 18),

                    // login
                    _buildTextField(
                      controller: loginController,
                      hintText: 'Логин',
                    ),
                    const SizedBox(height: 18),

                    // password
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Пароль',
                      obscureText: true,
                    ),
                    const SizedBox(height: 36),

                    // login button
                    _buildLoginButton(
                      context,
                      ref,
                      institutionController,
                      loginController,
                      passwordController,
                    ),
                    const SizedBox(height: 18),

                    InkWell(
                      onTap: () => context.go('/'),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text(
                          'Назад в главное меню',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white30,
                            decorationThickness: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white60, fontSize: 15),
        filled: true,
        fillColor: Colors.white.withOpacity(0.14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
      ),
    );
  }

  Widget _buildLoginButton(
    BuildContext context,
    WidgetRef ref,
    TextEditingController institutionController,
    TextEditingController emailController,
    TextEditingController passwordController,
  ) {
    return SizedBox(
      width: 260,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          final notifier = ref.read(teacherProvider.notifier);

          await notifier.loginTeacher(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            institutionId: institutionController.text.trim(),
          );

          final teacher = ref.read(teacherProvider);

          if (teacher != null && context.mounted) {
            await ref
                .read(currentLessonProvider.notifier)
                .loadCurrentLessonForTeacher(teacher.id!);
            context.go('/teacher/home');
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Ошибка входа")));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Войти',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
