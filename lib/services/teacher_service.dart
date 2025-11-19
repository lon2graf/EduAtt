import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:edu_att/models/teacher_model.dart';

class TeacherService {
  static Future<TeacherModel?> loginTeacher({
    required String email,
    required String password,
    required String institutionId,
  }) async {
    final supClient = Supabase.instance.client;
    try {
      final response =
          await supClient
              .from('teachers')
              .select()
              .eq('email', email)
              .eq('password', password)
              .eq('institution_id', institutionId)
              .single();
      ;

      return TeacherModel.fromJson(response);
    } catch (e) {
      print('Ошибка при входе преподавателя: $e');
      return null; // преподаватель не найден или ошибка
    }
  }
}
