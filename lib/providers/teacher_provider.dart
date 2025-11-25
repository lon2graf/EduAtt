import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/models/teacher_model.dart';
import 'package:edu_att/services/teacher_service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:edu_att/services/shared_preferences_service.dart';

class TeacherNotifier extends StateNotifier<TeacherModel?> {
  TeacherNotifier() : super(null);

  Future<void> loginTeacher({
    required String email,
    required String password,
    required String institutionId,
  }) async {
    final teacher = await TeacherService.loginTeacher(
      email: email,
      password: password,
      institutionId: institutionId,
    );

    if (teacher != null) {
      state = teacher;
      // Просто сохраняем данные при успешном логине
      await SharedPreferencesService.saveTeacherCredentials(
        login: email,
        password: password,
        institutionId: institutionId,
      );
    } // если null — значит авторизация провалилась
  }

  void logout() async {
    state = null;
    await SharedPreferencesService.clearAllData();
  }
}

final teacherProvider = StateNotifierProvider<TeacherNotifier, TeacherModel?>(
  (ref) => TeacherNotifier(),
);
