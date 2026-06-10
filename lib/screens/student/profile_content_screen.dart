import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/providers/personal_mode_provider.dart';
import 'package:edu_att/theme/theme_provider.dart';
import 'package:edu_att/theme/app_theme_type.dart';
import 'package:edu_att/providers/frosya_provider.dart';
import 'package:edu_att/utils/attendance_analytics_helper.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/widgets/modals/logout_confirm_dialog.dart';

class ProfileContentScreen extends ConsumerWidget {
  const ProfileContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final StudentModel? student = ref.watch(currentStudentProvider);
    final allAttendances = ref.watch(attendanceProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              // --- Шапка профиля ---
              _buildProfileHeader(context, student),

              const SizedBox(height: 20),

              // --- Карточка посещаемости ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildAttendanceCard(context, allAttendances, colorScheme),
              ),

              const SizedBox(height: 12),

              // --- Кнопка детальной аналитики по предметам ---
              if (allAttendances.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildSubjectStatsButton(context, colorScheme),
                ),

              const SizedBox(height: 24),

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
                      student?.email ?? 'Не указан',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      'Логин',
                      student?.login ?? 'Не указан',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      'Роль',
                      student?.isHeadman == true ? 'Староста' : 'Студент',
                    ),

                    const SizedBox(height: 32),

                    // --- Настройки ---
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
                          if (ref.watch(mascotProvider)) ...[
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                            _buildMascotAnimationTile(context, ref),
                          ],
                          Divider(
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          _buildThemeSelector(context, ref),
                          if (ref.watch(personalModeProvider).isActive) ...[
                            Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                            ListTile(
                              leading: const Icon(Icons.settings_suggest_outlined),
                              title: const Text('Управление данными'),
                              subtitle: const Text('Предметы, расписание, бэкап'),
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
              _buildLogoutButton(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context,
    List<LessonAttendanceModel> attendances,
    ColorScheme colorScheme,
  ) {
    final withStatus = attendances.where((a) => a.status != null).toList();
    if (withStatus.isEmpty) return const SizedBox.shrink();

    final pct = AttendanceAnalyticsHelper.calculateOverallPercentage(attendances);
    final counts = AttendanceAnalyticsHelper.calculateStatusCounts(attendances);
    final total = withStatus.length;

    final isCritical = pct < 60;
    final isAtRisk = pct < 75;

    final pctColor = isCritical
        ? Colors.red.shade600
        : isAtRisk
            ? Colors.orange.shade700
            : Colors.green.shade600;

    final bgColor = isAtRisk
        ? pctColor.withValues(alpha: 0.07)
        : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    final borderColor = isAtRisk
        ? pctColor.withValues(alpha: 0.35)
        : colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            '${pct.round()}%',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: pctColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'посещаемость',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatChip(
                icon: Icons.check_circle_outline,
                value: counts[AttendanceStatus.present] ?? 0,
                label: 'Был',
                color: Colors.green.shade600,
              ),
              _StatChip(
                icon: Icons.access_time_outlined,
                value: counts[AttendanceStatus.late] ?? 0,
                label: 'Опоздал',
                color: Colors.orange.shade700,
              ),
              _StatChip(
                icon: Icons.cancel_outlined,
                value: counts[AttendanceStatus.absent] ?? 0,
                label: 'Пропустил',
                color: Colors.red.shade600,
              ),
              _StatChip(
                icon: Icons.format_list_numbered_outlined,
                value: total,
                label: 'Всего',
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          if (isAtRisk) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 12),
            Row(
              children: [
                EduMascot(
                  state: isCritical ? MascotState.error : MascotState.waiting,
                  height: 52,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Фрося беспокоится',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: pctColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCritical
                            ? 'Посещаемость критически низкая — срочно наверстай!'
                            : 'Посещаемость ниже нормы. Старайся не пропускать.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectStatsButton(BuildContext context, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => context.push('/student/subject_stats'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: colorScheme.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Посещаемость по предметам',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, StudentModel? student) {
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
                  '${student?.name ?? 'Имя'} ${student?.surname ?? 'Фамилия'}',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  student?.groupName ?? 'Группа не указана',
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

  Widget _buildMascotAnimationTile(BuildContext context, WidgetRef ref) {
    final isAnimated = ref.watch(mascotAnimationProvider);
    return ListTile(
      leading: const Icon(Icons.animation_outlined),
      title: const Text('Анимация Фроси'),
      subtitle: Text(isAnimated ? 'Летает' : 'Стоит спокойно'),
      trailing: Switch(
        value: isAnimated,
        onChanged: (_) {
          ref.read(mascotAnimationProvider.notifier).toggle();
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
      builder:
          (context) => SimpleDialog(
            title: const Text('Выберите тему'),
            children:
                AppThemeType.values
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

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: TextButton.icon(
          onPressed: () async {
            final isPersonal = ref.read(personalModeProvider).isActive;
            if (isPersonal) {
              final confirmed = await showPersonalLogoutDialog(context, ref);
              if (!confirmed || !context.mounted) return;
            }
            ref.read(currentStudentProvider.notifier).logout();
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

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
