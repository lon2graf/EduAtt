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

  StreamSubscription? _lessonStreamSub;
  StreamSubscription? _realtimeSub;

  /// ID урока, статус которого отслеживается через единый Realtime-канал.
  String? _trackedLessonId;

  bool _createAttempted = false;

  CurrentLessonNotifier(this._repository) : super(null);

  // ── Student ────────────────────────────────────────────────────────────────

  Future<void> loadCurrentLesson(String groupId) async {
    final lesson = await _repository.getCurrentLesson(groupId);
    state = lesson;
    if (lesson?.id != null) {
      _trackedLessonId = lesson!.id;
      _startLessonsRealtime();
    }
  }

  Future<void> loadCurrentLessonForTeacher(String teacherId) async {
    final lesson = await _repository.getCurrentLessonForTeacher(teacherId);
    state = lesson;
    if (lesson?.id != null) {
      _trackedLessonId = lesson!.id;
      _startLessonsRealtime();
    }
  }

  Future<void> loadCurrentOrNextLesson(String groupId) async {
    var lesson = await _repository.getCurrentLesson(groupId);
    lesson ??= await _repository.getNextLesson(groupId);
    state = lesson;
    if (lesson?.id != null && !lesson!.isUpcoming) {
      _trackedLessonId = lesson.id;
      _startLessonsRealtime();
    }
  }

  // ── Teacher (reactive) ─────────────────────────────────────────────────────

  Future<void> loadCurrentOrNextLessonForTeacher(String teacherId) async {
    _createAttempted = false;

    await _lessonStreamSub?.cancel();

    _lessonStreamSub = _repository
        .watchCurrentOrNextLessonForTeacher(teacherId)
        .listen((lesson) async {
          state = lesson;

          if (lesson != null) {
            if (lesson.id != null && !lesson.isUpcoming) {
              _trackedLessonId = lesson.id;
            }
            return;
          }

          if (_createAttempted) return;
          _createAttempted = true;

          final fallback = await _repository.getCurrentLessonForTeacher(teacherId);
          if (fallback != null) {
            state = fallback;
            if (fallback.id != null && !fallback.isUpcoming) {
              _trackedLessonId = fallback.id;
            }
          }
        });

    _startLessonsRealtime();
  }

  // ── Status writes ──────────────────────────────────────────────────────────

  Future<void> updateLessonStatus(LessonAttendanceStatus status) async {
    if (state?.id == null) return;
    await _repository.updateStatus(state!.id!, status);
    state = state!.copyWith(status: status);
  }

  Future<LessonAttendanceStatus> getFreshStatus() {
    if (state?.id == null) return Future.value(LessonAttendanceStatus.free);
    return _repository.getFreshStatus(state!.id!);
  }

  void updateStatus(LessonAttendanceStatus newStatus) {
    if (state == null) return;
    state = state!.copyWith(status: newStatus);
  }

  // ── Private ────────────────────────────────────────────────────────────────

  /// Единый Supabase Realtime-канал для таблицы lessons.
  /// Обновляет Drift-кэш и проверяет изменение статуса отслеживаемого урока.
  void _startLessonsRealtime() {
    _realtimeSub?.cancel();
    _realtimeSub = _repository.watchLessonsRealtime().listen(
      (raw) {
        final lessonId = _trackedLessonId;
        if (lessonId == null || state == null) return;
        try {
          final match = raw.firstWhere(
            (r) => r['id'] == lessonId,
            orElse: () => {},
          );
          if (match.isEmpty) return;
          final newStatus = LessonAttendanceStatus.fromString(
            match['attendance_status'] as String?,
          );
          if (state!.status != newStatus) {
            AppLogger.info(
              'Realtime: статус урока изменился на $newStatus',
              'CurrentLessonNotifier',
            );
            state = state!.copyWith(status: newStatus);
          }
        } catch (_) {}
      },
      onError: (e) =>
          AppLogger.warning('Realtime lessons error: $e', 'CurrentLessonNotifier'),
    );
  }

  @override
  void dispose() {
    _lessonStreamSub?.cancel();
    _realtimeSub?.cancel();
    super.dispose();
  }
}
