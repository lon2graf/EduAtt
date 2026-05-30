import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/local_db/dao/lesson_dao.dart';
import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/data/remote/lesson_service.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepository(ref.watch(appDatabaseProvider)),
);

class LessonRepository {
  final LessonDao _dao;

  LessonRepository(AppDatabase db) : _dao = LessonDao(db);

  /// Offline-first: Drift → Supabase fallback.
  Future<LessonModel?> getCurrentLesson(String groupId) async {
    final local = await _dao.getCurrentForGroup(groupId);
    if (local != null) return local;
    try {
      return await LessonService.getCurrentLesson(groupId);
    } catch (e) {
      AppLogger.error('getCurrentLesson: сеть недоступна', e, null, 'LessonRepository');
      return null;
    }
  }

  /// Offline-first: Drift → Supabase fallback.
  Future<LessonModel?> getCurrentLessonForTeacher(String teacherId) async {
    final local = await _dao.getCurrentForTeacher(teacherId);
    if (local != null) return local;
    try {
      return await LessonService.getCurrentLessonForTeacher(teacherId);
    } catch (e) {
      AppLogger.error('getCurrentLessonForTeacher: сеть недоступна', e, null, 'LessonRepository');
      return null;
    }
  }

  /// Ближайшее занятие сегодня (только Drift — для Личного режима).
  Future<LessonModel?> getNextLesson(String groupId) =>
      _dao.getNextForGroup(groupId);

  /// Ближайшее занятие сегодня для преподавателя (только Drift).
  Future<LessonModel?> getNextLessonForTeacher(String teacherId) =>
      _dao.getNextForTeacher(teacherId);

  /// Обновляет статус: сначала на сервере (best-effort), затем локально в Drift.
  Future<void> updateStatus(String lessonId, LessonAttendanceStatus status) async {
    try {
      await LessonService.updateLessonStatus(lessonId, status);
    } catch (_) {
      // offline — обновляем только Drift, realtime подхватит при reconnect
    }
    await _dao.upsertStatus(lessonId, status.toDbValue);
  }

  /// Запрашивает актуальный статус из Supabase (только онлайн).
  Future<LessonAttendanceStatus> getFreshStatus(String lessonId) =>
      LessonService.getFreshStatus(lessonId);

  /// Realtime-поток статуса урока из Supabase.
  Stream<LessonAttendanceStatus?> watchStatus(String lessonId) =>
      BaseService.client
          .from('lessons')
          .stream(primaryKey: ['id'])
          .eq('id', lessonId)
          .map(
            (data) => data.isNotEmpty
                ? LessonAttendanceStatus.fromString(
                    data.first['attendance_status'] as String?,
                  )
                : null,
          );
}
