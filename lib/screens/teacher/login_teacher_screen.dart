import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/providers/institution_provider.dart';
import 'package:edu_att/models/insituiton_model.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';

class TeacherLoginScreen extends ConsumerStatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  ConsumerState<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends ConsumerState<TeacherLoginScreen> {
  final loginController = TextEditingController();
  final passwordController = TextEditingController();

  String? selectedInstitutionId;
  bool _isLoggingIn = false;
  MascotState _mascotState = MascotState.searching;
  Timer? _mascotTimer;

  @override
  void dispose() {
    _mascotTimer?.cancel();
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _startLoginOverlay() {
    _mascotTimer?.cancel();
    setState(() {
      _isLoggingIn = true;
      _mascotState = MascotState.searching;
    });
    _mascotTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _mascotState = _mascotState == MascotState.searching
              ? MascotState.updating
              : MascotState.searching;
        });
      }
    });
  }

  void _stopLoginOverlay() {
    _mascotTimer?.cancel();
    _mascotTimer = null;
    if (mounted) setState(() => _isLoggingIn = false);
  }

  Future<void> _handleLogin() async {
    if (selectedInstitutionId == null) {
      EduSnackBar.showInfo(context, ref, 'Выберите организацию');
      return;
    }

    _startLoginOverlay();

    await ref.read(teacherProvider.notifier).loginTeacher(
      email: loginController.text.trim(),
      password: passwordController.text.trim(),
      institutionId: selectedInstitutionId!,
    );

    _stopLoginOverlay();

    if (!mounted) return;

    final teacher = ref.read(teacherProvider);

    if (teacher != null) {
      if (!mounted) return;
      EduSnackBar.showGreeting(context, ref, teacher.name);
      context.go('/teacher/home');
    } else {
      EduSnackBar.showError(context, ref, 'Доступ запрещён. Проверьте данные.');
    }
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
                    // Маскот Фрося приветствует преподавателя
                    const EduMascot(state: MascotState.greeting, height: 120),
                    const SizedBox(height: 24),
                    Text(
                      'Вход преподавателя',
                      style: TextStyle(
                        color: isDark ? Colors.white : colorScheme.primary,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 32),

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
                        loginController.text = 'belov@mct.ru';
                        passwordController.text = '123';
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

          // Оверлей входа с Фросей
          if (_isLoggingIn)
            Container(
              color: colorScheme.surface.withValues(alpha: 0.95),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EduMascot(state: _mascotState, height: 140),
                    const SizedBox(height: 20),
                    Text(
                      'Выполняется вход...',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 220,
                      child: LinearProgressIndicator(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Оверлей загрузки организаций
          if (institutionsAsync.isLoading && !_isLoggingIn)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
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
        value: institutions.any((i) => i.id == selectedInstitutionId)
            ? selectedInstitutionId
            : null,
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
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
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
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
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
        onPressed: _isLoggingIn ? null : _handleLogin,
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
