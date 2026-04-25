import 'package:edu_att/models/teacher_model.dart';
import 'package:edu_att/data/remote/base_service.dart';

class TeacherService extends BaseService {
  static Future<TeacherModel?> loginTeacher({
    required String email,
    required String password,
    required String institutionId,
  }) async {
    return BaseService.executeSafely<TeacherModel>(
      operation: () async {
        final response = await BaseService.client
            .from('teachers')
            .select()
            .eq('email', email)
            .eq('password', password)
            .eq('institution_id', institutionId)
            .single();

        return TeacherModel.fromJson(response);
      },
      errorContext: 'loginTeacher',
    );
  }
}
