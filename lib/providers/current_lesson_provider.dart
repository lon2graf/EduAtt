import 'dart:async';

import 'package:edu_att/data/repositories/lesson_repository.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter_riverpod/legacy.dart';

final currentLessonProvider =
    StateNotifierProvider<CurrentLessonNotifier, LessonModel?>(
      (ref) => CurrentLessonNotifier(ref.watch(lessonRepositoryProvider)),
    );

class CurrentLessonNotifier extends StateNotifier<LessonModel?> {
  final LessonRepository _repository;
  StreamSubscription? _statusSubscription;

  CurrentLessonNotifier(this._repository) : super(null);

  Future<void> loadCurrentLesson(String groupId) async {
    final lesson = await _repository.getCurrentLesson(groupId);
    state = lesson;
    if (lesson?.id != null) _startStatusStream(lesson!.id!);
  }

  Future<void> loadCurrentLessonForTeacher(String teacherId) async {
    final lesson = await _repository.getCurrentLessonForTeacher(teacherId);
    state = lesson;
    if (lesson?.id != null) _startStatusStream(lesson!.id!);
  }

  /// Личный режим: текущее занятие, а если его нет — ближайшее на сегодня.
  Future<void> loadCurrentOrNextLesson(String groupId) async {
    var lesson = await _repository.getCurrentLesson(groupId);
    lesson ??= await _repository.getNextLesson(groupId);
    state = lesson;
    if (lesson?.id != null && !lesson!.isUpcoming) {
      _startStatusStream(lesson.id!);
    }
  }

  /// Личный режим (преподаватель): текущее или ближайшее занятие.
  Future<void> loadCurrentOrNextLessonForTeacher(String teacherId) async {
    var lesson = await _repository.getCurrentLessonForTeacher(teacherId);
    lesson ??= await _repository.getNextLessonForTeacher(teacherId);
    state = lesson;
    if (lesson?.id != null && !lesson!.isUpcoming) {
      _startStatusStream(lesson.id!);
    }
  }

  /// Обновляет статус на сервере и локально. Офлайн-безопасен: не бросает исключение.
  Future<void> updateLessonStatus(LessonAttendanceStatus status) async {
    if (state?.id == null) return;
    await _repository.updateStatus(state!.id!, status);
    state = state!.copyWith(status: status);
  }

  /// Запрашивает актуальный статус из Supabase. Только онлайн.
  Future<LessonAttendanceStatus> getFreshStatus() {
    if (state?.id == null) return Future.value(LessonAttendanceStatus.free);
    return _repository.getFreshStatus(state!.id!);
  }

  /// Обновляет статус только в памяти (без сетевого вызова).
  void updateStatus(LessonAttendanceStatus newStatus) {
    if (state == null) return;
    state = state!.copyWith(status: newStatus);
  }

  void _startStatusStream(String lessonId) {
    _statusSubscription?.cancel();
    _statusSubscription = _repository.watchStatus(lessonId).listen(
      (status) {
        if (status != null && state != null && state!.status != status) {
          AppLogger.info(
            'Realtime: статус урока изменился на $status',
            'CurrentLessonNotifier',
          );
          state = state!.copyWith(status: status);
        }
      },
      onError: (error) {
        AppLogger.error(
          'Realtime: ошибка в стриме урока',
          error,
          null,
          'CurrentLessonNotifier',
        );
      },
    );
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}
