import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/models/teacher_model.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:edu_att/utils/data_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InitialSyncService {
  final AppDatabase _db;

  InitialSyncService(this._db);

  Future<DataResult<void>> syncAll({
    required StudentModel student,
    void Function(String message)? onProgress,
  }) async {
    try {
      final institutionId = student.institution_id;
      if (institutionId == null) {
        return const Failure('ID учреждения не найден в профиле студента');
      }

      await _db.clearAllData();

      onProgress?.call('Загрузка учреждения...');
      await _syncInstitution(institutionId);

      onProgress?.call('Загрузка преподавателей...');
      await _syncTeachers(institutionId);

      onProgress?.call('Загрузка предметов...');
      await _syncSubjects(institutionId);

      onProgress?.call('Загрузка группы...');
      await _syncGroup(student.groupId);

      onProgress?.call('Загрузка студентов группы...');
      await _syncStudents(student.groupId);

      onProgress?.call('Загрузка расписания...');
      await _syncSchedules(student.groupId, institutionId);

      onProgress?.call('Загрузка уроков...');
      await _syncLessons(student.groupId);

      onProgress?.call('Загрузка посещаемости...');
      await _syncAttendances(student.id!);

      AppLogger.info('Начальная синхронизация завершена', 'InitialSyncService');
      return const Success(null);
    } catch (e, st) {
      AppLogger.error('Ошибка начальной синхронизации', e, st, 'InitialSyncService');
      try {
        await _db.clearAllData();
      } catch (_) {}
      return Failure(e.toString(), e);
    }
  }

  Future<void> _syncInstitution(String institutionId) async {
    final row = await BaseService.client
        .from('institutions')
        .select('id, name')
        .eq('id', institutionId)
        .single();

    await _db.into(_db.institutions).insertOnConflictUpdate(
      InstitutionsCompanion.insert(
        id: row['id'] as String,
        name: row['name'] as String,
      ),
    );
  }

  Future<void> _syncTeachers(String institutionId) async {
    final response = await BaseService.client
        .from('teachers')
        .select('id, name, surname, department')
        .eq('institution_id', institutionId);

    await _db.batch((b) {
      b.insertAll(
        _db.teachers,
        (response as List).cast<Map<String, dynamic>>().map(
          (row) => TeachersCompanion.insert(
            id: row['id'] as String,
            name: row['name'] as String,
            surname: row['surname'] as String,
            department: Value(row['department'] as String?),
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> _syncSubjects(String institutionId) async {
    final response = await BaseService.client
        .from('subjects')
        .select('id, institution_id, name')
        .eq('institution_id', institutionId);

    await _db.batch((b) {
      b.insertAll(
        _db.subjects,
        (response as List).cast<Map<String, dynamic>>().map(
          (row) => SubjectsCompanion.insert(
            id: row['id'] as String,
            institutionId: row['institution_id'] as String,
            name: row['name'] as String,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> _syncGroup(String groupId) async {
    final row = await BaseService.client
        .from('groups')
        .select('id, name, institution_id, curator_id')
        .eq('id', groupId)
        .single();

    await _db.into(_db.groups).insertOnConflictUpdate(
      GroupsCompanion.insert(
        id: row['id'] as String,
        name: row['name'] as String,
        institutionId: row['institution_id'] as String,
        curatorId: Value(row['curator_id'] as String?),
      ),
    );
  }

  Future<void> _syncStudents(String groupId) async {
    final response = await BaseService.client
        .from('students')
        .select('id, name, surname, group_id, isheadman')
        .eq('group_id', groupId);

    await _db.batch((b) {
      b.insertAll(
        _db.students,
        (response as List).cast<Map<String, dynamic>>().map(
          (row) => StudentsCompanion.insert(
            id: row['id'] as String,
            name: row['name'] as String,
            surname: row['surname'] as String,
            groupId: row['group_id'] as String,
            isHeadman: row['isheadman'] as bool,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> _syncSchedules(String groupId, String institutionId) async {
    final response = await BaseService.client
        .from('schedule')
        .select(
          'id, institution_id, subject_id, group_id, start_time, end_time, teacher_id, date, weekday',
        )
        .eq('group_id', groupId);

    await _db.batch((b) {
      b.insertAll(
        _db.schedules,
        (response as List).cast<Map<String, dynamic>>().map(
          (row) => SchedulesCompanion.insert(
            id: row['id'] as String,
            institutionId: row['institution_id'] as String,
            subjectId: row['subject_id'] as String,
            groupId: row['group_id'] as String,
            startTime: row['start_time'] as String,
            endTime: row['end_time'] as String,
            teacherId: row['teacher_id'] as String,
            date: DateTime.parse(row['date'] as String),
            weekday: row['weekday'] as int,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> _syncLessons(String groupId) async {
    final response = await BaseService.client
        .from('lessons')
        .select('id, schedule_id, topic, attendance_status, schedule!inner(group_id)')
        .eq('schedule.group_id', groupId);

    await _db.batch((b) {
      b.insertAll(
        _db.lessons,
        (response as List).cast<Map<String, dynamic>>().map(
          (row) => LessonsCompanion.insert(
            id: row['id'] as String,
            scheduleId: row['schedule_id'] as String,
            topic: Value(row['topic'] as String?),
            attendanceStatus: row['attendance_status'] as String,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  // ─── Teacher sync ────────────────────────────────────────────────────────────

  Future<DataResult<void>> syncAllForTeacher({
    required TeacherModel teacher,
    void Function(String message)? onProgress,
  }) async {
    try {
      final institutionId = teacher.institutionId;
      final teacherId = teacher.id!;

      await _db.clearAllData();

      onProgress?.call('Загрузка учреждения...');
      await _syncInstitution(institutionId);

      onProgress?.call('Загрузка преподавателей...');
      await _syncTeachers(institutionId);

      onProgress?.call('Загрузка предметов...');
      await _syncSubjects(institutionId);

      onProgress?.call('Загрузка групп...');
      await _syncGroupsForInstitution(institutionId);

      onProgress?.call('Загрузка студентов...');
      await _syncStudentsForInstitution(institutionId);

      onProgress?.call('Загрузка расписания...');
      await _syncSchedulesForTeacher(teacherId, institutionId);

      onProgress?.call('Загрузка уроков...');
      await _syncLessonsForTeacher(teacherId);

      AppLogger.info(
        'Начальная синхронизация преподавателя завершена',
        'InitialSyncService',
      );
      return const Success(null);
    } catch (e, st) {
      AppLogger.error(
        'Ошибка синхронизации преподавателя',
        e,
        st,
        'InitialSyncService',
      );
      try {
        await _db.clearAllData();
      } catch (_) {}
      return Failure(e.toString(), e);
    }
  }

  Future<void> _syncGroupsForInstitution(String institutionId) async {
    final response = await BaseService.client
        .from('groups')
        .select('id, name, institution_id, curator_id')
        .eq('institution_id', institutionId);

    await _db.batch((b) {
      b.insertAll(
        _db.groups,
        (response as List).cast<Map<String, dynamic>>().map(
          (row) => GroupsCompanion.insert(
            id: row['id'] as String,
            name: row['name'] as String,
            institutionId: row['institution_id'] as String,
            curatorId: Value(row['curator_id'] as String?),
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// Скачивает всех студентов учреждения одним запросом через JOIN.
  Future<void> _syncStudentsForInstitution(String institutionId) async {
    final response = await BaseService.client
        .from('students')
        .select('id, name, surname, group_id, isheadman, groups!inner(institution_id)')
        .eq('groups.institution_id', institutionId);

    await _db.batch((b) {
      b.insertAll(
        _db.students,
        (response as List).cast<Map<String, dynamic>>().map(
          (row) => StudentsCompanion.insert(
            id: row['id'] as String,
            name: row['name'] as String,
            surname: row['surname'] as String,
            groupId: row['group_id'] as String,
            isHeadman: row['isheadman'] as bool,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> _syncSchedulesForTeacher(
    String teacherId,
    String institutionId,
  ) async {
    final response = await BaseService.client
        .from('schedule')
        .select(
          'id, institution_id, subject_id, group_id, start_time, end_time, teacher_id, date, weekday',
        )
        .eq('teacher_id', teacherId);

    await _db.batch((b) {
      b.insertAll(
        _db.schedules,
        (response as List).cast<Map<String, dynamic>>().map(
          (row) => SchedulesCompanion.insert(
            id: row['id'] as String,
            institutionId: row['institution_id'] as String,
            subjectId: row['subject_id'] as String,
            groupId: row['group_id'] as String,
            startTime: row['start_time'] as String,
            endTime: row['end_time'] as String,
            teacherId: row['teacher_id'] as String,
            date: DateTime.parse(row['date'] as String),
            weekday: row['weekday'] as int,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> _syncLessonsForTeacher(String teacherId) async {
    final response = await BaseService.client
        .from('lessons')
        .select(
          'id, schedule_id, topic, attendance_status, schedule!inner(teacher_id)',
        )
        .eq('schedule.teacher_id', teacherId);

    await _db.batch((b) {
      b.insertAll(
        _db.lessons,
        (response as List).cast<Map<String, dynamic>>().map(
          (row) => LessonsCompanion.insert(
            id: row['id'] as String,
            scheduleId: row['schedule_id'] as String,
            topic: Value(row['topic'] as String?),
            attendanceStatus: row['attendance_status'] as String,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> _syncAttendances(String studentId) async {
    final response = await BaseService.client
        .from('lesson_attendances')
        .select('id, lesson_id, student_id, status')
        .eq('student_id', studentId);

    await _db.batch((b) {
      b.insertAll(
        _db.lessonAttendances,
        (response as List).cast<Map<String, dynamic>>().map(
          (row) => LessonAttendancesCompanion.insert(
            id: row['id'] as String,
            lessonId: row['lesson_id'] as String,
            studentId: row['student_id'] as String,
            status: Value(row['status'] as String?),
            isSynced: const Value(true),
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }
}

final initialSyncServiceProvider = Provider<InitialSyncService>(
  (ref) => InitialSyncService(ref.watch(appDatabaseProvider)),
);
