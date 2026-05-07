import 'package:edu_att/data/remote/schedule_service.dart';
import 'package:edu_att/models/schedule_model.dart';
import 'package:edu_att/utils/data_result.dart';
import 'package:flutter_riverpod/legacy.dart';

// --- Состояние ---

class ScheduleState {
  final bool isLoading;
  final List<ScheduleModel> schedules;
  final DateTime selectedDay;

  const ScheduleState({
    this.isLoading = false,
    this.schedules = const [],
    required this.selectedDay,
  });

  /// Занятия на выбранный день, отсортированные по времени начала.
  List<ScheduleModel> get schedulesForDay => schedules
      .where((s) => _isSameDay(s.date, selectedDay))
      .toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  ScheduleState copyWith({
    bool? isLoading,
    List<ScheduleModel>? schedules,
    DateTime? selectedDay,
  }) =>
      ScheduleState(
        isLoading: isLoading ?? this.isLoading,
        schedules: schedules ?? this.schedules,
        selectedDay: selectedDay ?? this.selectedDay,
      );
}

// --- Нотифайер ---

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  ScheduleNotifier() : super(ScheduleState(selectedDay: DateTime.now()));

  Future<DataResult<void>> loadForStudent(String groupId) async {
    state = state.copyWith(isLoading: true);
    final result = await ScheduleService.getScheduleByGroup(groupId);
    return switch (result) {
      Success(:final data) => _applyData(data),
      Failure(:final message, :final error) => _applyError(message, error),
    };
  }

  Future<DataResult<void>> loadForTeacher(String teacherId) async {
    state = state.copyWith(isLoading: true);
    final result = await ScheduleService.getScheduleByTeacher(teacherId);
    return switch (result) {
      Success(:final data) => _applyData(data),
      Failure(:final message, :final error) => _applyError(message, error),
    };
  }

  void selectDay(DateTime day) => state = state.copyWith(selectedDay: day);

  DataResult<void> _applyData(List<ScheduleModel> data) {
    state = state.copyWith(isLoading: false, schedules: data);
    return const Success(null);
  }

  DataResult<void> _applyError(String message, Object? error) {
    state = state.copyWith(isLoading: false);
    return Failure(message, error);
  }
}

// --- Провайдер ---

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, ScheduleState>(
      (ref) => ScheduleNotifier(),
    );
