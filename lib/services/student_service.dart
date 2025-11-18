import 'package:edu_att/models/student_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentServices {
  static Future<StudentModel?> loginStudent(
    String institutionId,
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
              .single();

      //if (response == null) return null; // не найден студент
      return StudentModel.fromJson(response);
    } catch (e) {
      print('Ошибка при входе студента: $e');
      return null;
    }
  }

  static Future<List<StudentModel>> GetStudentsByGroupId(String groupId) async {
    final supClient = Supabase.instance.client;

    try {
      final response = await supClient
          .from('students')
          .select('''
        id,
        name,
        surname,
        group_id,
        isHeadman
      ''') // Выбираем все нужные поля
          .eq('group_id', groupId); // Фильтруем по group_id

      print("Запрашиваю студентов из группы: $groupId");
      print(response);

      if (response == null) return [];

      return (response as List)
          .map((item) => StudentModel.fromJson(item))
          .toList();
    } catch (e) {
      print('Ошибка при получении студентов по группе: $e');
      return [];
    }
  }
}
