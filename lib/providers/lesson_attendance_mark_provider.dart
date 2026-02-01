import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/models/attendance_status.dart';

/// StateNotifier для отметки посещаемости студентов
class LessonAttendanceMarkNotifier
    extends StateNotifier<List<LessonAttendanceModel>> {
  LessonAttendanceMarkNotifier() : super([]);

  /// Инициализация массива для текущего урока и студентов группы
  void initializeAttendance(
    List<StudentModel> groupStudents,
    LessonModel? currentLesson,
  ) async {
    if (currentLesson == null || currentLesson.id == null) {
      state = []; // Очищаем список или оставляем пустым
      return;
    }

    final lesson = currentLesson;
    final String lessonId = currentLesson.id!; // Изменено int → String

    try {
      List<LessonAttendanceModel> existingMarks = [];

      // Теперь обращаемся к lesson (он точно существует)
      final bool shouldLoadFromDb =
          lesson.status == LessonAttendanceStatus.waitConfirmation ||
          lesson.status == LessonAttendanceStatus.onTeacherEditing ||
          lesson.status == LessonAttendanceStatus.confirmed;

      if (shouldLoadFromDb) {
        existingMarks = await LessonsAttendanceService.getAttendancesForLesson(
          lessonId, // Теперь передаем String
        );
      }

      final marksMap = {for (var mark in existingMarks) mark.studentId: mark};

      state =
          groupStudents.map((student) {
            final existingMark = marksMap[student.id];

            if (existingMark != null) {
              return LessonAttendanceModel(
                id: existingMark.id,
                lessonId: lessonId, // Используем безопасный ID (теперь String)
                studentId: student.id!,
                studentName: student.name,
                status: existingMark.status,
              );
            } else {
              return LessonAttendanceModel(
                lessonId: lessonId, // Используем безопасный ID (теперь String)
                studentId: student.id!,
                studentName: student.name,
                status: null,
              );
            }
          }).toList();
    } catch (e) {
      print('Ошибка инициализации ведомости: $e');
      state =
          groupStudents.map((student) {
            return LessonAttendanceModel(
              lessonId: lessonId,
              studentId: student.id!,
              studentName: student.name,
              status: null,
            );
          }).toList();
    }
  }

  /// Установка статуса посещаемости для конкретного студента
  void setAttendanceStatus(String studentId, AttendanceStatus status) {
    // Создаем копию состояния для неизменяемости
    final newState =
        state.map((item) {
          if (item.studentId == studentId) {
            // Создаем новый объект с обновленным статусом
            return LessonAttendanceModel(
              id: item.id,
              lessonId: item.lessonId,
              studentId: item.studentId,
              studentName: item.studentName,
              status: status,
              lessonDate: item.lessonDate,
              lessonStart: item.lessonStart,
              lessonEnd: item.lessonEnd,
              subjectName: item.subjectName,
              teacherName: item.teacherName,
              teacherSurname: item.teacherSurname,
              groupId: item.groupId,
            );
          }
          return item;
        }).toList();

    state = newState;
  }

  /// Сохранение данных на сервер (заглушка, можно реализовать вызов API)
  Future<void> saveAttendance() async {
    try {
      await LessonsAttendanceService.saveAttendances(state);
      state = [];
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
