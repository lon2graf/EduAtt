import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:go_router/go_router.dart';

class StudentLoginScreen extends ConsumerWidget {
  const StudentLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final institutionController = TextEditingController();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF5A00FF), Color(0xFF0078FF), Color(0xFF00C6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.15)),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Вход студента',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 50),
                    _buildTextField(
                      controller: institutionController,
                      hintText: 'ID образовательной организации',
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Email',
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Пароль',
                      obscureText: true,
                    ),
                    const SizedBox(height: 40),
                    _buildLoginButton(
                      context,
                      ref,
                      institutionController,
                      emailController,
                      passwordController,
                    ),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () => context.go('/'),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text(
                          'Назад в главное меню',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 20,
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
      width: 280,
      height: 60,
      child: ElevatedButton(
        onPressed: () async {
          print('кнопка тыкнут');
          final success = await ref
              .read(currentStudentProvider.notifier)
              .login(
                institutionController.text.trim(),
                emailController.text.trim(),
                passwordController.text.trim(),
              );

          if (success && context.mounted) {
            print("кнопка тыкнут и саксекс");

            final student = ref.watch(currentStudentProvider);

            if (student != null && !student.isHeadman) {
              context.go('/student/home');
            } else {
              print("староста");
              context.go('');
            }
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Ошибка входа')));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
          elevation: 10,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'Войти',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
