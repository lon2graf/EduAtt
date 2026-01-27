import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/attendance_report_data_model.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/models/attendance_status.dart'; // 1. Импорт Enum

class WeeklyReportDataPreparer {
  WeeklyReportDataPreparer._();

  static AttendanceReportData prepareReportData({
    required String groupName,
    required DateTime monday,
    required DateTime sunday,
    required List<StudentModel> allGroupStudents,
    required List<LessonAttendanceModel> rawRecords,
  }) {
    // 2. Исправлено форматирование дат (добавлены нули: 01.09 вместо 1.9)
    final startDateStr =
        '${monday.day.toString().padLeft(2, '0')}.${monday.month.toString().padLeft(2, '0')}.${monday.year}';
    final endDateStr =
        '${sunday.day.toString().padLeft(2, '0')}.${sunday.month.toString().padLeft(2, '0')}.${sunday.year}';

    // === ШАГ 1: Собираем все уникальные занятия за неделю ===
    final Set<int> uniqueLessonIds = {};
    final List<LessonAttendanceModel> lessonsList = [];

    for (final record in rawRecords) {
      if (record.lessonId == 0 || record.lessonDate == null) continue;
      if (uniqueLessonIds.contains(record.lessonId)) continue;

      uniqueLessonIds.add(record.lessonId);
      lessonsList.add(record);
    }

    // Сортируем занятия по дате и времени
    lessonsList.sort((a, b) {
      final dateCompare = (a.lessonDate ?? DateTime(2000)).compareTo(
        b.lessonDate ?? DateTime(2000),
      );
      if (dateCompare != 0) return dateCompare;
      return (a.lessonStart ?? '').compareTo(b.lessonStart ?? '');
    });

    // === ШАГ 2: Формируем заголовки ===
    final List<String> dayHeaders = [];
    final List<String> subjectHeaders = [];

    for (final lesson in lessonsList) {
      if (lesson.lessonDate == null) continue;
      final weekday = lesson.lessonDate!.weekday;
      if (weekday < 1 || weekday > 6) continue;

      final dayLabel = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб'][weekday - 1];
      dayHeaders.add(dayLabel);

      final subject = _abbreviateSubject(lesson.subjectName ?? '');
      subjectHeaders.add(subject);
    }

    // === ШАГ 3: Подготавливаем данные по студентам ===
    final studentIdToName = <String, String>{
      for (final s in allGroupStudents)
        if (s.id != null) s.id!: '${s.surname} ${s.name}',
    };

    // Карта: studentId -> {lessonId -> statusSymbol}
    final studentToLessonStatus = <String, Map<int, String>>{};

    for (final record in rawRecords) {
      studentToLessonStatus.putIfAbsent(record.studentId, () => {});

      String symbol;

      // 3. Используем Enum для выбора символа в ведомости
      // record.status теперь имеет тип AttendanceStatus?
      switch (record.status) {
        case AttendanceStatus.present:
          symbol = '+';
          break;
        case AttendanceStatus.absent:
          symbol = '–'; // Тире
          break;
        case AttendanceStatus.late:
          symbol = 'ОП';
          break;
        default:
          symbol = ''; // Пусто, если статус не указан
      }

      studentToLessonStatus[record.studentId]![record.lessonId] = symbol;
    }

    // === ШАГ 4: Формируем таблицу ===
    final sortedStudents =
        studentIdToName.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    final studentNames = <String>[];
    final attendance = <List<String>>[];

    for (final entry in sortedStudents) {
      final studentId = entry.key;
      final name = entry.value;
      studentNames.add(name);

      final statusMap = studentToLessonStatus[studentId] ?? {};
      final statuses = <String>[];
      for (final lesson in lessonsList) {
        statuses.add(statusMap[lesson.lessonId] ?? '');
      }
      attendance.add(statuses);
    }

    return AttendanceReportData(
      groupName: groupName,
      startDateStr: startDateStr,
      endDateStr: endDateStr,
      studentNames: studentNames,
      attendance: attendance,
      dayHeaders: dayHeaders,
      subjectHeaders: subjectHeaders,
    );
  }

  static String _abbreviateSubject(String subject) {
    if (subject.isEmpty) return '';
    if (subject.length <= 7) return subject;
    return '${subject.substring(0, 6)}.';
  }
}
