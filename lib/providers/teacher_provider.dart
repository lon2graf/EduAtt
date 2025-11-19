import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/models/teacher_model.dart';
import 'package:edu_att/services/teacher_service.dart';
import 'package:flutter_riverpod/legacy.dart';

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

    state = teacher; // если null — значит авторизация провалилась
  }

  void logout() {
    state = null;
  }
}

final teacherProvider = StateNotifierProvider<TeacherNotifier, TeacherModel?>(
  (ref) => TeacherNotifier(),
);
