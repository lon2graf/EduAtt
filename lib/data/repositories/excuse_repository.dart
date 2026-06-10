import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/local_db/dao/excuse_dao.dart';
import 'package:edu_att/data/remote/excuse_service.dart';
import 'package:edu_att/models/excuse_request_model.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final excuseRepositoryProvider = Provider<ExcuseRepository>(
  (ref) => ExcuseRepository(ref.watch(appDatabaseProvider)),
);

/// Стрим количества pending-объяснительных для текущего преподавателя.
final pendingExcuseCountProvider = StreamProvider.autoDispose<int>((ref) {
  final teacher = ref.watch(teacherProvider);
  if (teacher?.id == null) return Stream.value(0);
  return ref
      .watch(excuseRepositoryProvider)
      .watchPendingCountForTeacher(teacher!.id!);
});

class ExcuseRepository {
  final AppDatabase _db;
  final ExcuseDao _dao;

  ExcuseRepository(AppDatabase db) : _db = db, _dao = ExcuseDao(db);

  /// Студент подаёт объяснительную.
  /// Сохраняет локально (isSynced=false) и отправляет в Supabase best-effort.
  Future<ExcuseRequestModel> submitExcuse({
    required String lessonId,
    required String studentId,
    required ExcuseReasonType reasonType,
    String? description,
  }) async {
    final now = DateTime.now();
    final id = const Uuid().v4();

    final companion = ExcuseRequestsCompanion.insert(
      id: id,
      lessonId: lessonId,
      studentId: studentId,
      reasonType: reasonType.toDbValue,
      description: Value(description),
      createdAt: now,
      isSynced: const Value(false),
    );

    await _dao.upsert(companion);

    var synced = false;
    final json = {
      'id': id,
      'lesson_id': lessonId,
      'student_id': studentId,
      'reason_type': reasonType.toDbValue,
      'description': description,
      'status': 'pending',
      'created_at': now.toIso8601String(),
    };

    try {
      await ExcuseService.submit(json);
      await _dao.markSynced([id]);
      synced = true;
    } catch (e) {
      AppLogger.warning('submitExcuse: отложена синхронизация ($e)', 'ExcuseRepository');
    }

    return ExcuseRequestModel(
      id: id,
      lessonId: lessonId,
      studentId: studentId,
      reasonType: reasonType,
      description: description,
      createdAt: now,
      isSynced: synced,
    );
  }

  /// Преподаватель одобряет или отклоняет объяснительную.
  /// Обновляет статус объяснительной и поле is_excused в lesson_attendances.
  /// Возвращает true если данные синхронизированы с сервером.
  Future<bool> reviewExcuse({
    required String excuseId,
    required bool approved,
    required String teacherId,
    required String attendanceId,
  }) async {
    final status = approved ? ExcuseStatusType.approved : ExcuseStatusType.rejected;
    final now = DateTime.now();

    // 1. Локально: обновляем объяснительную
    await _dao.updateStatus(
      id: excuseId,
      status: status,
      reviewedBy: teacherId,
      reviewedAt: now,
    );

    // 2. Локально: обновляем is_excused в lesson_attendances
    await (_db.update(_db.lessonAttendances)
          ..where((a) => a.id.equals(attendanceId)))
        .write(LessonAttendancesCompanion(isExcused: Value(approved)));

    // 3. Remote best-effort
    try {
      await ExcuseService.updateStatus(
        excuseId: excuseId,
        status: status.toDbValue,
        reviewedBy: teacherId,
        reviewedAt: now.toIso8601String(),
      );
      await ExcuseService.updateAttendanceExcused(
        attendanceId: attendanceId,
        isExcused: approved,
      );
      await _dao.markSynced([excuseId]);
      return true;
    } catch (e) {
      AppLogger.warning('reviewExcuse: отложена синхронизация ($e)', 'ExcuseRepository');
      return false;
    }
  }

  /// Загружает объяснительные для набора уроков (для аналитики).
  Future<List<ExcuseRequestModel>> getForLessonIds(
    List<String> lessonIds,
  ) async {
    final rows = await _dao.getForLessonIds(lessonIds);
    return rows.map(_dao.fromRow).toList();
  }

