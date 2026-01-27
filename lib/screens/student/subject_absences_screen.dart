import 'package:edu_att/models/attendance_status.dart'; // 1. Импорт Enum
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';

class SubjectAbsencesScreen extends ConsumerWidget {
  final String subjectName;

  const SubjectAbsencesScreen({super.key, required this.subjectName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAttendances = ref.watch(attendanceProvider);

    // 2. Исправленная фильтрация с использованием Enum
    final subjectAbsences =
        allAttendances
            .where(
              (attendance) =>
                  attendance.subjectName == subjectName &&
                  // Больше никаких строк! Сравниваем напрямую с Enum.
                  attendance.status == AttendanceStatus.absent,
            )
            .toList();

    // Сортируем по дате (от новых к старым)
    subjectAbsences.sort(
      (a, b) => (b.lessonDate ?? DateTime(2000)).compareTo(
        a.lessonDate ?? DateTime(2000),
      ),
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.06)),
          child: SafeArea(
            child: Column(
              children: [
                // AppBar
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              subjectName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), // Для симметрии
                      ],
                    ),
                  ),
                ),

                // Статистика
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Всего пропусков',
                          '${subjectAbsences.length}',
                        ),
                        _buildStatItem(
                          'За месяц',
                          '${_getThisMonthAbsences(subjectAbsences)}',
                        ),
                      ],
                    ),
                  ),
                ),

                // Список пропусков
                Expanded(
                  child:
                      subjectAbsences.isEmpty
                          ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.celebration_outlined,
                                  size: 56,
                                  color: Colors.white60,
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'Пропусков по этому предмету нет!',
                                  style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            itemCount: subjectAbsences.length,
                            separatorBuilder:
                                (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final absence = subjectAbsences[index];
                              return _buildAbsenceCard(absence);
                            },
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white60, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAbsenceCard(LessonAttendanceModel absence) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDate(absence.lessonDate),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Время: ${absence.lessonStart ?? '??'} - ${absence.lessonEnd ?? '??'}',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          if (absence.teacherName != null || absence.teacherSurname != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Преподаватель: ${absence.teacherName ?? ''} ${absence.teacherSurname ?? ''}',
                style: const TextStyle(color: Colors.white60, fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Дата не указана';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final absenceDay = DateTime(date.year, date.month, date.day);

    if (absenceDay == today) {
      return 'Сегодня';
    } else if (absenceDay == today.subtract(const Duration(days: 1))) {
      return 'Вчера';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  int _getThisMonthAbsences(List<LessonAttendanceModel> absences) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);

    return absences.where((absence) {
      final absenceDate = absence.lessonDate;
      return absenceDate != null &&
          absenceDate.isAfter(currentMonth.subtract(const Duration(days: 1))) &&
          absenceDate.isBefore(nextMonth);
    }).length;
  }
}
