import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/models/lesson_model.dart';

class LessonDao {
  final AppDatabase _db;

  LessonDao(this._db);

  Future<LessonModel?> getCurrentForGroup(String groupId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final nowTime = _formatTime(now);

    final row = await (_db.select(_db.lessons).join([
      innerJoin(_db.schedules, _db.schedules.id.equalsExp(_db.lessons.scheduleId)),
      innerJoin(_db.subjects, _db.subjects.id.equalsExp(_db.schedules.subjectId)),
      innerJoin(_db.teachers, _db.teachers.id.equalsExp(_db.schedules.teacherId)),
      innerJoin(_db.groups, _db.groups.id.equalsExp(_db.schedules.groupId)),
    ])
      ..where(
        _db.schedules.groupId.equals(groupId) &
        _db.schedules.date.isBetweenValues(todayStart, todayEnd) &
        _db.schedules.startTime.isSmallerOrEqualValue(nowTime) &
        _db.schedules.endTime.isBiggerThanValue(nowTime),
      ))
    .getSingleOrNull();

    return row != null ? _fromRow(row) : null;
  }

  Future<LessonModel?> getCurrentForTeacher(String teacherId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final nowTime = _formatTime(now);

    final row = await (_db.select(_db.lessons).join([
      innerJoin(_db.schedules, _db.schedules.id.equalsExp(_db.lessons.scheduleId)),
      innerJoin(_db.subjects, _db.subjects.id.equalsExp(_db.schedules.subjectId)),
      innerJoin(_db.teachers, _db.teachers.id.equalsExp(_db.schedules.teacherId)),
      innerJoin(_db.groups, _db.groups.id.equalsExp(_db.schedules.groupId)),
    ])
      ..where(
        _db.schedules.teacherId.equals(teacherId) &
        _db.schedules.date.isBetweenValues(todayStart, todayEnd) &
        _db.schedules.startTime.isSmallerOrEqualValue(nowTime) &
        _db.schedules.endTime.isBiggerThanValue(nowTime),
      ))
    .getSingleOrNull();

    return row != null ? _fromRow(row) : null;
  }

  /// Ближайшее занятие сегодня, которое ещё не началось (используется в Личном режиме).
  Future<LessonModel?> getNextForGroup(String groupId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final nowTime = _formatTime(now);

    final rows = await (_db.select(_db.lessons).join([
      innerJoin(_db.schedules, _db.schedules.id.equalsExp(_db.lessons.scheduleId)),
      innerJoin(_db.subjects, _db.subjects.id.equalsExp(_db.schedules.subjectId)),
      innerJoin(_db.teachers, _db.teachers.id.equalsExp(_db.schedules.teacherId)),
      innerJoin(_db.groups, _db.groups.id.equalsExp(_db.schedules.groupId)),
    ])
      ..where(
        _db.schedules.groupId.equals(groupId) &
        _db.schedules.date.isBetweenValues(todayStart, todayEnd) &
        _db.schedules.startTime.isBiggerThanValue(nowTime),
      )
      ..orderBy([OrderingTerm.asc(_db.schedules.startTime)]))
        .get();

    return rows.isNotEmpty ? _fromRow(rows.first) : null;
  }

  /// Реактивный стрим: все уроки преподавателя на сегодня, отсортированные по
  /// времени начала. Time-check (current vs upcoming) вычисляется в .map()
  /// при каждой эмиссии — поэтому не устаревает при изменении данных.
  Stream<LessonModel?> watchCurrentOrNextForTeacher(String teacherId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return (_db.select(_db.lessons).join([
      innerJoin(_db.schedules, _db.schedules.id.equalsExp(_db.lessons.scheduleId)),
      innerJoin(_db.subjects, _db.subjects.id.equalsExp(_db.schedules.subjectId)),
      innerJoin(_db.teachers, _db.teachers.id.equalsExp(_db.schedules.teacherId)),
      innerJoin(_db.groups, _db.groups.id.equalsExp(_db.schedules.groupId)),
    ])
      ..where(
        _db.schedules.teacherId.equals(teacherId) &
        _db.schedules.date.isBetweenValues(todayStart, todayEnd),
      )
      ..orderBy([OrderingTerm.asc(_db.schedules.startTime)]))
    .watch()
    .map((rows) {
      final nowTime = _formatTime(DateTime.now());
      LessonModel? upcoming;
      for (final row in rows) {
        final s = row.readTable(_db.schedules);
        if (s.startTime.compareTo(nowTime) <= 0 && s.endTime.compareTo(nowTime) > 0) {
          return _fromRow(row);
        }
        if (upcoming == null && s.startTime.compareTo(nowTime) > 0) {
          upcoming = _fromRow(row);
        }
      }
      return upcoming;
    });
  }

