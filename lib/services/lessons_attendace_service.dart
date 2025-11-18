import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonsAttendanceService {
  static Future<void> saveAttendances(
    List<LessonAttendanceModel> attendances,
  ) async {
    final supClient = Supabase.instance.client;
    final data = attendances.map((e) => e.toJson()).toList();

    try {
      await supClient.from('lesson_attendances').upsert(data);
    } catch (e) {
      throw Exception('Не удалось сохранить посещаемость: $e');
    }
  }

  static Future<List<LessonAttendanceModel>> GetAllStudentAttendaces(
    String id,
  ) async {
    final supClient = Supabase.instance.client;

    try {
      final response = await supClient
          .from('lesson_attendances')
          .select('''
    id,
    lesson_id,
    student_id,
    status,
    lessons (
      schedule (
        date,
        start_time,
        end_time,
        subjects (
          id,
          name
        ),
        teachers (
          id,
          name,
          surname
        )
      )
    )
  ''')
          .eq('student_id', id);
      print("ищу пропуски");
      print(response);

      if (response == null) return [];

      return (response as List)
          .map((item) => LessonAttendanceModel.fromNestedJson(item))
          .toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  static List<LessonAttendanceModel> filterAttendancesByDate(
    List<LessonAttendanceModel> allAttendances,
    DateTime date,
  ) {
    return allAttendances.where((attendance) {
      return attendance.lessonDate != null &&
          attendance.lessonDate!.year == date.year &&
          attendance.lessonDate!.month == date.month &&
          attendance.lessonDate!.day == date.day;
    }).toList();
  }

  static double calculateAttendancePercentageForMonth(
    List<LessonAttendanceModel> allAttendances,
    DateTime monthDate,
  ) {
    // Фильтруем занятия, которые были в указанном месяце
    final List<LessonAttendanceModel> monthlyAttendances =
        allAttendances
            .where(
              (attendance) =>
                  attendance.lessonDate != null &&
                  attendance.lessonDate!.year == monthDate.year &&
                  attendance.lessonDate!.month == monthDate.month,
            )
            .toList();

    if (monthlyAttendances.isEmpty) {
      return 0.0; // Если занятий не было, возвращаем 0%
    }

    // Считаем количество занятий, на которых студент присутствовал
    final int presentCount =
        monthlyAttendances
            .where(
              (attendance) => attendance.status?.toLowerCase() == 'present',
            )
            .length;

    // Общее количество занятий
    final int totalCount = monthlyAttendances.length;

    // Рассчитываем процент
    return (presentCount / totalCount) * 100.0;
  }

  static int countAbsencesForMonth(
    List<LessonAttendanceModel> allAttendances,
    DateTime monthDate,
  ) {
    return allAttendances
        .where(
          (attendance) =>
              attendance.status?.toLowerCase() == 'absent' &&
              attendance.lessonDate != null &&
              attendance.lessonDate!.year == monthDate.year &&
              attendance.lessonDate!.month == monthDate.month,
        )
        .length;
  }
}
