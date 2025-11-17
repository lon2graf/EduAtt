import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/services/student_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class AttendanceNotifier extends StateNotifier<List<LessonAttendanceModel>> {
  AttendanceNotifier() : super([]);

  /// Загружает все посещения студента
  Future<void> loadStudentAttendances(String studentId) async {
    final attendances = await LessonsAttendanceService.GetAllStudentAttendaces(
      studentId,
    );
    state = attendances;
  }

  void clear() {
    state = [];
  }

  /// Получить только пропуски по определённому предмету
  List<LessonAttendanceModel> bySubject(String subjectName) {
    return state.where((e) => e.subjectName == subjectName).toList();
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<LessonAttendanceModel>>(
      (ref) => AttendanceNotifier(),
    );
