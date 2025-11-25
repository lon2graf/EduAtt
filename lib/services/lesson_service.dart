import 'package:edu_att/models/lesson_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonService {
  // Метод для получения текущего урока для группы
  static Future<LessonModel?> getCurrentLesson(String groupId) async {
    final supClient = Supabase.instance.client; // Получаем клиент Supabase
    final now = DateTime.now(); // Текущее время

    // Форматируем дату в формат YYYY-MM-DD
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Форматируем текущее время в формат HH:mm:ss
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

    // Выполняем запрос к Supabase:
    // выбираем уроки, у которых дата совпадает с сегодняшней,
    // время начала <= текущее время и время конца > текущее время,
    // то есть урок, который идет прямо сейчас
    final response =
        await supClient
            .from('lessons')
            .select('''
      id,
      topic,
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
    ''')
            .eq('schedule.group_id', groupId) // Фильтр по группе
            .eq('schedule.date', today) // Фильтр по дате
            .lte('schedule.start_time', currentTime) // Урок уже начался
            .gt('schedule.end_time', currentTime) // Но еще не закончился
            .maybeSingle(); // Получаем одну запись или null

    // Отладочные выводы
    print("получаю данные о текущем уроке");
    print(today);
    print(currentTime);
    print(response);

    // Если урок не найден — возвращаем null
    if (response == null) return null;

    // Преобразуем JSON в модель LessonModel
    return LessonModel.fromJson(response);
  }

  // Метод для получения текущего урока для учителя
  static Future<LessonModel?> getCurrentLessonForTeacher(
    String teacherId,
  ) async {
    final supClient = Supabase.instance.client; // Клиент Supabase
    final now = DateTime.now(); // Текущее время

    // Форматируем дату YYYY-MM-DD
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Форматируем текущее время HH:mm:ss
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

    // Запрос аналогичен предыдущему, но фильтрация идет по teacher_id
    final response =
        await supClient
            .from('lessons')
            .select('''
        id,
        topic,
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
}