  /// Ближайшее занятие сегодня для преподавателя (Личный режим).
  Future<LessonModel?> getNextForTeacher(String teacherId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final nowTime = _formatTime(now);

    final rows = await (_db.select(_db.lessons).join([
      innerJoin(_db.schedules, _db.schedules.id.equalsExp(_db.lessons.scheduleId)),
      innerJoin(_db.subjects, _db.subjects.id.equalsExp(_db.schedules.subjectId)),
      innerJoin(_db.teachers, _db.teachers.id.equalsExp(_db.schedules.teacherId)),
      innerJoin(_db.groups, _db.groups.id.equalsExp(_db.schedules.groupId)),
    ])
      ..where(
        _db.schedules.teacherId.equals(teacherId) &
        _db.schedules.date.isBetweenValues(todayStart, todayEnd) &
        _db.schedules.startTime.isBiggerThanValue(nowTime),
      )
      ..orderBy([OrderingTerm.asc(_db.schedules.startTime)]))
        .get();

    return rows.isNotEmpty ? _fromRow(rows.first) : null;
  }

  Stream<List<LessonModel>> watchPastForTeacher(String teacherId) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    return (_db.select(_db.lessons).join([
      innerJoin(_db.schedules, _db.schedules.id.equalsExp(_db.lessons.scheduleId)),
      innerJoin(_db.subjects, _db.subjects.id.equalsExp(_db.schedules.subjectId)),
      innerJoin(_db.teachers, _db.teachers.id.equalsExp(_db.schedules.teacherId)),
      innerJoin(_db.groups, _db.groups.id.equalsExp(_db.schedules.groupId)),
    ])
      ..where(
        _db.schedules.teacherId.equals(teacherId) &
        _db.schedules.date.isSmallerThanValue(todayStart),
      )
      ..orderBy([
        OrderingTerm.desc(_db.schedules.date),
        OrderingTerm.desc(_db.schedules.startTime),
      ]))
    .watch()
    .map((rows) => rows.map(_fromRow).toList());
  }

  Future<void> upsertLesson({
    required String id,
    required String scheduleId,
    String? topic,
    required String attendanceStatus,
  }) =>
      _db.into(_db.lessons).insertOnConflictUpdate(
            LessonsCompanion.insert(
              id: id,
              scheduleId: scheduleId,
              topic: Value(topic),
              attendanceStatus: attendanceStatus,
            ),
          );

  Future<void> upsertStatus(String lessonId, String status) =>
      (_db.update(_db.lessons)..where((l) => l.id.equals(lessonId)))
          .write(LessonsCompanion(attendanceStatus: Value(status)));

  Future<void> upsertTopic(String lessonId, String? topic) =>
      (_db.update(_db.lessons)..where((l) => l.id.equals(lessonId)))
          .write(LessonsCompanion(topic: Value(topic)));

  // ── Private helpers ────────────────────────────────────────────────────────

  LessonModel _fromRow(TypedResult row) {
    final lesson = row.readTable(_db.lessons);
    final schedule = row.readTable(_db.schedules);
    final subject = row.readTable(_db.subjects);
    final teacher = row.readTable(_db.teachers);
    final group = row.readTable(_db.groups);

    return LessonModel(
      id: lesson.id,
      topic: lesson.topic,
      date: _formatDate(schedule.date),
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      groupId: schedule.groupId,
      groupName: group.name,
      subjectName: subject.name,
      teacherName: teacher.name,
      teacherSurname: teacher.surname,
      status: LessonAttendanceStatus.fromString(lesson.attendanceStatus),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
