import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';

class ScheduleDao {
  final AppDatabase _db;

  ScheduleDao(this._db);

  /// Reactive stream: Schedules JOIN Subjects + Teachers + Groups + Lessons (LEFT).
  /// Emits whenever any of the joined rows change for this group.
  Stream<List<TypedResult>> watchForGroup(String groupId) =>
      (_db.select(_db.schedules).join([
        innerJoin(_db.subjects, _db.subjects.id.equalsExp(_db.schedules.subjectId)),
        innerJoin(_db.teachers, _db.teachers.id.equalsExp(_db.schedules.teacherId)),
        innerJoin(_db.groups, _db.groups.id.equalsExp(_db.schedules.groupId)),
        leftOuterJoin(
          _db.lessons,
          _db.lessons.scheduleId.equalsExp(_db.schedules.id),
        ),
      ])
        ..where(_db.schedules.groupId.equals(groupId))
        ..orderBy([
          OrderingTerm.asc(_db.schedules.date),
          OrderingTerm.asc(_db.schedules.startTime),
        ]))
          .watch();

  /// Same as watchForGroup but filtered by teacher.
  Stream<List<TypedResult>> watchForTeacher(String teacherId) =>
      (_db.select(_db.schedules).join([
        innerJoin(_db.subjects, _db.subjects.id.equalsExp(_db.schedules.subjectId)),
        innerJoin(_db.teachers, _db.teachers.id.equalsExp(_db.schedules.teacherId)),
        innerJoin(_db.groups, _db.groups.id.equalsExp(_db.schedules.groupId)),
        leftOuterJoin(
          _db.lessons,
          _db.lessons.scheduleId.equalsExp(_db.schedules.id),
        ),
      ])
        ..where(_db.schedules.teacherId.equals(teacherId))
        ..orderBy([
          OrderingTerm.asc(_db.schedules.date),
          OrderingTerm.asc(_db.schedules.startTime),
        ]))
          .watch();

  Future<void> upsertAllSchedules(List<SchedulesCompanion> companions) =>
      _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.schedules, companions),
      );

  Future<void> upsertAllLessons(List<LessonsCompanion> companions) =>
      _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.lessons, companions),
      );
}
