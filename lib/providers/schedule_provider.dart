import 'dart:async';

import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/data/repositories/schedule_repository.dart';
import 'package:edu_att/models/schedule_model.dart';
import 'package:flutter_riverpod/legacy.dart';

// ── State ────────────────────────────────────────────────────────────────────

class ScheduleState {
  final List<ScheduleModel> schedules;
  final DateTime selectedDay;
  final bool isLoading;

  const ScheduleState({
    this.schedules = const [],
    required this.selectedDay,
    this.isLoading = false,
  });

  /// Lessons for the selected day, sorted by start time.
  List<ScheduleModel> get schedulesForDay => schedules
      .where((s) => _isSameDay(s.date, selectedDay))
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  /// Lesson currently in progress (today).
  ScheduleModel? get ongoingLesson {
    final now = DateTime.now();
    final t = _timeStr(now);
    final matches = schedules.where((s) =>
        _isSameDay(s.date, now) &&
        s.startTime.compareTo(t) <= 0 &&
        s.endTime.compareTo(t) > 0);
    return matches.isEmpty ? null : matches.first;
  }

  /// Next lesson today that hasn't started yet.
  ScheduleModel? get nextTodayLesson {
    final now = DateTime.now();
    final t = _timeStr(now);
    final upcoming = schedules
        .where((s) => _isSameDay(s.date, now) && s.startTime.compareTo(t) > 0)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _timeStr(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:'
      '${dt.second.toString().padLeft(2, '0')}';

  ScheduleState copyWith({
    List<ScheduleModel>? schedules,
    DateTime? selectedDay,
    bool? isLoading,
  }) => ScheduleState(
    schedules: schedules ?? this.schedules,
    selectedDay: selectedDay ?? this.selectedDay,
    isLoading: isLoading ?? this.isLoading,
  );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final ScheduleRepository _repository;

  StreamSubscription<List<ScheduleModel>>? _driftSub;
  StreamSubscription<List<Map<String, dynamic>>>? _scheduleRealtimeSub;
  StreamSubscription<List<Map<String, dynamic>>>? _lessonsRealtimeSub;

  String? _groupId;
  String? _teacherId;

  ScheduleNotifier(this._repository)
    : super(ScheduleState(selectedDay: DateTime.now()));

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called when a student's schedule screen opens.
  Future<void> initScheduleStream(String groupId) async {
    if (_groupId == groupId) return; // already watching
    _groupId = groupId;
    _teacherId = null;
    await _cancelSubscriptions();

    state = state.copyWith(isLoading: true);

    _driftSub = _repository.watchForGroup(groupId).listen(
      (data) => state = state.copyWith(schedules: data, isLoading: false),
    );

    _backgroundSync();
    _subscribeScheduleRealtime(groupId: groupId);
    _subscribeLessonsRealtime();
  }

  /// Called when a teacher's schedule screen opens.
  Future<void> initTeacherScheduleStream(String teacherId) async {
    if (_teacherId == teacherId) return;
    _teacherId = teacherId;
    _groupId = null;
    await _cancelSubscriptions();

    state = state.copyWith(isLoading: true);

    _driftSub = _repository.watchForTeacher(teacherId).listen(
      (data) => state = state.copyWith(schedules: data, isLoading: false),
    );

    _backgroundSyncTeacher();
    _subscribeScheduleRealtime(teacherId: teacherId);
    _subscribeLessonsRealtime();
  }

  /// Triggered by pull-to-refresh. Awaitable so the indicator can stop.
  Future<void> syncSchedule() async {
    try {
      if (_groupId != null) {
        await _repository.syncForGroup(_groupId!);
      } else if (_teacherId != null) {
        await _repository.syncForTeacher(_teacherId!);
      }
    } catch (_) {}
  }

  void selectDay(DateTime day) => state = state.copyWith(selectedDay: day);

  @override
  void dispose() {
    _driftSub?.cancel();
    _scheduleRealtimeSub?.cancel();
    _lessonsRealtimeSub?.cancel();
    _driftSub = null;
    _scheduleRealtimeSub = null;
    _lessonsRealtimeSub = null;
    super.dispose();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _cancelSubscriptions() async {
    await _driftSub?.cancel();
    await _scheduleRealtimeSub?.cancel();
    await _lessonsRealtimeSub?.cancel();
    _driftSub = null;
    _scheduleRealtimeSub = null;
    _lessonsRealtimeSub = null;
  }

  void _backgroundSync() {
    _repository.syncForGroup(_groupId!).catchError((_) {});
  }

  void _backgroundSyncTeacher() {
    _repository.syncForTeacher(_teacherId!).catchError((_) {});
  }

  /// Supabase stream on `schedule` for the group/teacher.
  /// When schedule rows change, trigger a full sync (picks up lesson changes too).
  void _subscribeScheduleRealtime({String? groupId, String? teacherId}) {
    final stream = groupId != null
        ? BaseService.client
            .from('schedule')
            .stream(primaryKey: ['id'])
            .eq('group_id', groupId)
        : BaseService.client
            .from('schedule')
            .stream(primaryKey: ['id'])
            .eq('teacher_id', teacherId!);

    _scheduleRealtimeSub = stream.listen((_) {
      // Any schedule change → re-sync schedules + lessons
      if (groupId != null) {
        _repository.syncForGroup(groupId).catchError((_) {});
      } else if (teacherId != null) {
        _repository.syncForTeacher(teacherId).catchError((_) {});
      }
    });
  }

  /// Supabase stream on `lessons` (no group filter — filtered client-side via
  /// the Drift JOIN query). Handles real-time topic updates.
  void _subscribeLessonsRealtime() {
    _lessonsRealtimeSub = BaseService.client
        .from('lessons')
        .stream(primaryKey: ['id'])
        .listen((rows) {
          _repository
              .upsertLessonsFromRaw(rows.cast<Map<String, dynamic>>())
              .catchError((_) {});
        });
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, ScheduleState>(
  (ref) => ScheduleNotifier(ref.watch(scheduleRepositoryProvider)),
);
