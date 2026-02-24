import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/models/attendance_status.dart';
import 'dart:async';

class LessonAttendanceMarkNotifier
    extends StateNotifier<List<LessonAttendanceModel>> {
  LessonAttendanceMarkNotifier() : super([]);

  StreamSubscription? _streamSubscription;

  Future<void> initializeAttendance(
    List<StudentModel> groupStudents,
    LessonModel? currentLesson,
  ) async {
    if (currentLesson == null || currentLesson.id == null) return;
    final lessonId = currentLesson.id!;

    try {
      // 1. Пытаемся загрузить начальные данные (Future)
      final existingMarks =
          await LessonsAttendanceService.getAttendancesForLesson(lessonId);

      final marksMap = {for (var mark in existingMarks) mark.studentId: mark};

      state =
          groupStudents.map((student) {
            final existingMark = marksMap[student.id];
            return LessonAttendanceModel(
              id: existingMark?.id,
              lessonId: lessonId,
              studentId: student.id!,
              studentName: '${student.surname} ${student.name}',
              status: existingMark?.status,
            );
          }).toList();

      // 2. Если загрузка удалась, запускаем Realtime (Stream)
      _startAttendanceStream(lessonId);
    } catch (e) {
      // ОБРАБОТКА ОШИБКИ ПРИ ЗАГРУЗКЕ
      print('❌ Ошибка инициализации ведомости: $e');
      // Тут можно либо оставить список пустым, либо пометить какую-то переменную ошибки
    }
  }

  void _startAttendanceStream(String lessonId) {
    _streamSubscription?.cancel();

    _streamSubscription = LessonsAttendanceService.getAttendanceStream(
      lessonId,
    ).listen(
      (List<Map<String, dynamic>> data) {
        if (data.isEmpty) return;

        // Обновляем стейт при получении данных
        for (var row in data) {
          final studentIdFromDb = row['student_id'].toString();
          final newStatus = AttendanceStatus.fromString(
            row['status'] as String?,
          );

          state = [
            for (final item in state)
              if (item.studentId == studentIdFromDb)
                item.copyWith(status: newStatus, id: row['id'].toString())
              else
                item,
          ];
        }
      },
      // ОБРАБОТКА ОШИБКИ В ПОТОКЕ
      onError: (error) {
        print('❌ Ошибка в Realtime-потоке посещаемости: $error');
        // Например, можно попробовать перезапустить стрим через пару секунд
      },
    );
  }

  void setAttendanceStatus(String studentId, AttendanceStatus status) {
    state = [
      for (final item in state)
        if (item.studentId == studentId)
          item.copyWith(status: status)
        else
          item,
    ];
  }

  Future<void> saveAttendance() async {
    try {
      // Отправляем текущее состояние (state) в сервис для Upsert-запроса
      await LessonsAttendanceService.saveAttendances(state);
      print('✅ Посещаемость успешно синхронизирована с БД');
    } catch (e) {
      print('❌ Ошибка при сохранении посещаемости: $e');
      rethrow; // Перебрасываем ошибку, чтобы UI (EduSnackBar) её поймал
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

final lessonAttendanceMarkProvider = StateNotifierProvider<
  LessonAttendanceMarkNotifier,
  List<LessonAttendanceModel>
>((ref) => LessonAttendanceMarkNotifier());
