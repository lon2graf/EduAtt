import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';

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
            colors: [
              Color(0xFF4A148C), // Глубокий фиолетовый
              Color(0xFF6A1B9A), // Темно-фиолетовый
              Color(0xFF7B1FA2), // Ярче посередине
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
          ), // Вуаль
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20), // Уменьшены отступы
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Вход студента',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34, // Уменьшен шрифт заголовка
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0, // Уменьшена ширина
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40), // Уменьшен отступ
                    _buildTextField(
                      controller: institutionController,
                      hintText: 'ID образовательной организации',
                    ),
                    const SizedBox(height: 18), // Уменьшен отступ
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Email',
                    ),
                    const SizedBox(height: 18), // Уменьшен отступ
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Пароль',
                      obscureText: true,
                    ),
                    const SizedBox(height: 36), // Уменьшен отступ
                    _buildLoginButton(
                      context,
                      ref,
                      institutionController,
                      emailController,
                      passwordController,
                    ),
                    const SizedBox(height: 18), // Уменьшен отступ
                    InkWell(
                      onTap: () => context.go('/'),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text(
                          'Назад в главное меню',
                          style: TextStyle(
                            color: Colors.white60, // Светлее
                            fontSize: 15, // Уменьшен шрифт
                            decoration: TextDecoration.underline,
                            decorationColor:
                                Colors.white30, // Светлее подчёркивание
                            decorationThickness: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // --- Кнопка автозаполнения (прозрачная) ---
                    GestureDetector(
                      onTap: () {
                        // Автоматически заполняем поля тестовыми данными
                        institutionController.text =
                            '73ba4892-2449-4a4f-bf93-30c222965b59';
                        emailController.text = 'roman.t@kfu.ru';
                        passwordController.text = 'pass123';
                      },
                      // Делаем кнопку невидимой, но она по-прежнему реагирует на нажатие
                      child: Opacity(
                        opacity: 0.0, // Полностью прозрачная
                        child: Container(
                          width:
                              100, // Произвольный размер для удобства тестирования
                          height: 50,
                          color: Colors.transparent, // Цвет убран
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
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16, // Уменьшен шрифт
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: Colors.white60, // Светлее
          fontSize: 15, // Уменьшен шрифт
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.14), // Светлее фон поля
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), // Уменьшено скругление
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          // Обводка при фокусе
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.4), // Цвет обводки при фокусе
            width: 1.2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16, // Уменьшены внутренние отступы
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
      width: 260, // Уменьшена ширина
      height: 56, // Уменьшена высота
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
            print("кнопка тыкнут и саксесс");

            final student = ref.watch(currentStudentProvider);

            if (student != null) {
              await ref
                  .read(attendanceProvider.notifier)
                  .loadStudentAttendances(student.id!);
              await ref
                  .read(currentLessonProvider.notifier)
                  .loadCurrentLesson(student.groupId);
              context.go('/student/home');
            }
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Ошибка входа')));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade700, // Фиолетовый стиль
          foregroundColor: Colors.white,
          elevation: 6, // Уменьшена тень
          shadowColor: Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Уменьшено скругление
          ),
        ),
        child: const Text(
          'Войти',
          style: TextStyle(
            fontSize: 17, // Уменьшен шрифт
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
