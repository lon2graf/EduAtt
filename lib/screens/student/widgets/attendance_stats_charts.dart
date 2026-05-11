import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/utils/attendance_analytics_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AttendanceStatsSection extends StatefulWidget {
  final List<LessonAttendanceModel> attendances;

  const AttendanceStatsSection({super.key, required this.attendances});

  @override
  State<AttendanceStatsSection> createState() => _AttendanceStatsSectionState();
}

class _AttendanceStatsSectionState extends State<AttendanceStatsSection> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final withStatus =
        widget.attendances.where((a) => a.status != null).toList();

    if (withStatus.isEmpty) {
      return _buildEmptyState(context);
    }

    final statusCounts =
        AttendanceAnalyticsHelper.calculateStatusCounts(withStatus);
    final subjectStats =
        AttendanceAnalyticsHelper.calculateSubjectStats(withStatus);
    final overallPct =
        AttendanceAnalyticsHelper.calculateOverallPercentage(withStatus);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        if (overallPct >= 90) ...[
          _buildPraiseCard(context, overallPct),
          const SizedBox(height: 12),
        ],
        _buildPieChartCard(context, statusCounts, withStatus.length),
        if (subjectStats.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildSubjectStatsCard(context, subjectStats),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EduMascot(state: MascotState.empty, height: 180),
          const SizedBox(height: 16),
          Text(
            'Данных пока нет\nФрося ждёт твоих занятий!',
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

  Widget _buildPraiseCard(BuildContext context, double pct) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const EduMascot(state: MascotState.success, height: 72),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Фрося тобой гордится! 🐾',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Посещаемость ${pct.toStringAsFixed(0)}% — так держать!',
                  style: TextStyle(fontSize: 13, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(
    BuildContext context,
    Map<AttendanceStatus, int> counts,
    int total,
  ) {
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
          Text(
            'Общая статистика',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _AttendancePieChart(
                        counts: counts,
                        touchedIndex: _touchedPieIndex,
                        onTouch: (i) => setState(() => _touchedPieIndex = i),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'занятий',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem(
                      Colors.green,
                      'Присутствовал',
                      counts[AttendanceStatus.present] ?? 0,
                    ),
                    const SizedBox(height: 10),
                    _legendItem(
                      Colors.red,
                      'Отсутствовал',
                      counts[AttendanceStatus.absent] ?? 0,
                    ),
                    const SizedBox(height: 10),
                    _legendItem(
                      Colors.orange,
                      'Опоздал',
                      counts[AttendanceStatus.late] ?? 0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubjectStatsCard(
    BuildContext context,
    List<SubjectStat> stats,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final chartHeight = (stats.length * 44.0).clamp(160.0, 300.0);

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
          Text(
            'По предметам',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _SubjectAttendanceBarChart(stats: stats, height: chartHeight),
        ],
      ),
    );
  }
}

class _AttendancePieChart extends StatelessWidget {
  final Map<AttendanceStatus, int> counts;
  final int touchedIndex;
  final ValueChanged<int> onTouch;

  const _AttendancePieChart({
    required this.counts,
    required this.touchedIndex,
    required this.onTouch,
  });

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    if (sections.isEmpty) return const SizedBox.shrink();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 48,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            if (!event.isInterestedForInteractions ||
                response?.touchedSection == null) {
              onTouch(-1);
              return;
            }
            onTouch(response!.touchedSection!.touchedSectionIndex);
          },
        ),
      ),
      duration: const Duration(milliseconds: 200),
    );
  }

  List<PieChartSectionData> _buildSections() {
    const entries = [
      (AttendanceStatus.present, Colors.green),
      (AttendanceStatus.absent, Colors.red),
      (AttendanceStatus.late, Colors.orange),
    ];

    int sectionIdx = 0;
    final List<PieChartSectionData> sections = [];

    for (final entry in entries) {
      final count = counts[entry.$1] ?? 0;
      if (count == 0) continue;
      final isTouched = sectionIdx == touchedIndex;
      sections.add(PieChartSectionData(
        value: count.toDouble(),
        color: entry.$2,
        radius: isTouched ? 68 : 58,
        title: '$count',
        showTitle: true,
        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isTouched ? 14 : 11,
        ),
      ));
      sectionIdx++;
    }
    return sections;
  }
}

class _SubjectAttendanceBarChart extends StatelessWidget {
  final List<SubjectStat> stats;
  final double height;

  const _SubjectAttendanceBarChart({
    required this.stats,
    required this.height,
  });

  Color _barColor(double pct) {
    if (pct >= 80) return Colors.green;
    if (pct >= 50) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barWidth = stats.length > 6 ? 14.0 : 20.0;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barGroups: stats.asMap().entries.map((entry) {
            final stat = entry.value;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: stat.percentage,
                  color: _barColor(stat.percentage),
                  width: barWidth,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
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
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: 25,
                getTitlesWidget: (value, meta) => Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= stats.length) {
                    return const SizedBox.shrink();
                  }
                  final name = stats[i].name;
                  final short =
                      name.length > 8 ? '${name.substring(0, 7)}.' : name;
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      short,
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
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black87,
              getTooltipItem: (group, _, rod, __) {
                final stat = stats[group.x];
                return BarTooltipItem(
                  '${stat.name}\n'
                  '${stat.percentage.toStringAsFixed(0)}%  '
                  '(${stat.present}/${stat.total})',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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
  }
}
