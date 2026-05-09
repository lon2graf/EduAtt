import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';

class AttendanceDao {
  final AppDatabase _db;

  AttendanceDao(this._db);

  Future<List<LessonAttendance>> getForLesson(String lessonId) =>
      (_db.select(_db.lessonAttendances)
            ..where((t) => t.lessonId.equals(lessonId)))
          .get();

  Future<void> upsertAll(List<LessonAttendancesCompanion> companions) =>
      _db.batch(
        (b) => b.insertAllOnConflictUpdate(_db.lessonAttendances, companions),
      );

  Future<List<LessonAttendance>> getUnsynced() =>
      (_db.select(_db.lessonAttendances)
            ..where((t) => t.isSynced.equals(false)))
          .get();

  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    await (_db.update(_db.lessonAttendances)
          ..where((t) => t.id.isIn(ids)))
        .write(const LessonAttendancesCompanion(isSynced: Value(true)));
  }

  /// Реактивный стрим посещаемости студента с JOIN на lessons/schedules/subjects/teachers.
  Stream<List<TypedResult>> watchForStudent(String studentId) =>
      (_db
              .select(_db.lessonAttendances)
              .join([
                innerJoin(
                  _db.lessons,
                  _db.lessons.id.equalsExp(_db.lessonAttendances.lessonId),
                ),
                innerJoin(
                  _db.schedules,
                  _db.schedules.id.equalsExp(_db.lessons.scheduleId),
                ),
                innerJoin(
                  _db.subjects,
                  _db.subjects.id.equalsExp(_db.schedules.subjectId),
                ),
                innerJoin(
                  _db.teachers,
                  _db.teachers.id.equalsExp(_db.schedules.teacherId),
                ),
              ])
            ..where(_db.lessonAttendances.studentId.equals(studentId))
            ..orderBy([
              OrderingTerm.asc(_db.schedules.date),
              OrderingTerm.asc(_db.schedules.startTime),
            ]))
          .watch();

  /// Возвращает максимальное значение server_updated_at для студента.
  /// Используется для delta sync: «с какого момента качать новые данные».
  Future<DateTime?> getMaxServerUpdatedAt(String studentId) async {
    final row = await _db
        .customSelect(
          'SELECT MAX(server_updated_at) AS max_ts '
          'FROM lesson_attendances WHERE student_id = ?',
          variables: [Variable.withString(studentId)],
          readsFrom: {_db.lessonAttendances},
        )
        .getSingle();
    final ms = row.read<int?>('max_ts');
    return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }
}
