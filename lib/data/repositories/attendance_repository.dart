import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/local_db/dao/attendance_dao.dart';
import 'package:edu_att/data/remote/lessons_attendace_service.dart';
import 'package:edu_att/data/repositories/i_attendance_repository.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/utils/app_logger.dart';

class AttendanceRepository implements IAttendanceRepository {
  final AttendanceDao _dao;

  AttendanceRepository(AppDatabase db) : _dao = AttendanceDao(db);

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
}
