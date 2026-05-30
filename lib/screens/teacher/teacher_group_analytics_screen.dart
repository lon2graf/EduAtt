import 'dart:math' as math;

import 'package:edu_att/models/group_analytics_data.dart';
import 'package:edu_att/providers/group_analytics_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/utils/attendance_pdf_generator.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

class TeacherGroupAnalyticsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String groupName;

  const TeacherGroupAnalyticsScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  ConsumerState<TeacherGroupAnalyticsScreen> createState() =>
      _TeacherGroupAnalyticsScreenState();
}

class _TeacherGroupAnalyticsScreenState
    extends ConsumerState<TeacherGroupAnalyticsScreen> {
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(groupAnalyticsProvider.notifier)
          .loadForGroup(widget.groupId, widget.groupName);
    });
  }

  Future<void> _exportPdf() async {
    final state = ref.read(groupAnalyticsProvider);
    if (state.data.isEmpty) {
      EduSnackBar.showInfo(context, ref, 'Нет данных для экспорта');
      return;
    }
    setState(() => _isExporting = true);
    try {
      final notifier = ref.read(groupAnalyticsProvider.notifier);
      final allRecords = notifier.records;
      final records = state.selectedSubject != null
          ? allRecords.where((r) => r.subjectName == state.selectedSubject).toList()
          : allRecords;

      final teacher = ref.read(teacherProvider);
      final teacherName =
          teacher != null ? '${teacher.surname} ${teacher.name}' : '';

      final periodLabel = _buildPeriodLabel(state);

      final bytes = await AttendancePdfGenerator.generate(
        groupName: widget.groupName,
        teacherFullName: teacherName,
        periodLabel: periodLabel,
        selectedSubject: state.selectedSubject,
        records: records,
      );

      final now = DateTime.now();
      await FilePicker.platform.saveFile(
        dialogTitle: 'Сохранить рапортичку',
        fileName:
            'Рапортичка_${widget.groupName}_${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}.pdf',
        bytes: bytes,
      );
    } catch (e) {
      if (mounted) EduSnackBar.showError(context, ref, 'Не удалось создать PDF');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _buildPeriodLabel(GroupAnalyticsState state) {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    return switch (state.period) {
      AnalyticsPeriod.allTime => 'за всё время',
      AnalyticsPeriod.thisMonth => () {
          final now = DateTime.now();
          return 'за ${now.month}.${now.year}';
        }(),
      AnalyticsPeriod.lastMonth => () {
          final now = DateTime.now();
          final last = DateTime(now.year, now.month - 1);
          return 'за ${last.month}.${last.year}';
        }(),
      AnalyticsPeriod.custom => state.customRange != null
          ? 'с ${fmt(state.customRange!.start)} по ${fmt(state.customRange!.end)}'
          : 'за всё время',
    };
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    );
    if (picked != null) {
      ref.read(groupAnalyticsProvider.notifier).changePeriod(
            AnalyticsPeriod.custom,
            customRange: picked,
          );
    }
  }

  String _customLabel(DateTimeRange? range) {
    if (range == null) return 'Период';
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    return '${fmt(range.start)} – ${fmt(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(groupAnalyticsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text('Аналитика · ${widget.groupName}'),
            centerTitle: false,
            actions: [
              if (_isExporting)
                const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Экспорт рапортички',
                  onPressed: state.data.isEmpty ? null : _exportPdf,
                ),
            ],
          ),

          // --- Чипы периода ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _PeriodChip(
                      label: 'Всё время',
                      selected: state.period == AnalyticsPeriod.allTime,
                      onTap: () => ref
                          .read(groupAnalyticsProvider.notifier)
                          .changePeriod(AnalyticsPeriod.allTime),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: 'Этот месяц',
                      selected: state.period == AnalyticsPeriod.thisMonth,
                      onTap: () => ref
                          .read(groupAnalyticsProvider.notifier)
                          .changePeriod(AnalyticsPeriod.thisMonth),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: 'Прошлый месяц',
                      selected: state.period == AnalyticsPeriod.lastMonth,
                      onTap: () => ref
                          .read(groupAnalyticsProvider.notifier)
                          .changePeriod(AnalyticsPeriod.lastMonth),
                    ),
                    const SizedBox(width: 8),
                    _PeriodChip(
                      label: state.period == AnalyticsPeriod.custom
                          ? _customLabel(state.customRange)
                          : 'Выбрать даты',
                      selected: state.period == AnalyticsPeriod.custom,
                      icon: Icons.date_range,
                      onTap: _pickCustomRange,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Чипы предметов (показываем только если предметов > 1) ---
          if (state.availableSubjects.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _PeriodChip(
                        label: 'Все предметы',
                        selected: state.selectedSubject == null,
                        icon: Icons.library_books_outlined,
                        onTap: () => ref
                            .read(groupAnalyticsProvider.notifier)
                            .selectSubject(null),
                      ),
                      ...state.availableSubjects.map(
                        (subject) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _PeriodChip(
                            label: subject,
                            selected: state.selectedSubject == subject,
                            onTap: () => ref
                                .read(groupAnalyticsProvider.notifier)
                                .selectSubject(subject),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.data.isEmpty)
            SliverFillRemaining(child: _EmptyState())
          else ...[
            // --- Кольцевой график + сводка ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _OverviewCard(
                  data: state.data,
                  selectedSubject: state.selectedSubject,
                ),
              ),
            ),

            // --- Динамика по занятиям ---
            if (state.data.timeline.length > 1)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _TimelineCard(timeline: state.data.timeline),
                ),
              ),

            // --- Зона риска ---
            if (state.data.atRisk.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _AtRiskCard(
                    students: state.data.atRisk,
                    colorScheme: colorScheme,
                  ),
                ),
              ),

            // --- Посещаемость по студентам ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _StudentBarsCard(students: state.data.byStudent),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ],
      ),
    );
  }
}

