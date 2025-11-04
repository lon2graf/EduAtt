import 'package:edu_att/models/student_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentServices {
  static Future<StudentModel?> loginStudent(
    int institutionId,
    String email,
    String password,
  ) async {
    final supClient = Supabase.instance.client;

    try {
      final response =
          await supClient
              .from('students')
              .select()
              .eq('email', email)
              .eq('password', password)
              .eq('institution_id', institutionId)
              .limit(1)
              .maybeSingle();

      if (response == null) return null; // не найден студент
      return StudentModel.fromJson(response);
    } catch (e) {
      print('Ошибка при входе студента: $e');
      return null;
    }
  }
}
