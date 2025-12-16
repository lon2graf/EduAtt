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
              (attendance) => attendance.status?.toLowerCase() == 'присутсвует',
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
              attendance.status?.toLowerCase() == 'отсутствует' &&
              attendance.lessonDate != null &&
              attendance.lessonDate!.year == monthDate.year &&
              attendance.lessonDate!.month == monthDate.month,
        )
        .length;
  }

  // Проверяет, есть ли записи посещаемости для конкретного урока
  static Future<bool> isLessonMarked(int lessonId) async {
    final supClient = Supabase.instance.client;
    try {
      final response = await supClient
          .from('lesson_attendances')
          .select('id') // Нам нужен только факт существования ID
          .eq('lesson_id', lessonId)
          .limit(1); // Достаточно найти хотя бы одну запись

      // Если список не пуст, значит урок уже отмечен
      return (response as List).isNotEmpty;
    } catch (e) {
      print('Ошибка при проверке статуса урока: $e');
      return false;
    }
  }

  static Future<List<LessonAttendanceModel>> getWeeklyGroupAttendance({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final supClient = Supabase.instance.client;
    final startStr = _formatDate(startDate);
    final endStr = _formatDate(endDate);
    try {
      final response = await supClient
          .from('lesson_attendances')
          .select('''
          id,
        lesson_id,
        student_id,
        status,
        students (name, surname),
        lessons (
          schedule (
            date,
            start_time,
            end_time,
            group_id,
            subject_id,
            teacher_id,
            subjects (name),
            teachers (name, surname)
            )
            )
            
    ''')
          .eq('lessons.schedule.group_id', groupId)
          .gte('lessons.schedule.date', startStr)
          .lte('lessons.schedule.date', endStr);

      final List<LessonAttendanceModel> attendances =
          (response as List)
              .map((json) => LessonAttendanceModel.fromNestedJson(json))
              .toList();

      attendances.sort((a, b) {
        return (a.lessonDate ?? DateTime(2000)).compareTo(
          b.lessonDate ?? DateTime(2000),
        );
      });

      return attendances;
    } catch (e) {
      print('❗ Ошибка в getWeeklyGroupAttendance: $e');
      return [];
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
