import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/services/lesson_service.dart';
import 'package:flutter_riverpod/legacy.dart';

class CurrentLessonNotifier extends StateNotifier<LessonModel?> {
  CurrentLessonNotifier() : super(null);

  // Метод для загрузки текущего урока по groupId
  Future<void> loadCurrentLesson(String groupId) async {
    final lesson = await LessonService.getCurrentLesson(groupId);
    state = lesson;
  }

  Future<void> loadCurrentLessonForTeacher(String teacherId) async {
    final lesson = await LessonService.getCurrentLessonForTeacher(teacherId);
    state = lesson;
  }

  void updateStatus(LessonAttendanceStatus newStatus) {
    if (state == null) return;

    state = state!.copyWith(status: newStatus);
  }
}

// Провайдер для использования в UI
final currentLessonProvider =
    StateNotifierProvider<CurrentLessonNotifier, LessonModel?>(
      (ref) => CurrentLessonNotifier(),
    );