// ─── Чип периода ──────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Кольцевой график + сводка ────────────────────────────────────────────────

class _OverviewCard extends StatelessWidget {
  final GroupAnalyticsData data;
  final String? selectedSubject;

  const _OverviewCard({required this.data, this.selectedSubject});

  Color _color() {
    if (data.overallPercentage >= 80) return Colors.green;
    if (data.overallPercentage >= 50) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _color();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Кольцо
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: data.overallPercentage),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, __) => SizedBox(
              width: 110,
              height: 110,
              child: CustomPaint(
                painter: _RingPainter(
                  percentage: value,
                  color: color,
                  trackColor: colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${value.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        selectedSubject != null
                            ? (selectedSubject!.length > 10
                                ? '${selectedSubject!.substring(0, 9)}…'
                                : selectedSubject!)
                            : 'группа',
                        style: TextStyle(
                          fontSize: 9,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          // Сводка
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  color: Colors.green,
                  label: 'Присутствовали',
                  value: data.totalPresent,
                ),
                const SizedBox(height: 6),
                _StatRow(
                  color: Colors.orange,
                  label: 'Опоздали',
                  value: data.totalLate,
                ),
                const SizedBox(height: 6),
                _StatRow(
                  color: Colors.red,
                  label: 'Пропустили',
                  value: data.totalAbsent,
                ),
                const SizedBox(height: 10),
                Text(
                  'Занятий: ${data.timeline.length}',
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
    );
  }
}

class _StatRow extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _StatRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
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
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color trackColor;

  const _RingPainter({
    required this.percentage,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
    if (percentage <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * (percentage.clamp(0, 100) / 100),
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.percentage != percentage || old.color != color;
}

// ─── Динамика по занятиям ─────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final List<LessonTimelineStat> timeline;

  const _TimelineCard({required this.timeline});

  Color _barColor(double pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 50) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final n = timeline.length;

    return Container(
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
          const Text(
            'Динамика по занятиям',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth =
                  ((constraints.maxWidth / n) * 0.72).clamp(4.0, 32.0);
              final interval = n <= 8 ? 1.0 : (n / 6).ceilToDouble();

              return SizedBox(
                height: 100,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: 100,
                    minY: 0,
                    barGroups: timeline.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.percentage,
                            color: _barColor(e.value.percentage),
                            width: barWidth,
                            borderRadius: BorderRadius.circular(3),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 100,
                              color: colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: interval,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= n) return const SizedBox.shrink();
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.black87,
                        getTooltipItem: (group, _, rod, __) {
                          final lesson = timeline[group.x];
                          final d = lesson.date;
                          return BarTooltipItem(
                            '${d.day}.${d.month}  ${lesson.percentage.toStringAsFixed(0)}%\n'
                            '${lesson.presentCount}/${lesson.totalStudents} студ.',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  duration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Занятие №  (нажмите на столбик — увидите дату и явку)',
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Зона риска ───────────────────────────────────────────────────────────────

class _AtRiskCard extends StatelessWidget {
  final List<StudentAttendanceStat> students;
  final ColorScheme colorScheme;

  const _AtRiskCard({required this.students, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red.shade700, size: 18),
              const SizedBox(width: 6),
              Text(
                'Требуют внимания · ${students.length} чел.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...students.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.studentName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${s.percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${s.absent} пр.)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Посещаемость по студентам ────────────────────────────────────────────────

class _StudentBarsCard extends StatelessWidget {
  final List<StudentAttendanceStat> students;

  const _StudentBarsCard({required this.students});

  Color _barColor(double pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 50) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
          const Text(
            'Посещаемость студентов',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          Text(
            'Отсортировано по возрастанию',
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...students.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(
                      s.studentName,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: s.percentage / 100),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor:
                              colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(
                              _barColor(s.percentage)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 38,
                    child: Text(
                      '${s.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _barColor(s.percentage),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Пустое состояние ─────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EduMascot(state: MascotState.empty, height: 160),
          const SizedBox(height: 16),
          Text(
            'Данных о посещаемости пока нет.\nОтметьте хотя бы одно занятие.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
