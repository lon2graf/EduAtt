import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/local_db/dao/lesson_dao.dart';
import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/data/remote/lesson_service.dart';
import 'package:edu_att/data/services/personal_mode_service.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final lessonRepositoryProvider = Provider<LessonRepository>(
  (ref) => LessonRepository(ref.watch(appDatabaseProvider)),
);

class LessonRepository {
  final LessonDao _dao;
  final AppDatabase _db;

  LessonRepository(AppDatabase db) : _dao = LessonDao(db), _db = db;

  /// Offline-first: Drift → Supabase fallback.
  Future<LessonModel?> getCurrentLesson(String groupId) async {
    final local = await _dao.getCurrentForGroup(groupId);
    if (local != null) return local;
    if (groupId == PersonalModeService.kDefaultGroupId) return null;
    try {
      return await LessonService.getCurrentLesson(groupId);
    } catch (e) {
      AppLogger.error('getCurrentLesson: сеть недоступна', e, null, 'LessonRepository');
      return null;
    }
  }

  /// Offline-first: Drift → Supabase → auto-create from schedule fallback.
  Future<LessonModel?> getCurrentLessonForTeacher(String teacherId) async {
    final local = await _dao.getCurrentForTeacher(teacherId);
    if (local != null) return local;
    if (teacherId == PersonalModeService.kTeacherId) return null;
    try {
      final remote = await LessonService.getCurrentLessonForTeacher(teacherId);
      if (remote != null) return remote;
      // Запись в lessons не найдена — создаём по текущему слоту расписания.
      return await _createLessonFromCurrentSchedule(teacherId);
    } catch (e) {
      AppLogger.error('getCurrentLessonForTeacher: ошибка', e, null, 'LessonRepository');
      return null;
    }
  }

  /// Берёт текущий слот из Drift (расписание уже синхронизировано при входе),
  /// создаёт запись lesson в Supabase + локально и возвращает LessonModel.
  Future<LessonModel?> _createLessonFromCurrentSchedule(String teacherId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final nowTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

    final row = await (_db.select(_db.schedules).join([
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

    if (row == null) return null;

    final schedule = row.readTable(_db.schedules);
    final subject  = row.readTable(_db.subjects);
    final teacher  = row.readTable(_db.teachers);
    final group    = row.readTable(_db.groups);

    final lessonId = const Uuid().v4();

    try {
      await BaseService.client.from('lessons').insert({
        'id': lessonId,
        'schedule_id': schedule.id,
        'topic': null,
        'attendance_status': 'free',
      });
    } catch (e) {
      // Гонка: другой клиент уже вставил запись — повторно пробуем получить.
      AppLogger.warning('_createLessonFromCurrentSchedule: insert conflict', 'LessonRepository');
      return await LessonService.getCurrentLessonForTeacher(teacherId);
    }

    await _dao.upsertLesson(
      id: lessonId,
      scheduleId: schedule.id,
      attendanceStatus: LessonAttendanceStatus.free.toDbValue,
    );

    final date =
        '${schedule.date.year}-'
        '${schedule.date.month.toString().padLeft(2, '0')}-'
        '${schedule.date.day.toString().padLeft(2, '0')}';

    AppLogger.info('Создан lesson $lessonId для schedule ${schedule.id}', 'LessonRepository');

    return LessonModel(
      id: lessonId,
      date: date,
      startTime: schedule.startTime,
      endTime: schedule.endTime,
      groupId: schedule.groupId,
      groupName: group.name,
      subjectName: subject.name,
      teacherName: teacher.name,
      teacherSurname: teacher.surname,
      status: LessonAttendanceStatus.free,
    );
  }

  /// Реактивный Drift-стрим текущего или следующего урока преподавателя.
  /// Переиздаётся при любом INSERT/UPDATE в таблицах lessons/schedules.
  Stream<LessonModel?> watchCurrentOrNextLessonForTeacher(String teacherId) =>
      _dao.watchCurrentOrNextForTeacher(teacherId);

  /// Realtime → Drift: получает сырые строки из Supabase, сохраняет локально
  /// и возвращает данные вызывающей стороне для проверки изменений статуса.
  /// Один канал вместо двух (заменяет бывший watchStatus).
  Stream<List<Map<String, dynamic>>> watchLessonsRealtime() =>
      BaseService.client
          .from('lessons')
          .stream(primaryKey: ['id'])
          .asyncMap((raw) async {
            await _upsertLessonsFromRaw(raw);
            return raw;
          });

  Future<void> _upsertLessonsFromRaw(List<Map<String, dynamic>> raw) async {
    if (raw.isEmpty) return;

    // Фильтруем только уроки из расписания текущего пользователя —
    // stream() не поддерживает inFilter, поэтому отсекаем чужие записи здесь.
    final knownScheduleIds = (await _db.select(_db.schedules).get())
        .map((s) => s.id)
        .toSet();

    final relevant = raw
        .where((row) => knownScheduleIds.contains(row['schedule_id'] as String?))
        .toList();

    if (relevant.isEmpty) return;

    await _db.batch((b) {
      b.insertAllOnConflictUpdate(
        _db.lessons,
        relevant.map(
          (row) => LessonsCompanion.insert(
            id: row['id'] as String,
            scheduleId: row['schedule_id'] as String,
            topic: Value(row['topic'] as String?),
            attendanceStatus: row['attendance_status'] as String? ?? 'free',
          ),
        ).toList(),
      );
    });
  }

  /// Реактивный стрим всех прошедших занятий преподавателя (дата < сегодня).
  Stream<List<LessonModel>> watchPastLessonsForTeacher(String teacherId) =>
      _dao.watchPastForTeacher(teacherId);

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

  /// Сохраняет тему занятия: сначала локально, затем best-effort в Supabase.
  Future<void> updateTopic(String lessonId, String? topic) async {
    await _dao.upsertTopic(lessonId, topic);
    try {
      await BaseService.client
          .from('lessons')
          .update({'topic': topic})
          .eq('id', lessonId);
    } catch (_) {}
  }

  /// Запрашивает актуальный статус из Supabase (только онлайн).
  Future<LessonAttendanceStatus> getFreshStatus(String lessonId) =>
      LessonService.getFreshStatus(lessonId);
}
