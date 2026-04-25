import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/data/remote/student_service.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:edu_att/data/remote/shared_preferences_service.dart';

final currentStudentProvider =
    StateNotifierProvider<StudentNotifier, StudentModel?>(
      (ref) => StudentNotifier(),
    );

class StudentNotifier extends StateNotifier<StudentModel?> {
  StudentNotifier() : super(null);

  Future<bool> login(
    String institutionId,
    String email,
    String password,
  ) async {
    try {
      final student = await StudentServices.loginStudent(
        institutionId,
        email,
        password,
      );
      if (student != null) {
        state = student;
        await SharedPreferencesService.saveStudentCredentials(
          login: email,
          password: password,
          institutionId: institutionId,
        );
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Ошибка при логине студента', e, null, 'StudentNotifier');
      return false;
    }
  }

  void logout() async {
    state = null;
    await SharedPreferencesService.clearAllData();
  }

  bool get isLoggined => state != null;
}
