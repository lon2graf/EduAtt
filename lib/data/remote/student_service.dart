import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/utils/app_logger.dart';

class StudentServices extends BaseService {
  static Future<StudentModel?> loginStudent(
    String institutionId,
    String email,
    String password,
  ) async {
    return BaseService.executeSafely<StudentModel>(
      operation: () async {
        final response = await BaseService.client
            .from('students')
            .select('''
      id,
      name,
      surname,
      email,
      login,
      group_id,
      isheadman,
      groups!inner (name, institution_id)
    ''')
            .eq('email', email)
            .eq('password', password)
            .eq('groups.institution_id', institutionId)
            .single();

        return StudentModel.fromJson(response);
      },
      errorContext: 'loginStudent',
    );
  }

  static Future<List<StudentModel>> getStudentsByGroupId(String groupId) async {
    final result = await BaseService.executeSafely<List<StudentModel>>(
      operation: () async {
        final response = await BaseService.client
            .from('students')
            .select('''
        id,
        name,
        surname,
        group_id,
        isheadman
      ''')
            .eq('group_id', groupId);

        AppLogger.debug('Запрос студентов группы: $groupId', 'StudentService');
        AppLogger.debug('Ответ БД: ${response.length} студентов', 'StudentService');

        return (response as List)
            .map((item) => StudentModel.fromJson(item))
            .toList();
      },
      errorContext: 'getStudentsByGroupId',
    );

    return result ?? [];
  }
}
