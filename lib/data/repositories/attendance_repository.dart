import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/local_db/dao/attendance_dao.dart';
import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/data/remote/lessons_attendace_service.dart';
import 'package:edu_att/data/repositories/i_attendance_repository.dart';
import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/utils/app_logger.dart';

class AttendanceRepository implements IAttendanceRepository {
  final AppDatabase _db;
  final AttendanceDao _dao;

  AttendanceRepository(AppDatabase db) : _db = db, _dao = AttendanceDao(db);

  @override
  Future<List<LessonAttendanceModel>> getForLesson(String lessonId) async {
    final local = await _dao.getForLesson(lessonId);
    if (local.isNotEmpty) {
      AppLogger.debug('Посещаемость загружена из локальной БД', 'AttendanceRepository');
      return local.map(LessonAttendanceModel.fromDrift).toList();
    }

    AppLogger.debug('Локальная БД пуста, загружаем из Supabase', 'AttendanceRepository');
    final remote = await LessonsAttendanceService.getAttendancesForLesson(lessonId);
    if (remote.isNotEmpty) {
      await _dao.upsertAll(remote.map((m) => m.toCompanion()).toList());
    }
    return remote;
  }

  @override
  Future<void> saveLocally(List<LessonAttendanceModel> attendances) =>
      _dao.upsertAll(
        attendances.map((m) => m.toCompanion(isSynced: false)).toList(),
      );

  @override
  Future<void> syncToRemote() async {
    final unsynced = await _dao.getUnsynced();
    if (unsynced.isEmpty) return;

    final models = unsynced.map(LessonAttendanceModel.fromDrift).toList();
    await LessonsAttendanceService.saveAttendances(models);
    await _dao.markAsSynced(unsynced.map((r) => r.id).toList());

    AppLogger.info(
      'Синхронизировано ${unsynced.length} записей посещаемости',
      'AttendanceRepository',
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> watchLesson(String lessonId) =>
      LessonsAttendanceService.getAttendanceStream(lessonId);

  @override
  Stream<List<LessonAttendanceModel>> watchStudentAttendance(String studentId) =>
      _dao.watchForStudent(studentId).map(
        (rows) => rows.map((row) {
          final a = row.readTable(_db.lessonAttendances);
          final s = row.readTable(_db.schedules);
          final sub = row.readTable(_db.subjects);
          final t = row.readTable(_db.teachers);
          return LessonAttendanceModel(
            id: a.id,
            lessonId: a.lessonId,
            studentId: a.studentId,
            status: AttendanceStatus.fromString(a.status),
            lessonDate: s.date,
            lessonStart: s.startTime,
            lessonEnd: s.endTime,
            subjectName: sub.name,
            teacherName: t.name,
            teacherSurname: t.surname,
          );
        }).toList(),
      );

  @override
  Future<void> syncDelta(String studentId) async {
    final response = await BaseService.client
        .from('lesson_attendances')
        .select('id, lesson_id, student_id, status')
        .eq('student_id', studentId);

    if ((response as List).isNotEmpty) {
      AppLogger.info(
        'Delta sync: получено ${response.length} записей',
        'AttendanceRepository',
      );
      await upsertFromRemote(response.cast<Map<String, dynamic>>());
    }
  }

  @override
  Future<void> markSelfPresent({
    required String lessonId,
    required String studentId,
  }) =>
      LessonsAttendanceService.markSelfPresent(
        lessonId: lessonId,
        studentId: studentId,
      );

  @override
  Stream<List<Map<String, dynamic>>> watchRemoteStudent(String studentId) =>
      LessonsAttendanceService.getStudentAttendanceStream(studentId);

  @override
  Future<List<LessonAttendanceModel>> getWeeklyGroupAttendance({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      LessonsAttendanceService.getWeeklyGroupAttendance(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );

  @override
  Future<void> upsertFromRemote(List<Map<String, dynamic>> raw) async {
    if (raw.isEmpty) return;
    final companions = raw.map(
      (row) => LessonAttendancesCompanion.insert(
        id: row['id'] as String,
        lessonId: row['lesson_id'] as String,
        studentId: row['student_id'] as String,
        status: Value(row['status'] as String?),
        isSynced: const Value(true),
      ),
    ).toList();
    await _dao.upsertAll(companions);
  }
}
