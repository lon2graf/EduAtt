import 'package:edu_att/data/remote/shared_preferences_service.dart';
import 'package:edu_att/data/services/personal_mode_service.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/providers/personal_mode_provider.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PersonalRoleSelectScreen extends ConsumerStatefulWidget {
  const PersonalRoleSelectScreen({super.key});

  @override
  ConsumerState<PersonalRoleSelectScreen> createState() =>
      _PersonalRoleSelectScreenState();
}

class _PersonalRoleSelectScreenState
    extends ConsumerState<PersonalRoleSelectScreen> {
  PersonalRole? _selectedRole;
  bool _isLoading = false;

  Future<void> _activate() async {
    if (_selectedRole == null) return;
    setState(() => _isLoading = true);
    try {
      final service = ref.read(personalModeServiceProvider);
      await service.initializeIfNeeded(_selectedRole!);
      await SharedPreferencesService.savePersonalMode(_selectedRole!.storedValue);
      ref.read(personalModeProvider.notifier).activate(_selectedRole!);

      if (_selectedRole == PersonalRole.teacher) {
        ref
            .read(teacherProvider.notifier)
            .loginPersonal(service.buildTeacherModel());
        if (mounted) context.go('/teacher/home');
      } else {
        ref
            .read(currentStudentProvider.notifier)
            .loginPersonal(service.buildStudentModel(_selectedRole!));
        if (mounted) context.go('/student/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Личный режим'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const EduMascot(state: MascotState.science, height: 120),
              const SizedBox(height: 16),
              Text(
                'Без регистрации и интернета.\nВыбери роль:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              ...PersonalRole.values.map(
                (role) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _RoleCard(
                    role: role,
                    selected: _selectedRole == role,
                    onTap: () => setState(() => _selectedRole = role),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _selectedRole != null && !_isLoading
                      ? _activate
                      : null,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Войти', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final PersonalRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon => switch (role) {
        PersonalRole.student => Icons.school_outlined,
        PersonalRole.headman => Icons.star_outline_rounded,
        PersonalRole.teacher => Icons.person_outline_rounded,
      };

  String get _description => switch (role) {
        PersonalRole.student => 'Просматривай расписание и следи за пропусками',
        PersonalRole.headman =>
          'Отмечай посещаемость своей группы и управляй составом',
        PersonalRole.teacher =>
          'Веди несколько групп, составляй расписание, собирай аналитику',
      };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _icon,
              size: 28,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _description,
                    style: TextStyle(
                      fontSize: 12,
                      color: selected
                          ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
