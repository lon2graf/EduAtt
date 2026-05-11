import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/utils/app_logger.dart';

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
      AppLogger.info('Получение текущего урока для группы', 'LessonService');
      AppLogger.debug('Дата: $today, Время: $currentTime', 'LessonService');
      AppLogger.debug('Ответ БД: ${response != null ? "урок найден" : "урок не найден"}', 'LessonService');

      // Если урок не найден — возвращаем null
      if (response == null) return null;

      // Преобразуем JSON в модель LessonModel
      return LessonModel.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.error('Критическая ошибка в getCurrentLesson', e, stackTrace, 'LessonService');
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

    try {
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
              .eq('schedule.teacher_id', teacherId)
              .eq('schedule.date', today)
              .lte('schedule.start_time', currentTime)
              .gt('schedule.end_time', currentTime)
              .maybeSingle();

      AppLogger.info('Получение текущего урока для преподавателя', 'LessonService');
      AppLogger.debug('ID преподавателя: $teacherId', 'LessonService');
      AppLogger.debug('Дата: $today, Время: $currentTime', 'LessonService');
      AppLogger.debug('Ответ БД: ${response != null ? "урок найден" : "урок не найден"}', 'LessonService');

      if (response == null) return null;
      return LessonModel.fromJson(response);
    } catch (e, stackTrace) {
      AppLogger.error('Критическая ошибка в getCurrentLessonForTeacher', e, stackTrace, 'LessonService');
      return null;
    }
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
      AppLogger.warning('Ошибка при проверке статуса урока, возвращаем Free', 'LessonService');
      AppLogger.error('getFreshStatus', e, null, 'LessonService');
      // В случае ошибки (например, нет интернета) возвращаем Free,
      // либо можно обработать иначе, но Free позволит не блокировать приложение намертво
      return LessonAttendanceStatus.free;
    }
  }
}
