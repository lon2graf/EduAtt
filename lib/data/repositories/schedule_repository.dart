import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/local_db/dao/schedule_dao.dart';
import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/models/schedule_model.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScheduleRepository {
  final AppDatabase _db;
  final ScheduleDao _dao;

  ScheduleRepository(AppDatabase db)
    : _db = db,
      _dao = ScheduleDao(db);

  // ── Reactive streams (Drift SSoT) ──────────────────────────────────────────

  Stream<List<ScheduleModel>> watchForGroup(String groupId) =>
      _dao.watchForGroup(groupId).map(_mapRows);

  Stream<List<ScheduleModel>> watchForTeacher(String teacherId) =>
      _dao.watchForTeacher(teacherId).map(_mapRows);

  // ── Delta sync (Supabase → Drift) ──────────────────────────────────────────

  Future<void> syncForGroup(String groupId) async {
    AppLogger.info('Синхронизация расписания группы $groupId', 'ScheduleRepository');
    await _syncSchedules(groupId: groupId);
    await _syncLessons(groupId: groupId);
  }

  Future<void> syncForTeacher(String teacherId) async {
    AppLogger.info('Синхронизация расписания преподавателя $teacherId', 'ScheduleRepository');
    await _syncSchedules(teacherId: teacherId);
    await _syncLessons(teacherId: teacherId);
  }

  // ── Real-time entry-point ───────────────────────────────────────────────────

  /// Called when the Supabase lessons stream emits new rows.
  Future<void> upsertLessonsFromRaw(List<Map<String, dynamic>> raw) async {
    if (raw.isEmpty) return;
    final companions = raw.map(
      (row) => LessonsCompanion.insert(
        id: row['id'] as String,
        scheduleId: row['schedule_id'] as String,
        topic: Value(row['topic'] as String?),
        attendanceStatus: row['attendance_status'] as String? ?? 'free',
      ),
    ).toList();
    await _dao.upsertAllLessons(companions);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<void> _syncSchedules({String? groupId, String? teacherId}) async {
    assert(groupId != null || teacherId != null);

    var query = BaseService.client
        .from('schedule')
        .select('id, institution_id, subject_id, group_id, start_time, end_time, teacher_id, date, weekday');

    final response = groupId != null
        ? await query.eq('group_id', groupId)
        : await query.eq('teacher_id', teacherId!);

    final companions = (response as List).cast<Map<String, dynamic>>().map(
      (row) => SchedulesCompanion.insert(
        id: row['id'] as String,
        institutionId: row['institution_id'] as String,
        subjectId: row['subject_id'] as String,
        groupId: row['group_id'] as String,
        startTime: row['start_time'] as String,
        endTime: row['end_time'] as String,
        teacherId: row['teacher_id'] as String,
        date: DateTime.parse(row['date'] as String),
        weekday: row['weekday'] as int,
      ),
    ).toList();

    await _dao.upsertAllSchedules(companions);
    AppLogger.debug('Upserted ${companions.length} schedules', 'ScheduleRepository');
  }

  Future<void> _syncLessons({String? groupId, String? teacherId}) async {
    assert(groupId != null || teacherId != null);

    final List<dynamic> response;
    if (groupId != null) {
      response = await BaseService.client
          .from('lessons')
          .select('id, schedule_id, topic, attendance_status, schedule!inner(group_id)')
          .eq('schedule.group_id', groupId);
    } else {
      response = await BaseService.client
          .from('lessons')
          .select('id, schedule_id, topic, attendance_status, schedule!inner(teacher_id)')
          .eq('schedule.teacher_id', teacherId!);
    }

    final companions = response.cast<Map<String, dynamic>>().map(
      (row) => LessonsCompanion.insert(
        id: row['id'] as String,
        scheduleId: row['schedule_id'] as String,
        topic: Value(row['topic'] as String?),
        attendanceStatus: row['attendance_status'] as String? ?? 'free',
      ),
    ).toList();

    await _dao.upsertAllLessons(companions);
    AppLogger.debug('Upserted ${companions.length} lessons', 'ScheduleRepository');
  }

  // ── TypedResult → ScheduleModel ─────────────────────────────────────────────

  List<ScheduleModel> _mapRows(List<TypedResult> rows) {
    // De-duplicate by schedule ID in case a schedule has multiple lessons.
    final seen = <String>{};
    final result = <ScheduleModel>[];

    for (final row in rows) {
      final s = row.readTable(_db.schedules);
      if (!seen.add(s.id)) continue;

      final sub = row.readTable(_db.subjects);
      final t = row.readTable(_db.teachers);
      final g = row.readTable(_db.groups);
      final l = row.readTableOrNull(_db.lessons);

      result.add(ScheduleModel(
        id: s.id,
        topic: l?.topic,
        startTime: s.startTime,
        endTime: s.endTime,
        date: s.date,
        weekday: s.weekday,
        subjectName: sub.name,
        teacherFullName: '${t.surname} ${t.name}'.trim(),
        groupName: g.name,
      ));
    }
    return result;
  }
}

final scheduleRepositoryProvider = Provider<ScheduleRepository>(
  (ref) => ScheduleRepository(ref.watch(appDatabaseProvider)),
);
