import 'package:edu_att/data/repositories/i_attendance_repository.dart';
import 'package:edu_att/models/group_analytics_data.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/providers/lesson_attendance_mark_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

enum AnalyticsPeriod { allTime, thisMonth, lastMonth, custom }

// Sentinel для корректного обнуления nullable поля в copyWith.
const _keep = Object();

class GroupAnalyticsState {
  final bool isLoading;
  final GroupAnalyticsData data;
  final AnalyticsPeriod period;
  final DateTimeRange? customRange;
  final String? groupId;
  final String? groupName;
  final String? selectedSubject;
  final List<String> availableSubjects;

  const GroupAnalyticsState({
    this.isLoading = false,
    this.data = GroupAnalyticsData.empty,
    this.period = AnalyticsPeriod.allTime,
    this.customRange,
    this.groupId,
    this.groupName,
    this.selectedSubject,
    this.availableSubjects = const [],
  });

  GroupAnalyticsState copyWith({
    bool? isLoading,
    GroupAnalyticsData? data,
    AnalyticsPeriod? period,
    DateTimeRange? customRange,
    String? groupId,
    String? groupName,
    Object? selectedSubject = _keep,
    List<String>? availableSubjects,
  }) =>
      GroupAnalyticsState(
        isLoading: isLoading ?? this.isLoading,
        data: data ?? this.data,
        period: period ?? this.period,
        customRange: customRange ?? this.customRange,
        groupId: groupId ?? this.groupId,
        groupName: groupName ?? this.groupName,
        selectedSubject: selectedSubject == _keep
            ? this.selectedSubject
            : selectedSubject as String?,
        availableSubjects: availableSubjects ?? this.availableSubjects,
      );
}

class GroupAnalyticsNotifier extends StateNotifier<GroupAnalyticsState> {
  final IAttendanceRepository _repository;

  // Полный набор загруженных записей за текущий период.
  // Фильтрация по предмету происходит над этим кешем без обращения к БД.
  List<LessonAttendanceModel> _cachedRecords = [];

  GroupAnalyticsNotifier(this._repository) : super(const GroupAnalyticsState());

  /// Полный набор записей за текущий период — используется для генерации PDF.
  List<LessonAttendanceModel> get records => List.unmodifiable(_cachedRecords);

  Future<void> loadForGroup(String groupId, String groupName) async {
    state = state.copyWith(
      isLoading: true,
      groupId: groupId,
      groupName: groupName,
    );
    await _reload(groupId, state.period, state.customRange);
  }

  Future<void> changePeriod(
    AnalyticsPeriod period, {
    DateTimeRange? customRange,
  }) async {
    final groupId = state.groupId;
    if (groupId == null) return;
    state = state.copyWith(
      isLoading: true,
      period: period,
      customRange: customRange,
    );
    await _reload(groupId, period, customRange ?? state.customRange);
  }

  /// Применяет фильтр по предмету без обращения к БД.
  void selectSubject(String? subject) {
    final filtered = subject == null
        ? _cachedRecords
        : _cachedRecords.where((r) => r.subjectName == subject).toList();
    state = state.copyWith(
      selectedSubject: subject,
      data: GroupAnalyticsHelper.compute(filtered),
    );
  }

  Future<void> _reload(
    String groupId,
    AnalyticsPeriod period,
    DateTimeRange? customRange,
  ) async {
    final range = _dateRange(period, customRange);
    try {
      final records = await _repository.getGroupAttendanceInRange(
        groupId: groupId,
        startDate: range.start,
        endDate: range.end,
      );

      _cachedRecords = records;

      final subjects = records
          .map((r) => r.subjectName)
          .whereType<String>()
          .toSet()
          .toList()
        ..sort();

      state = state.copyWith(
        isLoading: false,
        data: GroupAnalyticsHelper.compute(records),
        availableSubjects: subjects,
        selectedSubject: null,
      );

      AppLogger.debug(
        'Аналитика группы: ${records.length} записей, ${subjects.length} предметов',
        'GroupAnalyticsNotifier',
      );
    } catch (e) {
      AppLogger.error(
        'Ошибка загрузки аналитики группы',
        e,
        null,
        'GroupAnalyticsNotifier',
      );
      state = state.copyWith(isLoading: false);
    }
  }

  static DateTimeRange _dateRange(
    AnalyticsPeriod period,
    DateTimeRange? custom,
  ) {
    final now = DateTime.now();
    return switch (period) {
      AnalyticsPeriod.allTime => DateTimeRange(
          start: DateTime(2020),
          end: DateTime(2030),
        ),
      AnalyticsPeriod.thisMonth => DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        ),
      AnalyticsPeriod.lastMonth => DateTimeRange(
          start: DateTime(now.year, now.month - 1, 1),
          end: DateTime(now.year, now.month, 0),
        ),
      AnalyticsPeriod.custom =>
        custom ?? DateTimeRange(start: DateTime(2020), end: DateTime(2030)),
    };
  }
}

final groupAnalyticsProvider =
    StateNotifierProvider<GroupAnalyticsNotifier, GroupAnalyticsState>(
  (ref) => GroupAnalyticsNotifier(ref.watch(attendanceRepositoryProvider)),
);
