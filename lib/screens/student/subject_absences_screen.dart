import 'package:edu_att/models/attendance_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';

class SubjectAbsencesScreen extends ConsumerWidget {
  final String subjectName;

  const SubjectAbsencesScreen({super.key, required this.subjectName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final allAttendances = ref.watch(attendanceProvider);

    // Фильтрация
    final subjectAbsences =
        allAttendances
            .where(
              (attendance) =>
                  attendance.subjectName == subjectName &&
                  attendance.status == AttendanceStatus.absent,
            )
            .toList();

    // Сортировка
    subjectAbsences.sort(
      (a, b) => (b.lessonDate ?? DateTime(2000)).compareTo(
        a.lessonDate ?? DateTime(2000),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(subjectName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Блок статистики
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildStatsCard(context, subjectAbsences),
          ),

          // Список пропусков
          Expanded(
            child:
                subjectAbsences.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: subjectAbsences.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildAbsenceCard(
                          context,
                          subjectAbsences[index],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    List<LessonAttendanceModel> absences,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, 'Всего', '${absences.length}'),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.primary.withOpacity(0.2),
          ),
          _buildStatItem(
            context,
            'За месяц',
            '${_getThisMonthAbsences(absences)}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
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
            color: colorScheme.primary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.celebration_outlined,
            size: 64,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Пропусков по этому предмету нет!',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
        border: Border.all(color: Colors.red.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.05),
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
                  color: Colors.red.withOpacity(0.1),
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
              Icon(
                Icons.access_time,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
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
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
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
    final absenceDay = DateTime(date.year, date.month, date.day);

    if (absenceDay == today) return 'Сегодня';
    if (absenceDay == today.subtract(const Duration(days: 1))) return 'Вчера';
    return '${date.day}.${date.month}.${date.year}';
  }

  int _getThisMonthAbsences(List<LessonAttendanceModel> absences) {
    final now = DateTime.now();
    return absences.where((absence) {
      final date = absence.lessonDate;
      return date != null && date.year == now.year && date.month == now.month;
    }).length;
  }
}
