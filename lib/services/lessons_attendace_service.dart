import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LessonsAttendanceService {
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
}
