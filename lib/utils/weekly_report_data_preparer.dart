import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/attendance_report_data_model.dart';
import 'package:edu_att/models/student_model.dart';

class WeeklyReportDataPreparer {
  WeeklyReportDataPreparer._();

  static AttendanceReportData prepareReportData({
    required String groupName,
    required DateTime monday,
    required DateTime sunday,
    required List<StudentModel> allGroupStudents,
    required List<LessonAttendanceModel> rawRecords,
  }) {
    final startDateStr = '${monday.day}.${monday.month}.${monday.year}';
    final endDateStr = '${sunday.day}.${sunday.month}.${sunday.year}';

    // === ШАГ 1: Собираем все уникальные занятия за неделю ===
    // Используем Set, чтобы избежать дубликатов lessonId
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
      // Сравниваем время как строки (формат HH:mm)
      return (a.lessonStart ?? '').compareTo(b.lessonStart ?? '');
    });

    // === ШАГ 2: Формируем заголовки ===
    final List<String> dayHeaders = []; // ['Пн', 'Пн', 'Пн', 'Вт', ...]
    final List<String> subjectHeaders = []; // ['Матем.', 'Информ.', ...]

    for (final lesson in lessonsList) {
      if (lesson.lessonDate == null) continue;
      final weekday = lesson.lessonDate!.weekday; // Пн=1, ..., Сб=6
      if (weekday < 1 || weekday > 6) continue; // Игнорируем Вс

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

    // Карта: studentId -> {lessonId -> status}
    final studentToLessonStatus = <String, Map<int, String>>{};
    for (final record in rawRecords) {
      studentToLessonStatus.putIfAbsent(record.studentId, () => {});
      String status;
      switch ((record.status ?? '').toLowerCase()) {
        case 'присутствует':
          status = '+';
          break;
        case 'отсутствует':
          status = '–';
          break;
        case 'опоздал':
          status = 'ОП';
          break;
        default:
          status = '';
      }
      studentToLessonStatus[record.studentId]![record.lessonId] = status;
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
      dayHeaders: dayHeaders, // ← новые поля
      subjectHeaders: subjectHeaders,
    );
  }

  static String _abbreviateSubject(String subject) {
    if (subject.isEmpty) return '';
    // Простая аббревиатура: первые 5-7 символов + точка, если длинно
    if (subject.length <= 7) return subject;
    return '${subject.substring(0, 6)}.';
  }
}