  /// Загружает объяснительные для урока (для экрана преподавателя).
  Future<List<ExcuseRequestModel>> getForLesson(String lessonId) async {
    final rows = await _dao.getForLesson(lessonId);
    if (rows.isNotEmpty) return rows.map(_dao.fromRow).toList();

    // Fallback: удалённая загрузка + кэш в Drift
    try {
      final remote = await ExcuseService.getForLesson(lessonId);
      for (final r in remote) {
        await _dao.upsert(_companionFromJson(r));
      }
      return remote.map(ExcuseRequestModel.fromJson).toList();
    } catch (e) {
      AppLogger.warning('getForLesson: нет данных ($e)', 'ExcuseRepository');
      return [];
    }
  }

  /// Реактивный стрим количества pending-объяснительных для преподавателя.
  Stream<int> watchPendingCountForTeacher(String teacherId) =>
      _dao.watchPendingCountForTeacher(teacherId);

  /// Реактивный стрим объяснительных студента (для экрана пропусков).
  Stream<List<ExcuseRequestModel>> watchForStudent(String studentId) =>
      _dao.watchForStudent(studentId).map(
        (rows) => rows.map(_dao.fromRow).toList(),
      );

  /// По конкретному пропуску — есть ли объяснительная?
  Future<ExcuseRequestModel?> getByAttendance(
    String lessonId,
    String studentId,
  ) async {
    final row = await _dao.getByLessonAndStudent(lessonId, studentId);
    return row != null ? _dao.fromRow(row) : null;
  }

  /// Синхронизирует непереданные объяснительные.
  Future<void> syncPending() async {
    final unsynced = await _dao.getUnsynced();
    if (unsynced.isEmpty) return;

    for (final row in unsynced) {
      try {
        final model = _dao.fromRow(row);
        if (model.status == ExcuseStatusType.pending) {
          await ExcuseService.submit(model.toJson());
        } else {
          await ExcuseService.updateStatus(
            excuseId: model.id,
            status: model.status.toDbValue,
            reviewedBy: model.reviewedBy ?? '',
            reviewedAt: model.reviewedAt?.toIso8601String() ?? '',
          );
        }
        await _dao.markSynced([row.id]);
      } catch (_) {}
    }

    AppLogger.info(
      'syncPending: отправлено ${unsynced.length} объяснительных',
      'ExcuseRepository',
    );
  }

  /// Скачивает объяснительные студента при начальной синхронизации.
  Future<void> syncForStudent(String studentId) async {
    try {
      final remote = await ExcuseService.getForStudent(studentId);
      for (final r in remote) {
        await _dao.upsert(_companionFromJson(r));
      }
    } catch (e) {
      AppLogger.warning('syncForStudent: $e', 'ExcuseRepository');
    }
  }

  /// Скачивает объяснительные для уроков преподавателя.
  Future<void> syncForTeacherLessons(List<String> lessonIds) async {
    for (final lessonId in lessonIds) {
      try {
        final remote = await ExcuseService.getForLesson(lessonId);
        for (final r in remote) {
          await _dao.upsert(_companionFromJson(r));
        }
      } catch (_) {}
    }
  }

  /// Синхронизирует объяснительные для всех уроков преподавателя из Supabase.
  /// Вызывается при загрузке главного экрана чтобы бейдж был актуальным.
  Future<void> syncForTeacher(String teacherId) async {
    try {
      final scheduleRows = await (_db.select(_db.schedules)
            ..where((s) => s.teacherId.equals(teacherId)))
          .get();
      if (scheduleRows.isEmpty) return;

      final scheduleIds = scheduleRows.map((s) => s.id).toSet();
      final lessonRows = await (_db.select(_db.lessons)
            ..where((l) => l.scheduleId.isIn(scheduleIds)))
          .get();
      if (lessonRows.isEmpty) return;

      final lessonIds = lessonRows.map((l) => l.id).toList();
      await syncForTeacherLessons(lessonIds);
    } catch (e) {
      AppLogger.warning('syncForTeacher: $e', 'ExcuseRepository');
    }
  }

  ExcuseRequestsCompanion _companionFromJson(Map<String, dynamic> r) =>
      ExcuseRequestsCompanion.insert(
        id: r['id'] as String,
        lessonId: r['lesson_id'] as String,
        studentId: r['student_id'] as String,
        reasonType: r['reason_type'] as String,
        description: Value(r['description'] as String?),
        status: Value(r['status'] as String? ?? 'pending'),
        createdAt: DateTime.parse(r['created_at'] as String),
        reviewedBy: Value(r['reviewed_by'] as String?),
        reviewedAt: Value(
          r['reviewed_at'] != null
              ? DateTime.tryParse(r['reviewed_at'] as String)
              : null,
        ),
        isSynced: const Value(true),
      );
}
