import 'dart:async';

import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/repositories/attendance_repository.dart';
import 'package:edu_att/data/repositories/i_attendance_repository.dart';
import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// --- Провайдеры инфраструктуры ---

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final attendanceRepositoryProvider = Provider<IAttendanceRepository>(
  (ref) => AttendanceRepository(ref.watch(appDatabaseProvider)),
);

// --- Нотифайер ---

class LessonAttendanceMarkNotifier
    extends StateNotifier<List<LessonAttendanceModel>> {
  final IAttendanceRepository _repository;

  LessonAttendanceMarkNotifier(this._repository) : super([]);

  StreamSubscription? _streamSubscription;

  Future<void> initializeAttendance(
    List<StudentModel> groupStudents,
    LessonModel? currentLesson,
  ) async {
    if (currentLesson == null || currentLesson.id == null) return;
    final lessonId = currentLesson.id!;

    try {
      // 1. Загружаем начальные данные через репозиторий (локально или удалённо)
      final existingMarks = await _repository.getForLesson(lessonId);

      final marksMap = {for (var mark in existingMarks) mark.studentId: mark};

      state = groupStudents.map((student) {
        final existingMark = marksMap[student.id];
        return LessonAttendanceModel(
          id: existingMark?.id,
          lessonId: lessonId,
          studentId: student.id!,
          studentName: '${student.surname} ${student.name}',
          status: existingMark?.status,
        );
      }).toList();

      // 2. Запускаем Realtime-поток из Supabase
      _startAttendanceStream(lessonId);
    } catch (e) {
      AppLogger.error(
        'Ошибка инициализации ведомости',
        e,
        null,
        'LessonAttendanceMarkNotifier',
      );
    }
  }

  void _startAttendanceStream(String lessonId) {
    _streamSubscription?.cancel();

    _streamSubscription = _repository.watchLesson(lessonId).listen(
      (List<Map<String, dynamic>> data) {
        if (data.isEmpty) return;

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
      onError: (error) {
        AppLogger.error(
          'Ошибка в Realtime-потоке посещаемости',
          error,
          null,
          'LessonAttendanceMarkNotifier',
        );
      },
    );
  }

  void setAttendanceStatus(String studentId, AttendanceStatus status) {
    state = [
      for (final item in state)
        if (item.studentId == studentId) item.copyWith(status: status) else item,
    ];
  }

  Future<void> saveAttendance() async {
    try {
      // 1. Сохраняем локально с isSynced = false
      await _repository.saveLocally(state);
      // 2. Синхронизируем с Supabase
      await _repository.syncToRemote();
      AppLogger.info(
        'Посещаемость успешно синхронизирована с БД',
        'LessonAttendanceMarkNotifier',
      );
    } catch (e) {
      AppLogger.error(
        'Ошибка при сохранении посещаемости',
        e,
        null,
        'LessonAttendanceMarkNotifier',
      );
      rethrow;
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
>((ref) => LessonAttendanceMarkNotifier(ref.watch(attendanceRepositoryProvider)));
