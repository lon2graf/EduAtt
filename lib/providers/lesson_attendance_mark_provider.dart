import 'dart:async';

import 'package:edu_att/data/repositories/attendance_repository.dart';
import 'package:edu_att/data/repositories/i_attendance_repository.dart';
import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/providers/personal_mode_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

// --- Провайдеры инфраструктуры ---

final attendanceRepositoryProvider = Provider<IAttendanceRepository>(
  (ref) => AttendanceRepository(ref.watch(appDatabaseProvider)),
);

// --- Нотифайер ---

class LessonAttendanceMarkNotifier
    extends StateNotifier<List<LessonAttendanceModel>> {
  final IAttendanceRepository _repository;
  final bool _isPersonalMode;

  LessonAttendanceMarkNotifier(this._repository, {bool isPersonalMode = false})
      : _isPersonalMode = isPersonalMode,
        super([]);

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
    if (_isPersonalMode) return;
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

  /// Сохраняет локально (обязательно) и пытается синхронизировать с сервером.
  /// Возвращает true если данные ушли на сервер, false — если только в Drift.
  Future<bool> saveAttendance() async {
    await _repository.saveLocally(state);
    if (_isPersonalMode) return true;
    try {
      await _repository.syncToRemote();
      AppLogger.info('Посещаемость синхронизирована с сервером', 'LessonAttendanceMarkNotifier');
      return true;
    } catch (e) {
      AppLogger.warning('Синхронизация отложена (оффлайн), данные сохранены локально', 'LessonAttendanceMarkNotifier');
      return false;
    }
  }

  /// Вызывается при восстановлении соединения — отправляет все отложенные записи.
  Future<void> syncPending() async {
    if (_isPersonalMode) return;
    try {
      await _repository.syncToRemote();
      AppLogger.info('Отложенная синхронизация посещаемости выполнена', 'LessonAttendanceMarkNotifier');
    } catch (e) {
      AppLogger.warning('syncPending: синхронизация не удалась', 'LessonAttendanceMarkNotifier');
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
>(
  (ref) => LessonAttendanceMarkNotifier(
    ref.watch(attendanceRepositoryProvider),
    isPersonalMode: ref.watch(personalModeProvider).isActive,
  ),
);
