import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/models/teacher_model.dart';
import 'package:edu_att/theme/theme_provider.dart'; // Провайдер темы
import 'package:edu_att/theme/app_theme_type.dart'; // Enum темы
import 'package:go_router/go_router.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/providers/frosya_provider.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';

class TeacherProfileContentScreen extends ConsumerWidget {
  const TeacherProfileContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TeacherModel? teacher = ref.watch(teacherProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              // --- Шапка профиля ---
              _buildProfileHeader(context, teacher),

              const SizedBox(height: 24),

              // --- Блок информации ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Личные данные'),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      'Email',
                      teacher?.email ?? 'Не указан',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      'Логин',
                      teacher?.login ?? 'Не указан',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      'Кафедра',
                      teacher?.department ?? 'Не указана',
                    ),

                    const SizedBox(height: 32),

                    // --- Блок настроек (ТЕМЫ) ---
                    _buildSectionTitle(context, 'Настройки'),
                    const SizedBox(height: 12),
                    _buildThemeSwitcher(context, ref),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, 'Настройки интерфейса'),
                    const SizedBox(height: 12),
                    _buildMascotSettings(context, ref),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- Кнопка выхода ---
              _buildLogoutButton(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMascotSettings(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    // Слушаем наш провайдер маскота
    final isMascotEnabled = ref.watch(mascotProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: ListTile(
        // Явно задаем размер контейнера для иконки
        leading: SizedBox(
          width: 40,
          height: 40,
          child:
              isMascotEnabled
                  ? EduMascot(
                    state: MascotState.idle,
                    height: 40,
                  ) // Указываем высоту
                  : Icon(
                    Icons.pets_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
        ),
        title: const Text(
          'Помощник Фрося',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),

        subtitle: Text(
          isMascotEnabled ? 'Котик активно помогает' : 'Котик спит и не мешает',
          style: const TextStyle(fontSize: 12),
        ),

        trailing: Switch(
          value: isMascotEnabled,
          onChanged: (value) {
            // Вызываем метод переключения в провайдере
            ref.read(mascotProvider.notifier).toggleMascot();

            // Маленький бонус: уведомление о смене режима
            if (value) {
              EduSnackBar.showInfo(context, ref, 'Фрося проснулась!');
            } else {
              // Если маскот выключен, EduSnackBar сам покажет "сухой" текст без картинки
              EduSnackBar.showInfo(context, ref, 'Режим минимализма включен');
            }
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, TeacherModel? teacher) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.person_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 36,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${teacher?.name ?? 'Имя'} ${teacher?.surname ?? 'Фамилия'}',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Преподаватель',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSwitcher(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentTheme = ref.watch(themeProvider);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          _buildThemeOption(
            context,
            ref,
            title: 'Светлая',
            icon: Icons.wb_sunny_outlined,
            type: AppThemeType.light,
            isSelected: currentTheme == AppThemeType.light,
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
          _buildThemeOption(
            context,
            ref,
            title: 'Темная',
            icon: Icons.nightlight_round_outlined,
            type: AppThemeType.dark,
            isSelected: currentTheme == AppThemeType.dark,
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
          _buildThemeOption(
            context,
            ref,
            title: 'Как в системе',
            icon: Icons.settings_brightness_outlined,
            type: AppThemeType.system,
            isSelected: currentTheme == AppThemeType.system,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required IconData icon,
    required AppThemeType type,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: () => ref.read(themeProvider.notifier).setTheme(type),
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing:
          isSelected
              ? Icon(Icons.check_circle, color: colorScheme.primary, size: 20)
              : null,
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: TextButton.icon(
          onPressed: () {
            ref.read(teacherProvider.notifier).logout();
            context.go('/');
          },
          icon: const Icon(Icons.logout_rounded, color: Colors.red),
          label: const Text(
            'Выйти из аккаунта',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
