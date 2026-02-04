import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/providers/institution_provider.dart';
import 'package:edu_att/models/insituiton_model.dart';

class StudentLoginScreen extends ConsumerStatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  ConsumerState<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends ConsumerState<StudentLoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  String? selectedInstitutionId;

  @override
  Widget build(BuildContext context) {
    final institutionsAsync = ref.watch(institutionsProvider);

    return Stack(
      children: [
        Scaffold(
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF4A148C),
                  Color(0xFF6A1B9A),
                  Color(0xFF7B1FA2),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.06)),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Вход студента',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // -----------------------------
                        // DROPDOWN INSTITUTIONS
                        // -----------------------------
                        institutionsAsync.when(
                          data:
                              (institutions) =>
                                  _buildInstitutionDropdown(institutions),
                          loading: () => const SizedBox(),
                          error:
                              (_, __) => const Text(
                                "Ошибка загрузки организаций",
                                style: TextStyle(color: Colors.white70),
                              ),
                        ),

                        const SizedBox(height: 18),

                        _buildTextField(
                          controller: emailController,
                          hintText: 'Email',
                        ),
                        const SizedBox(height: 18),

                        _buildTextField(
                          controller: passwordController,
                          hintText: 'Пароль',
                          obscureText: true,
                        ),
                        const SizedBox(height: 36),

                        _buildLoginButton(context, ref),
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

                        const SizedBox(height: 20),

                        // --------------------------------------------------------------------
                        //      СЕКРЕТНАЯ НЕВИДИМАЯ КНОПКА АВТОЗАПОЛНЕНИЯ (для тестов)
                        // --------------------------------------------------------------------
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedInstitutionId =
                                  '761584a9-07a1-4e5f-9549-7911ab5bc1b5';
                            });
                            emailController.text = 'ivanova_v@mpcit.ru';
                            passwordController.text = 'myhash_s3';
                          },
                          child: Opacity(
                            opacity: 0.0,
                            child: Container(
                              width: 140,
                              height: 60,
                              color: Colors.transparent,
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
        ),

        // ---------------------------------------
        // FULLSCREEN LOADING OVERLAY
        // ---------------------------------------
        if (institutionsAsync.isLoading)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withOpacity(0.45),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------
  // WIDGET: Institution Dropdown
  // ------------------------------------------------
  Widget _buildInstitutionDropdown(List<InstitutionModel> institutions) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: const Text(
          'Выберите организацию',
          style: TextStyle(color: Colors.white70),
        ),
        value: selectedInstitutionId,
        items:
            institutions
                .map(
                  (inst) => DropdownMenuItem(
                    value: inst.id!,
                    child: Text(
                      inst.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
        onChanged:
            (value) => setState(() {
              selectedInstitutionId = value;
            }),

        // button style
        buttonStyleData: ButtonStyleData(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(14),
          ),
        ),

        // dropdown style
        dropdownStyleData: DropdownStyleData(
          elevation: 2,
          maxHeight: 320,
          decoration: BoxDecoration(
            color: const Color(0xFF4A148C),
            borderRadius: BorderRadius.circular(12),
          ),
          offset: const Offset(0, 0),
        ),

        iconStyleData: const IconStyleData(
          icon: Icon(Icons.arrow_drop_down, color: Colors.white),
        ),
      ),
    );
  }

  // ------------------------------------------------
  // TEXTFIELD BUILDER
  // ------------------------------------------------
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
        hintStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
      ),
    );
  }

  // ------------------------------------------------
  // LOGIN BUTTON
  // ------------------------------------------------
  Widget _buildLoginButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 260,
      height: 56,
      child: ElevatedButton(
        onPressed: () async {
          if (selectedInstitutionId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Выберите организацию")),
            );
            return;
          }

          final notifier = ref.read(currentStudentProvider.notifier);

          final success = await notifier.login(
            selectedInstitutionId!,
            emailController.text.trim(),
            passwordController.text.trim(),
          );

          if (success && mounted) {
            final student = ref.read(currentStudentProvider);

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
            ).showSnackBar(const SnackBar(content: Text("Ошибка входа")));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.2),
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
