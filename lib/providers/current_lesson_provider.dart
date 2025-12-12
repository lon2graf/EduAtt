import 'package:flutter_riverpod/flutter_riverpod.dart';
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
}

// Провайдер для использования в UI
final currentLessonProvider =
    StateNotifierProvider<CurrentLessonNotifier, LessonModel?>(
      (ref) => CurrentLessonNotifier(),
    );
