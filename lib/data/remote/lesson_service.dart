import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/data/remote/base_service.dart';

class LessonService extends BaseService {
  // Метод для получения текущего урока для группы
  static Future<LessonModel?> getCurrentLesson(String groupId) async {
    final now = DateTime.now();

    // Форматируем дату в формат YYYY-MM-DD
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Форматируем текущее время в формат HH:mm:ss
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

    try {
      // Выполняем запрос к Supabase
      final response =
          await BaseService.client
              .from('lessons')
              .select('''
  id,
  topic,
  attendance_status,
  schedule!inner (
    date,
    start_time,
    end_time,
    group_id,
    subjects!inner (
                name
              ),
              teachers!inner (
                name,
                surname
              )
  )
''') // Добавил 'status', он нужен для логики кнопок
              .eq('schedule.group_id', groupId)
              .eq('schedule.date', today)
              .lte('schedule.start_time', currentTime)
              .gt('schedule.end_time', currentTime)
              .maybeSingle();

      // Отладочные выводы
      print("!!!!!!!!!!!!!!!!!!!получаю данные о текущем уроке!!!!!!!!!!!");
      print("Дата: $today");
      print("Время: $currentTime");
      print("Ответ БД: $response");

      // Если урок не найден — возвращаем null
      if (response == null) return null;

      // Преобразуем JSON в модель LessonModel
      return LessonModel.fromJson(response);
    } catch (e, stackTrace) {
      print("🔴 КРИТИЧЕСКАЯ ОШИБКА в getCurrentLesson: $e");
      print(stackTrace); // Покажет строку кода, где упало
      return null;
    }
  }

  // Метод для получения текущего урока для учителя
  static Future<LessonModel?> getCurrentLessonForTeacher(
    String teacherId,
  ) async {
    final now = DateTime.now(); // Текущее время

    // Форматируем дату YYYY-MM-DD
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Форматируем текущее время HH:mm:ss
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

    // Запрос аналогичен предыдущему, но фильтрация идет по teacher_id
    final response =
        await BaseService.client
            .from('lessons')
            .select('''
        id,
        topic,
        attendance_status,
        schedule!inner (
          date,
          start_time,
          end_time,
          group_id,
          groups!inner(
          name),
          subjects!inner (
            name
          ),
          teachers!inner (
            name,
            surname
          )
        )
      ''')
            .eq('schedule.teacher_id', teacherId) // Фильтр по учителю
            .eq('schedule.date', today) // Текущая дата
            .lte('schedule.start_time', currentTime) // Урок уже начался
            .gt('schedule.end_time', currentTime) // Но еще идет
            .maybeSingle(); // Получаем одну запись

    // Отладочные выводы
    print(teacherId);
    print(today);
    print(currentTime);
    print(response);

    if (response == null) return null;

    // Преобразуем JSON в модель LessonModel
    return LessonModel.fromJson(response);
  }

  static Future<void> updateLessonStatus(
    String lessonId,
    LessonAttendanceStatus newStatus,
  ) async {
    return BaseService.executeOrThrow(
      operation: () async {
        await BaseService.client
            .from('lessons')
            .update({'attendance_status': newStatus.toDbValue})
            .eq('id', lessonId);
      },
      errorContext: 'updateLessonStatus',
    );
  }

  static Future<LessonAttendanceStatus> getFreshStatus(String lessonId) async {
    try {
      // Запрашиваем ТОЛЬКО поле 'attendance_status' для конкретного id
      final response = await BaseService.client
          .from('lessons')
          .select('attendance_status')
          .eq('id', lessonId)
          .single();

      // Превращаем строку из базы в наш Enum
      return LessonAttendanceStatus.fromString(
        response['attendance_status'] as String?,
      );
    } catch (e) {
      print('Ошибка при проверке статуса (getFreshStatus): $e');
      // В случае ошибки (например, нет интернета) возвращаем Free,
      // либо можно обработать иначе, но Free позволит не блокировать приложение намертво
      return LessonAttendanceStatus.free;
    }
  }
}
