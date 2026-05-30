import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/models/teacher_model.dart';
import 'package:edu_att/providers/personal_mode_provider.dart';
import 'package:edu_att/theme/theme_provider.dart';
import 'package:edu_att/theme/app_theme_type.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/providers/frosya_provider.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';
import 'package:edu_att/widgets/modals/logout_confirm_dialog.dart';

class TeacherProfileContentScreen extends ConsumerWidget {
  const TeacherProfileContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final TeacherModel? teacher = ref.watch(teacherProvider);
    final isPersonal = ref.watch(personalModeProvider).isActive;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              _buildProfileHeader(context, teacher),
              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(context, 'Личные данные'),
                    const SizedBox(height: 12),
                    _buildInfoCard(context, 'Email', teacher?.email ?? 'Не указан'),
                    const SizedBox(height: 12),
                    _buildInfoCard(context, 'Логин', teacher?.login ?? 'Не указан'),
                    const SizedBox(height: 12),
                    _buildInfoCard(context, 'Кафедра', teacher?.department ?? 'Не указана'),

                    const SizedBox(height: 32),

                    _buildSectionTitle(context, 'Настройки приложения'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildMascotSettingsTile(context, ref),
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          _buildThemeSelector(context, ref),
                          if (isPersonal) ...[
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                            ListTile(
                              leading: const Icon(Icons.settings_suggest_outlined),
                              title: const Text('Управление данными'),
                              subtitle: const Text('Предметы, группы, расписание, бэкап'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.push('/personal/manage'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              _buildLogoutButton(context, ref, isPersonal),
            ],
          ),
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

  Widget _buildMascotSettingsTile(BuildContext context, WidgetRef ref) {
    final isMascotEnabled = ref.watch(mascotProvider);
    return ListTile(
      leading: const Icon(Icons.pets_outlined),
      title: const Text('Помощник Фрося'),
      subtitle: Text(isMascotEnabled ? 'Активна' : 'Спит'),
      trailing: Switch(
        value: isMascotEnabled,
        onChanged: (value) {
          ref.read(mascotProvider.notifier).toggleMascot();
          EduSnackBar.showInfo(
            context,
            ref,
            value ? 'Фрося проснулась!' : 'Режим минимализма включен',
          );
        },
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final themeNames = {
      AppThemeType.light: 'Светлая',
      AppThemeType.dark: 'Темная',
      AppThemeType.system: 'Системная',
    };
    return ListTile(
      leading: const Icon(Icons.palette_outlined),
      title: const Text('Тема оформления'),
      subtitle: Text(themeNames[currentTheme] ?? 'Системная'),
      onTap: () => _showThemeDialog(context, ref),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Выберите тему'),
        children: AppThemeType.values
            .map(
              (type) => SimpleDialogOption(
                onPressed: () {
                  ref.read(themeProvider.notifier).setTheme(type);
                  Navigator.pop(context);
                },
                child: Text(type.name.toUpperCase()),
              ),
            )
            .toList(),
      ),
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
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
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

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, bool isPersonal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: TextButton.icon(
          onPressed: () async {
            if (isPersonal) {
              final confirmed = await showPersonalLogoutDialog(context, ref);
              if (!confirmed || !context.mounted) return;
            }
            ref.read(teacherProvider.notifier).logout();
            ref.read(personalModeProvider.notifier).deactivate();
            if (context.mounted) context.go('/');
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
            backgroundColor: Colors.red.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
