import 'package:edu_att/models/attendance_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/utils/attendance_analytics_helper.dart';
import 'package:edu_att/screens/student/widgets/subject_charts.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';

enum _Period { allTime, thisMonth, lastMonth, custom }

class SubjectAbsencesScreen extends ConsumerStatefulWidget {
  final String subjectName;

  const SubjectAbsencesScreen({super.key, required this.subjectName});

  @override
  ConsumerState<SubjectAbsencesScreen> createState() =>
      _SubjectAbsencesScreenState();
}

class _SubjectAbsencesScreenState
    extends ConsumerState<SubjectAbsencesScreen> {
  _Period _period = _Period.allTime;
  DateTimeRange? _customRange;

  List<LessonAttendanceModel> _applyFilter(
    List<LessonAttendanceModel> data,
  ) {
    final now = DateTime.now();
    return switch (_period) {
      _Period.allTime => data,
      _Period.thisMonth => data.where((a) {
          final d = a.lessonDate;
          return d != null && d.year == now.year && d.month == now.month;
        }).toList(),
      _Period.lastMonth => data.where((a) {
          final d = a.lessonDate;
          if (d == null) return false;
          final y = now.month == 1 ? now.year - 1 : now.year;
          final m = now.month == 1 ? 12 : now.month - 1;
          return d.year == y && d.month == m;
        }).toList(),
      _Period.custom => _customRange == null
          ? data
          : data.where((a) {
              final d = a.lessonDate;
              if (d == null) return false;
              final start = _customRange!.start;
              final end = DateTime(
                _customRange!.end.year,
                _customRange!.end.month,
                _customRange!.end.day,
                23,
                59,
                59,
              );
              return !d.isBefore(start) && !d.isAfter(end);
            }).toList(),
    };
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime(now.year, now.month, 1),
            end: now,
          ),
    );
    if (range != null && mounted) {
      setState(() {
        _customRange = range;
        _period = _Period.custom;
      });
    }
  }

  String _customLabel() {
    if (_customRange == null) return 'Период';
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    return '${fmt(_customRange!.start)} – ${fmt(_customRange!.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allAttendances = ref.watch(attendanceProvider);

    final subjectHistory = allAttendances
        .where((a) => a.subjectName == widget.subjectName)
        .toList();

    if (subjectHistory.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.subjectName),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _buildNoDataState(context),
      );
    }

    final filtered = _applyFilter(subjectHistory);
    final analysis = AttendanceAnalyticsHelper.getSubjectAnalysis(filtered);
    final absences = analysis.sortedHistory
        .where((a) => a.status == AttendanceStatus.absent)
        .toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              widget.subjectName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Фильтр по периоду
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip('Всё время', _Period.allTime),
                    const SizedBox(width: 8),
                    _chip('Этот месяц', _Period.thisMonth),
                    const SizedBox(width: 8),
                    _chip('Прошлый месяц', _Period.lastMonth),
                    const SizedBox(width: 8),
                    _customChip(colorScheme),
                  ],
                ),
              ),
            ),
          ),

          // Если в выбранном периоде данных нет
          if (analysis.isEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 48),
                child: _buildEmptyPeriodState(context),
              ),
            ),
          ] else ...[
            // Аналитика: кольцо + счётчики
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildAnalyticsCard(context, analysis),
              ),
            ),

            // Таймлайн
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _buildTimelineCard(context, analysis),
              ),
            ),

            // Заголовок списка пропусков
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Пропуски',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: absences.isEmpty
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${absences.length}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color:
                              absences.isEmpty ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (absences.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildNoAbsencesState(context),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList.separated(
                  itemCount: absences.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) =>
                      _buildAbsenceCard(context, absences[i]),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, _Period period) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = _period == period;
    return GestureDetector(
      onTap: () => setState(() => _period = period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _customChip(ColorScheme colorScheme) {
    final selected = _period == _Period.custom;
    return GestureDetector(
      onTap: _pickDateRange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.date_range_outlined,
              size: 14,
              color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              _customLabel(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(BuildContext context, SubjectAnalysis analysis) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          SubjectCircularChart(percentage: analysis.percentage),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _statRow(context, Icons.check_circle_outline, Colors.green,
                    'Присутствовал', analysis.present),
                const SizedBox(height: 10),
                _statRow(context, Icons.access_time, Colors.orange,
                    'Опоздал', analysis.late),
                const SizedBox(height: 10),
                _statRow(context, Icons.event_busy_outlined, Colors.red,
                    'Пропустил', analysis.absent),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1),
                ),
                _statRow(context, Icons.school_outlined,
                    colorScheme.primary, 'Всего', analysis.total),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(
    BuildContext context,
    IconData icon,
    Color color,
    String label,
    int value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineCard(BuildContext context, SubjectAnalysis analysis) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'История занятий',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${analysis.total} занятий',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SubjectHistoryTimeline(history: analysis.sortedHistory),
        ],
      ),
    );
  }

  Widget _buildNoDataState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EduMascot(state: MascotState.searching, height: 180),
          const SizedBox(height: 16),
          Text(
            'Статистика ещё не собрана\nФрося ждёт данных!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPeriodState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const EduMascot(state: MascotState.empty, height: 150),
        const SizedBox(height: 12),
        Text(
          'В этот период занятий не было',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildNoAbsencesState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        const EduMascot(state: MascotState.success, height: 140),
        const SizedBox(height: 12),
        Text(
          'Пропусков нет!\nФрося гордится тобой!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildAbsenceCard(
    BuildContext context,
    LessonAttendanceModel absence,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _formatDate(absence.lessonDate),
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '${absence.lessonStart ?? '??'} - ${absence.lessonEnd ?? '??'}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (absence.teacherName != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '${absence.teacherName} ${absence.teacherSurname ?? ''}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Дата не указана';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (day == today) return 'Сегодня';
    if (day == today.subtract(const Duration(days: 1))) return 'Вчера';
    return '${date.day}.${date.month}.${date.year}';
  }
}
