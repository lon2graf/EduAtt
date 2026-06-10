import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/providers/group_provider.dart';
import 'package:edu_att/providers/lesson_attendance_mark_provider.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';
import 'package:edu_att/providers/connectivity_provider.dart';
import 'package:edu_att/providers/group_analytics_provider.dart';
import 'package:edu_att/providers/personal_mode_provider.dart';
import 'package:edu_att/providers/schedule_provider.dart';
import 'package:edu_att/data/repositories/excuse_repository.dart';

// --- ВСПОМОГАТЕЛЬНЫЙ ВИДЖЕТ ---
class LiveIndicator extends StatefulWidget {
  const LiveIndicator({super.key});
  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class TeacherHomeContentScreen extends ConsumerStatefulWidget {
  const TeacherHomeContentScreen({super.key});
  @override
  ConsumerState<TeacherHomeContentScreen> createState() =>
      _TeacherHomeContentScreenState();
}

class _TeacherHomeContentScreenState
    extends ConsumerState<TeacherHomeContentScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
      final teacher = ref.read(teacherProvider);
      if (teacher?.id != null) {
        ref
            .read(currentLessonProvider.notifier)
            .loadCurrentOrNextLessonForTeacher(teacher!.id!);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final teacher = ref.read(teacherProvider);
    if (teacher == null || teacher.id == null) return;
    await ref
        .read(currentLessonProvider.notifier)
        .loadCurrentOrNextLessonForTeacher(teacher.id!);
    final lesson = ref.read(currentLessonProvider);
    if (lesson != null && lesson.groupId.isNotEmpty) {
      ref
          .read(groupAnalyticsProvider.notifier)
          .loadForGroup(lesson.groupId, lesson.groupName);
    }
    // Фоновая синхронизация объяснительных — обновляет бейдж без блокировки UI
    ref.read(excuseRepositoryProvider).syncForTeacher(teacher.id!);
  }

