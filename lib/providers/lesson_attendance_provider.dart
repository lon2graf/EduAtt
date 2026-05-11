import 'dart:async';

import 'package:edu_att/data/repositories/i_attendance_repository.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/providers/lesson_attendance_mark_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter_riverpod/legacy.dart';

class AttendanceNotifier extends StateNotifier<List<LessonAttendanceModel>> {
  final IAttendanceRepository _repository;

  StreamSubscription<List<LessonAttendanceModel>>? _driftSub;
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSub;

  AttendanceNotifier(this._repository) : super([]);

  /// Подписывается на Drift-стрим (SSoT для UI) + Supabase real-time + delta sync.
  Future<void> initStudentStream(String studentId) async {
    _driftSub?.cancel();
    _realtimeSub?.cancel();

    // 1. Drift-стрим обновляет state автоматически
    _driftSub = _repository.watchStudentAttendance(studentId).listen(
      (data) => state = data,
      onError: (e) => AppLogger.error(
        'Ошибка в Drift-стриме посещаемости',
        e,
        null,
        'AttendanceNotifier',
      ),
    );

    // 2. Supabase real-time → в БД, не напрямую в state
    _realtimeSub =
        _repository.watchRemoteStudent(studentId).listen(
          (data) => _repository.upsertFromRemote(data).catchError((_) {}),
          onError: (e) => AppLogger.warning(
            'Ошибка real-time посещаемости',
            'AttendanceNotifier',
          ),
        );

    // 3. Background delta sync (fire-and-forget)
    _backgroundSync(studentId);
  }

  /// Ручной delta sync (pull-to-refresh).
  Future<void> syncAttendanceDelta(String studentId) =>
      _repository.syncDelta(studentId);

  void _backgroundSync(String studentId) {
    _repository.syncDelta(studentId).catchError(
      (e) => AppLogger.warning('Фоновый delta sync не удался', 'AttendanceNotifier'),
    );
  }

  void clear() {
    _driftSub?.cancel();
    _realtimeSub?.cancel();
    _driftSub = null;
    _realtimeSub = null;
    state = [];
  }

  List<LessonAttendanceModel> bySubject(String subjectName) =>
      state.where((e) => e.subjectName == subjectName).toList();

  @override
  void dispose() {
    _driftSub?.cancel();
    _realtimeSub?.cancel();
    super.dispose();
  }
}

final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, List<LessonAttendanceModel>>(
      (ref) => AttendanceNotifier(ref.watch(attendanceRepositoryProvider)),
    );
