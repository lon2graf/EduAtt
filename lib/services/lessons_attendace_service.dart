import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonsAttendanceService {
  // Метод для сохранения списка посещаемости в базу данных
  static Future<void> saveAttendances(
    List<LessonAttendanceModel> attendances,
  ) async {
    final supClient = Supabase.instance.client; // Клиент Supabase
    final data =
        attendances
            .map((e) => e.toJson())
            .toList(); // Конвертация моделей в JSON

    try {
      // upsert — вставляет или обновляет записи по первичному ключу
      await supClient.from('lesson_attendances').upsert(data);
    } catch (e) {
      // В случае ошибки выбрасываем исключение
      throw Exception('Не удалось сохранить посещаемость: $e');
    }
  }

  // Метод получения всех посещений студента по его ID
  static Future<List<LessonAttendanceModel>> GetAllStudentAttendaces(
    String id,
  ) async {
    final supClient = Supabase.instance.client;

    try {
      // Выполняем SELECT с вложенными таблицами lessons -> schedule -> subjects/teachers
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
          .eq('student_id', id); // Фильтрация по студенту

      print("ищу пропуски");
      print(response);

      // Если ответ пустой — возвращаем пустой список
      if (response == null) return [];

      // Преобразуем JSON в список моделей LessonAttendanceModel
      return (response as List)
          .map((item) => LessonAttendanceModel.fromNestedJson(item))
          .toList();
    } catch (e) {
      // Ловим ошибку и выводим в консоль
      print(e);
      return [];
    }
  }

  // Фильтрация посещаемости по конкретной дате
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

  // Метод для расчета процента посещаемости за месяц
  static double calculateAttendancePercentageForMonth(
    List<LessonAttendanceModel> allAttendances,
    DateTime monthDate,
  ) {
    // Фильтруем занятия, относящиеся к указанному месяцу
    final List<LessonAttendanceModel> monthlyAttendances =
        allAttendances
            .where(
              (attendance) =>
                  attendance.lessonDate != null &&
                  attendance.lessonDate!.year == monthDate.year &&
                  attendance.lessonDate!.month == monthDate.month,
            )
            .toList();

    // Если не было занятий — процент посещаемости равен 0
    if (monthlyAttendances.isEmpty) {
      return 0.0;
    }

    // Подсчитываем, сколько занятий студент посетил
    final int presentCount =
        monthlyAttendances
            .where(
              (attendance) => attendance.status?.toLowerCase() == 'present',
            )
            .length;

    // Общее количество занятий за месяц
    final int totalCount = monthlyAttendances.length;

    // Возвращаем процент посещаемости
    return (presentCount / totalCount) * 100.0;
  }

  // Подсчет пропусков студента за указанный месяц
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