  @override
  Widget build(BuildContext context) {
    final teacher = ref.watch(teacherProvider);
    final lesson = ref.watch(currentLessonProvider);

    ref.listen<LessonModel?>(currentLessonProvider, (previous, next) {
      if (next?.status == LessonAttendanceStatus.waitConfirmation) {
        EduSnackBar.showInfo(
          context,
          ref,
          "Староста отправил ведомость на проверку!",
        );
      }
    });

    // Переход в офлайн/онлайн через реальный auth-check
    ref.listen<bool>(offlineModeProvider, (wasOffline, isOffline) {
      if (isOffline && wasOffline == false) {
        EduSnackBar.showWaiting(
          context,
          ref,
          'Нет соединения с сервером. Работаем оффлайн',
        );
      } else if (!isOffline && wasOffline == true) {
        EduSnackBar.showSuccess(context, ref, 'Соединение восстановлено');
        ref.read(scheduleProvider.notifier).syncSchedule();
        ref.read(lessonAttendanceMarkProvider.notifier).syncPending();
        ref.read(excuseRepositoryProvider).syncPending();
      }
    });

    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: _buildHeader(context, teacher),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStatsRow(context, lesson),
              ),
            ),
            if (lesson != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: _buildSectionHeader(context, 'Аналитика группы'),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildAnalyticsCard(context, lesson),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: _buildSectionHeader(context, 'Активное занятие'),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child:
                    lesson != null
                        ? _buildLiveLessonCard(context, lesson, isOffline)
                        : _buildNoLessonState(context),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, var teacher) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Здравствуйте,',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              '${teacher?.name ?? 'Преподаватель'}! 👋',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: (ref.watch(pendingExcuseCountProvider).asData?.value ?? 0) > 0,
              label: Text(
                '${ref.watch(pendingExcuseCountProvider).asData?.value ?? 0}',
              ),
              child: IconButton(
                icon: const Icon(Icons.history_outlined),
                tooltip: 'История занятий',
                onPressed: () => context.push('/teacher/history'),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: 'Расписание',
              onPressed: () => context.push('/schedule'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildLiveLessonCard(BuildContext context, LessonModel lesson, bool isOffline) {
    final colorScheme = Theme.of(context).colorScheme;
    double progress = _calculateTimeProgress(lesson.startTime, lesson.endTime);

    String formatTime(String time) {
      try {
        final parts = time.split(':');
        return parts.length >= 2 ? "${parts[0]}:${parts[1]}" : time;
      } catch (_) {
        return time;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLiveBadge(lesson),
                    const SizedBox(height: 12),
                    Text(
                      '${formatTime(lesson.startTime)} - ${formatTime(lesson.endTime)}',
                      style: TextStyle(
                        color: colorScheme.onPrimary.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lesson.subjectName.isEmpty ? 'Предмет' : lesson.subjectName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Внутри метода _buildLiveLessonCard:
                    Text(
                      'Группа: ${lesson.groupName}', // Заменяем lesson.groupId на lesson.groupName
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onPrimary.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const EduMascot(state: MascotState.science, height: 90),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusInfo(context, lesson),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: colorScheme.onPrimary.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
            ),
          ),
          const SizedBox(height: 24),
          _buildTeacherActions(context, lesson, isOffline),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(BuildContext context, LessonModel lesson) {
    String text = "Занятие активно";
    if (lesson.status == LessonAttendanceStatus.onHeadmanEditing) {
      text = "👨‍🎓 Староста отмечает посещаемость";
    } else if (lesson.status == LessonAttendanceStatus.waitConfirmation) {
      text = "📩 Ведомость ждет вашего подтверждения";
    } else if (lesson.status == LessonAttendanceStatus.confirmed) {
      text = "✅ Учет завершен";
    }
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildLiveBadge(LessonModel lesson) {
    final upcoming = lesson.isUpcoming;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: upcoming ? Colors.blueAccent : Colors.redAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!upcoming) const LiveIndicator(),
          if (!upcoming) const SizedBox(width: 8),
          if (upcoming) const Icon(Icons.access_time, size: 10, color: Colors.white),
          if (upcoming) const SizedBox(width: 4),
          Text(
            upcoming ? 'СКОРО' : 'LIVE',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherActions(BuildContext context, LessonModel lesson, bool isOffline) {
    final isPersonal = ref.read(personalModeProvider).isActive;
    return Row(
      children: [
        if (!isPersonal) ...[
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => context.go('/lesson_chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Icon(Icons.chat_bubble_outline, size: 20),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: isPersonal ? 7 : 5,
          child: _buildTeacherMainButton(context, lesson, isOffline),
        ),
      ],
    );
  }

  Widget _buildTeacherMainButton(BuildContext context, LessonModel lesson, bool isOffline) {
    final colorScheme = Theme.of(context).colorScheme;
    String btnText = 'ПЕРЕКЛИЧКА';
    Color btnTextColor = colorScheme.primary;
    IconData icon = Icons.edit_square;
    bool isDanger = false;

    if (lesson.status == LessonAttendanceStatus.onHeadmanEditing) {
      btnText = 'ПЕРЕХВАТИТЬ';
      btnTextColor = Colors.orange.shade900;
      icon = Icons.warning_amber_rounded;
      isDanger = true;
    } else if (lesson.status == LessonAttendanceStatus.waitConfirmation) {
      btnText = 'ПРОВЕРИТЬ';
      btnTextColor = Colors.blue.shade900;
      icon = Icons.fact_check_outlined;
    } else if (lesson.status == LessonAttendanceStatus.confirmed) {
      btnText = 'ИЗМЕНИТЬ';
      icon = Icons.lock_open;
    }

    return ElevatedButton.icon(
      onPressed: () => _handleTeacherAction(lesson, isDanger),
      icon: Icon(icon, size: 20),
      label: Text(
        btnText,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: btnTextColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _handleTeacherAction(
    LessonModel lesson,
    bool isDanger,
  ) async {
    final isOffline = ref.read(isOfflineProvider);

    if (!isOffline) {
      try {
        final freshStatus = await ref.read(currentLessonProvider.notifier).getFreshStatus();
        if (freshStatus != lesson.status) {
          if (mounted) {
            EduSnackBar.showInfo(context, ref, "Статус обновился. Фрося обновляет экран...");
            _loadInitialData();
          }
          return;
        }
      } catch (_) {
        // сеть пропала между проверкой — продолжаем с локальным статусом
      }
    }

    if (isDanger) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Перехватить управление?'),
          content: const Text(
            'Староста сейчас заполняет ведомость. Его данные могут быть потеряны.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: const Text('Перехватить', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    if (mounted) _enterEditMode(lesson);
  }

  Future<void> _enterEditMode(LessonModel lesson) async {
    try {
      await ref
          .read(currentLessonProvider.notifier)
          .updateLessonStatus(LessonAttendanceStatus.onTeacherEditing);

      if (lesson.groupId.isNotEmpty) {
        await ref.read(groupStudentsProvider.notifier).loadGroupStudents(lesson.groupId);
        final students = ref.read(groupStudentsProvider);
        await ref
            .read(lessonAttendanceMarkProvider.notifier)
            .initializeAttendance(students, ref.read(currentLessonProvider));
        if (mounted) context.go('/teacher/mark');
      }
    } catch (e) {
      if (mounted) EduSnackBar.showError(context, ref, "Не удалось открыть ведомость");
    }
  }

  double _calculateTimeProgress(String startStr, String endStr) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = today.add(
        Duration(
          hours: int.parse(startStr.split(':')[0]),
          minutes: int.parse(startStr.split(':')[1]),
        ),
      );
      final end = today.add(
        Duration(
          hours: int.parse(endStr.split(':')[0]),
          minutes: int.parse(endStr.split(':')[1]),
        ),
      );
      if (now.isBefore(start)) return 0.0;
      if (now.isAfter(end)) return 1.0;
      return now.difference(start).inSeconds / end.difference(start).inSeconds;
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildAnalyticsCard(BuildContext context, LessonModel lesson) {
    final colorScheme = Theme.of(context).colorScheme;
    final analytics = ref.watch(groupAnalyticsProvider);

    Color pctColor(double pct) {
      if (pct >= 80) return Colors.green;
      if (pct >= 50) return Colors.amber;
      return Colors.red;
    }

    return GestureDetector(
      onTap: () => context.push(
        '/teacher/analytics'
        '?group=${Uri.encodeComponent(lesson.groupId)}'
        '&name=${Uri.encodeComponent(lesson.groupName)}',
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bar_chart_rounded, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Аналитика посещаемости',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    analytics.isLoading
                        ? 'Загружаем...'
                        : analytics.data.isEmpty
                            ? 'Нет данных — отметьте первое занятие'
                            : '${analytics.data.timeline.length} зан. · '
                                '${analytics.data.atRisk.length} в зоне риска',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (!analytics.isLoading && !analytics.data.isEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: pctColor(analytics.data.overallPercentage)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${analytics.data.overallPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: pctColor(analytics.data.overallPercentage),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLessonState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
          const EduMascot(state: MascotState.empty, height: 200),
          const SizedBox(height: 16),
          Text(
            'Пар пока нет, Фрося отдыхает...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, LessonModel? lesson) {
    final String today = _getFormattedDate();
    return Row(
      children: [
        _buildSmallStatCard(
          context,
          lesson?.groupName ?? '—',
          'Учебная группа',
          Icons.group_outlined,
        ),
        const SizedBox(width: 12),
        _buildSmallStatCard(
          context,
          today,
          'Дата',
          Icons.calendar_today_outlined,
        ),
      ],
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  Widget _buildSmallStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
