import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/providers/institution_provider.dart';
import 'package:edu_att/models/insituiton_model.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';

class TeacherLoginScreen extends ConsumerStatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  ConsumerState<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends ConsumerState<TeacherLoginScreen> {
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  String? selectedInstitutionId;

  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final institutionsAsync = ref.watch(institutionsProvider);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Вход преподавателя',
                      style: TextStyle(
                        color: isDark ? Colors.white : colorScheme.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Выбор организации
                    institutionsAsync.when(
                      data:
                          (institutions) =>
                              _buildInstitutionDropdown(context, institutions),
                      loading: () => const SizedBox(height: 54),
                      error:
                          (_, __) => Text(
                            "Ошибка загрузки организаций",
                            style: TextStyle(color: colorScheme.error),
                          ),
                    ),

                    const SizedBox(height: 18),

                    _buildTextField(
                      context,
                      controller: loginController,
                      hintText: 'Логин',
                    ),
                    const SizedBox(height: 18),

                    _buildTextField(
                      context,
                      controller: passwordController,
                      hintText: 'Пароль',
                      obscureText: true,
                    ),
                    const SizedBox(height: 36),

                    _buildLoginButton(context, ref),
                    const SizedBox(height: 24),

                    InkWell(
                      onTap: () => context.go('/'),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Назад в главное меню',
                          style: TextStyle(
                            color:
                                isDark ? Colors.white60 : colorScheme.primary,
                            fontSize: 15,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),

                    // Секретная кнопка (невидимая)
                    GestureDetector(
                      onTap: () {
                        setState(
                          () =>
                              selectedInstitutionId =
                                  '761584a9-07a1-4e5f-9549-7911ab5bc1b5',
                        );
                        loginController.text = 'fedorov@mpcit.ru';
                        passwordController.text = 'myhash_t12';
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        color: Colors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Индикатор загрузки
          if (institutionsAsync.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstitutionDropdown(
    BuildContext context,
    List<InstitutionModel> institutions,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: Text(
          'Выберите организацию',
          style: TextStyle(color: theme.hintColor),
        ),
        value: selectedInstitutionId,
        items:
            institutions
                .map(
                  (inst) => DropdownMenuItem(
                    value: inst.id!,
                    child: Text(
                      inst.name,
                      style: TextStyle(color: colorScheme.onSurface),
                    ),
                  ),
                )
                .toList(),
        onChanged: (value) => setState(() => selectedInstitutionId = value),
        buttonStyleData: ButtonStyleData(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        iconStyleData: IconStyleData(
          icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: theme.hintColor),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 18,
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

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

          // Вызов метода логина именно для ПРЕПОДАВАТЕЛЯ
          await ref
              .read(teacherProvider.notifier)
              .loginTeacher(
                email: loginController.text.trim(),
                password: passwordController.text.trim(),
                institutionId: selectedInstitutionId!,
              );

          final teacher = ref.read(teacherProvider);

          if (teacher != null && mounted) {
            // Загружаем текущий урок преподавателя
            await ref
                .read(currentLessonProvider.notifier)
                .loadCurrentLessonForTeacher(teacher.id!);
            EduSnackBar.showGreeting(context, ref, teacher.name);
            context.go('/teacher/home');
          } else if (mounted) {
            EduSnackBar.showError(
              context,
              ref,
              'Доступ запрещен. Проверьте данные.',
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        child: const Text(
          'Войти',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
