import 'package:edu_att/models/lesson_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonService {
  static Future<LessonModel?> getCurrentLesson(String groupId) async {
    final supClient = Supabase.instance.client;
    final now = DateTime.now();

    // Форматируем дату YYYY-MM-DD
    final today =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // Форматируем текущее время HH:mm:ss
    final currentTime =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00";

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
            .eq('schedule.group_id', groupId)
            .eq('schedule.date', today)
            .lte('schedule.start_time', currentTime)
            .gt('schedule.end_time', currentTime)
            .maybeSingle();

    print("получаю данные о текущем уроке");
    print(today);
    print(currentTime);
    print(response);
    if (response == null) return null;

    return LessonModel.fromJson(response);
  }
}
