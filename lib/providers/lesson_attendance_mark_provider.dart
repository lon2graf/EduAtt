import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/services/lesson_service.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';

/// StateNotifier для отметки посещаемости студентов
class LessonAttendanceMarkNotifier
    extends StateNotifier<List<LessonAttendanceModel>> {
  LessonAttendanceMarkNotifier() : super([]);

  /// Инициализация массива для текущего урока и студентов группы
  void initialize(List<LessonAttendanceModel> attendances) {
    state = attendances;
  }

  void initializeAttendance(
    List<StudentModel> groupStudents,
    LessonModel? currentLesson,
  ) {
    state =
        groupStudents.map((student) {
          return LessonAttendanceModel(
            lessonId: currentLesson?.id ?? 0,
            studentId: student.id!,
            studentName: student.name, // для отображения на экране
            status: null, // пока не отмечен
          );
        }).toList();
  }

  /// Установка статуса посещаемости для конкретного студента
  void setAttendanceStatus(String studentId, String status) {
    for (final item in state) {
      if (item.studentId == studentId) {
        item.status = status; // просто меняем поле
        break;
      }
    }
    state = [...state]; // чтобы Riverpod заметил изменения
  }

  /// Получение студента по индексу
  LessonAttendanceModel? getStudentAt(int index) {
    if (index < 0 || index >= state.length) return null;
    return state[index];
  }

  /// Сохранение данных на сервер (заглушка, можно реализовать вызов API)
  Future<void> saveAttendance() async {
    try {
      await LessonsAttendanceService.saveAttendances(state);
      // Можно очистить или показать уведомление
      state = []; // или оставить, если нужен повторный просмотр
    } catch (e) {
      print('Ошибка при сохранении посещаемости: $e');
    }
  }
}

/// Провайдер для использования в приложении
final lessonAttendanceMarkProvider = StateNotifierProvider<
  LessonAttendanceMarkNotifier,
  List<LessonAttendanceModel>
>((ref) => LessonAttendanceMarkNotifier());
