import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/models/excuse_request_model.dart';

class ExcuseDao {
  final AppDatabase _db;

  ExcuseDao(this._db);

  Future<ExcuseRequest?> getByLessonAndStudent(
    String lessonId,
    String studentId,
  ) =>
      (_db.select(_db.excuseRequests)
            ..where(
              (e) =>
                  e.lessonId.equals(lessonId) & e.studentId.equals(studentId),
            ))
          .getSingleOrNull();

  Future<List<ExcuseRequest>> getForLesson(String lessonId) =>
      (_db.select(_db.excuseRequests)
            ..where((e) => e.lessonId.equals(lessonId)))
          .get();

  Future<List<ExcuseRequest>> getForLessonIds(List<String> lessonIds) {
    if (lessonIds.isEmpty) return Future.value([]);
    return (_db.select(_db.excuseRequests)
          ..where((e) => e.lessonId.isIn(lessonIds)))
        .get();
  }

  Stream<List<ExcuseRequest>> watchForStudent(String studentId) =>
      (_db.select(_db.excuseRequests)
            ..where((e) => e.studentId.equals(studentId))
            ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
          .watch();

  Future<void> upsert(ExcuseRequestsCompanion companion) =>
      _db.into(_db.excuseRequests).insertOnConflictUpdate(companion);

  Future<List<ExcuseRequest>> getUnsynced() =>
      (_db.select(_db.excuseRequests)
            ..where((e) => e.isSynced.equals(false)))
          .get();

  Future<void> markSynced(List<String> ids) =>
      (_db.update(_db.excuseRequests)..where((e) => e.id.isIn(ids))).write(
        const ExcuseRequestsCompanion(isSynced: Value(true)),
      );

  /// Помечает объяснительную как проверенную (approved/rejected) локально.
  Future<void> updateStatus({
    required String id,
    required ExcuseStatusType status,
    required String reviewedBy,
    required DateTime reviewedAt,
  }) =>
      (_db.update(_db.excuseRequests)..where((e) => e.id.equals(id))).write(
        ExcuseRequestsCompanion(
          status: Value(status.toDbValue),
          reviewedBy: Value(reviewedBy),
          reviewedAt: Value(reviewedAt),
          isSynced: const Value(false),
        ),
      );

  /// Реактивный стрим количества ожидающих объяснительных для преподавателя.
  /// Джойнит excuse_requests → lessons → schedules по teacherId.
  Stream<int> watchPendingCountForTeacher(String teacherId) {
    final query = _db.select(_db.excuseRequests).join([
      innerJoin(
        _db.lessons,
        _db.lessons.id.equalsExp(_db.excuseRequests.lessonId),
      ),
      innerJoin(
        _db.schedules,
        _db.schedules.id.equalsExp(_db.lessons.scheduleId),
      ),
    ])
      ..where(
        _db.excuseRequests.status.equals('pending') &
            _db.schedules.teacherId.equals(teacherId),
      );
    return query.watch().map((rows) => rows.length);
  }

  ExcuseRequestModel fromRow(ExcuseRequest row) => ExcuseRequestModel(
    id: row.id,
    lessonId: row.lessonId,
    studentId: row.studentId,
    reasonType: ExcuseReasonType.fromString(row.reasonType),
    description: row.description,
    status: ExcuseStatusType.fromString(row.status),
    createdAt: row.createdAt,
    reviewedBy: row.reviewedBy,
    reviewedAt: row.reviewedAt,
    isSynced: row.isSynced,
  );
}
