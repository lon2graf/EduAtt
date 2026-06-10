import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/models/schedule_model.dart';
import 'package:edu_att/providers/schedule_provider.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/providers/personal_mode_provider.dart';
import 'package:edu_att/screens/personal/schedule_entry_sheet.dart';
import 'package:edu_att/widgets/skeletons/skeleton_base.dart';
import 'package:edu_att/widgets/skeletons/schedule_card_skeleton.dart';

// Короткие названия дней недели (DateTime.weekday: 1=Пн … 7=Вс)
const _kWeekdayNames = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

// Полные названия месяцев (индекс = month - 1)
const _kMonthNames = [
  'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
];

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  // 0 = текущая неделя, -1 = прошлая, +1 = следующая
  int _weekOffset = 0;

  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initStream());
    // Перерисовываем каждую минуту, чтобы баннер появлялся/исчезал по расписанию
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<void> _initStream() async {
    final teacher = ref.read(teacherProvider);
    final student = ref.read(currentStudentProvider);
    final notifier = ref.read(scheduleProvider.notifier);

    if (teacher != null && teacher.id != null) {
      await notifier.initTeacherScheduleStream(teacher.id!);
    } else if (student != null) {
      await notifier.initScheduleStream(student.groupId);
    }
  }

  Future<void> _onRefresh() =>
      ref.read(scheduleProvider.notifier).syncSchedule();

  /// Первый день текущей отображаемой недели (Понедельник)
  DateTime get _weekStart {
    final now = DateTime.now();
    final mondayOffset = now.weekday - 1; // DateTime.weekday: 1=Mon
    final monday = now.subtract(Duration(days: mondayOffset));
    final shifted = monday.add(Duration(days: _weekOffset * 7));
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scheduleProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isPersonal = ref.watch(personalModeProvider).isActive;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Расписание'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButton: isPersonal
          ? FloatingActionButton(
              tooltip: 'Добавить занятие',
              onPressed: () => showScheduleEntrySheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          _WeekStrip(
            weekDays: _weekDays,
            selectedDay: state.selectedDay,
            weekOffset: _weekOffset,
            onDaySelected: (day) =>
                ref.read(scheduleProvider.notifier).selectDay(day),
            onPrevWeek: () => setState(() => _weekOffset--),
            onNextWeek: () => setState(() => _weekOffset++),
          ),
          const Divider(height: 1),
          Builder(builder: (_) {
            final now = DateTime.now();
            final isToday = state.selectedDay.year == now.year &&
                state.selectedDay.month == now.month &&
                state.selectedDay.day == now.day;
            if (!isToday) return const SizedBox.shrink();
            final ongoing = state.ongoingLesson;
            final next = state.nextTodayLesson;
            final banner = ongoing ?? next;
            if (banner == null) return const SizedBox.shrink();
            return _NextLessonBanner(
              lesson: banner,
              isOngoing: ongoing != null,
            );
          }),
          Expanded(
            child: isPersonal
                ? _ScheduleBody(state: state)
                : RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: _ScheduleBody(state: state),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Week Strip ───────────────────────

class _WeekStrip extends StatelessWidget {
  final List<DateTime> weekDays;
  final DateTime selectedDay;
  final int weekOffset;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPrevWeek;
  final VoidCallback onNextWeek;

  const _WeekStrip({
    required this.weekDays,
    required this.selectedDay,
    required this.weekOffset,
    required this.onDaySelected,
    required this.onPrevWeek,
    required this.onNextWeek,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) => _isSameDay(d, DateTime.now());

  /// "Май 2026" или "Апр / Май 2026" если неделя пересекает два месяца
  String get _monthLabel {
    final first = weekDays.first;
    final last = weekDays.last;
    if (first.month == last.month) {
      return '${_kMonthNames[first.month - 1]} ${first.year}';
    }
    // Неделя пересекает границу месяцев
    final suffix = first.year == last.year ? '${last.year}' : '';
    return '${_kMonthNames[first.month - 1]} / ${_kMonthNames[last.month - 1]} $suffix'.trim();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Заголовок месяца
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _monthLabel,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
        Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrevWeek,
            tooltip: 'Предыдущая неделя',
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekDays.map((day) {
                final selected = _isSameDay(day, selectedDay);
                final today = _isToday(day);

                return GestureDetector(
                  onTap: () => onDaySelected(day),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 38,
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: today && !selected
                          ? Border.all(color: colorScheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _kWeekdayNames[day.weekday],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? colorScheme.onPrimary
                                : today
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNextWeek,
            tooltip: 'Следующая неделя',
          ),
        ],
      ),
    ),      // closes Padding (days row)
  ],        // closes Column children
);          // closes Column
  }
}

// ─────────────────────── Body ───────────────────────

class _ScheduleBody extends StatelessWidget {
  final ScheduleState state;

  const _ScheduleBody({required this.state});

  @override
  Widget build(BuildContext context) {
    // ── Скелетон при загрузке ──────────────────────────────────────────────
    if (state.isLoading) {
      return EduSkeleton(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: 5,
          itemBuilder: (_, __) => const ScheduleCardSkeleton(),
        ),
      );
    }

    final items = state.schedulesForDay;

    if (items.isEmpty) {
      // Wrap in ListView so RefreshIndicator can trigger on empty state.
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                EduMascot(state: MascotState.empty, height: 120),
                const SizedBox(height: 16),
                Text(
                  'Занятий в этот день нет',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      itemBuilder: (context, index) => _ScheduleCard(item: items[index]),
    );
  }
}

// ─────────────────────── Next Lesson Banner ───────────────────────

class _NextLessonBanner extends StatefulWidget {
  final ScheduleModel lesson;
  final bool isOngoing;

  const _NextLessonBanner({required this.lesson, required this.isOngoing});

  @override
  State<_NextLessonBanner> createState() => _NextLessonBannerState();
}

class _NextLessonBannerState extends State<_NextLessonBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _countdown(String timeStr, {required bool isEnd}) {
    final now = DateTime.now();
    final parts = timeStr.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    final target = DateTime(now.year, now.month, now.day, h, m);
    final diff = target.difference(now);
    if (!diff.isNegative && diff.inMinutes == 0) {
      return isEnd ? 'заканчивается вот-вот' : 'начинается вот-вот';
    }
    final totalMin = diff.inMinutes.abs();
    if (totalMin < 60) {
      return isEnd ? 'ещё $totalMin мин' : 'через $totalMin мин';
    }
    final hrs = totalMin ~/ 60;
    final mins = totalMin % 60;
    final mStr = mins > 0 ? ' $mins мин' : '';
    return isEnd ? 'ещё ${hrs}ч$mStr' : 'через ${hrs}ч$mStr';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lesson = widget.lesson;
    final isOngoing = widget.isOngoing;

    final bgColor =
        isOngoing ? colorScheme.primaryContainer : colorScheme.secondaryContainer;
    final fgColor = isOngoing
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    final label = isOngoing ? 'Сейчас идёт' : 'Следующее занятие';
    final countdown = isOngoing
        ? _countdown(lesson.endTime, isEnd: true)
        : _countdown(lesson.startTime, isEnd: false);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isOngoing ? Icons.play_circle_outline : Icons.access_time_rounded,
            color: fgColor,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: fgColor.withValues(alpha: 0.7),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lesson.subjectName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${lesson.startTimeShort} – ${lesson.endTimeShort}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fgColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                countdown,
                style: TextStyle(
                  fontSize: 11,
                  color: fgColor.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── Card ───────────────────────

class _ScheduleCard extends StatelessWidget {
  final ScheduleModel item;

  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Время
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item.startTimeShort,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                Container(
                  width: 1.5,
                  height: 20,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  color: colorScheme.outlineVariant,
                ),
                Text(
                  item.endTimeShort,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Основная информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subjectName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (item.topic != null && item.topic!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.topic!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.teacherFullName,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.group_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        item.groupName,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
