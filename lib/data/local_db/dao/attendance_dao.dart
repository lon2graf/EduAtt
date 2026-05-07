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
}
