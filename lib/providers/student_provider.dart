import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/services/student_service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:edu_att/services/shared_preferences_service.dart';

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
      print('ошибка при логине студента: $e');
      return false;
    }
  }

  void logout() async {
    state = null;
    await SharedPreferencesService.clearAllData();
  }

  bool get isLoggined => state != null;
}
