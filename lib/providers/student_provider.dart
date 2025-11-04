import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/services/student_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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
        return true;
      }
      return false;
    } catch (e) {
      print('ошибка при логине студента: $e');
      return false;
    }
  }

  void logout() {
    state = null;
  }

  bool get isLoggined => state != null;
}
