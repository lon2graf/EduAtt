import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/utils/attendance_analytics_helper.dart';

class SubjectStatsScreen extends ConsumerWidget {
  const SubjectStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendances = ref.watch(attendanceProvider);
    final stats = AttendanceAnalyticsHelper.calculateSubjectStats(attendances);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('По предметам'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: stats.isEmpty
          ? _buildEmpty(colorScheme)
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _buildChart(context, stats, colorScheme),
                const SizedBox(height: 24),
                ...stats.map((s) => _SubjectCard(stat: s)),
              ],
            ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Данных о посещаемости пока нет',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<SubjectStat> stats,
    ColorScheme colorScheme,
  ) {
    // Обрезаем до 8 предметов если их много — иначе бары слишком узкие
    final visible = stats.take(8).toList();
    final barHeight = 28.0;
    final chartHeight = visible.length * (barHeight + 12.0) + 24;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Посещаемость по предметам',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: chartHeight,
              child: RotatedBox(
                quarterTurns: -1,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: 100,
                    minY: 0,
                    barGroups: visible.asMap().entries.map((e) {
                      final pct = e.value.percentage;
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: pct,
                            width: barHeight,
                            color: _barColor(pct),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 100,
                              color: colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ],
                        showingTooltipIndicators: [],
                      );
                    }).toList(),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= visible.length) {
                              return const SizedBox.shrink();
                            }
                            final pct = visible[i].percentage;
                            return RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                '${pct.round()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _barColor(pct),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 72,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= visible.length) {
                              return const SizedBox.shrink();
                            }
                            return RotatedBox(
                              quarterTurns: 1,
                              child: SizedBox(
                                width: 68,
                                child: Text(
                                  visible[i].name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _barColor(double pct) {
    if (pct >= 80) return Colors.green.shade500;
    if (pct >= 60) return Colors.orange.shade500;
    return Colors.red.shade400;
  }
}

// ── Карточка предмета ──────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final SubjectStat stat;

  const _SubjectCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pct = stat.percentage;
    final color = _color(pct);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stat.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${pct.round()}%',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 6,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Посетил ${stat.present} из ${stat.total} занятий',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _color(double pct) {
    if (pct >= 80) return Colors.green.shade500;
    if (pct >= 60) return Colors.orange.shade500;
    return Colors.red.shade400;
  }
}
