import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/models/teacher_model.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/providers/personal_mode_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonalModeService {
  // ── Сентинельные ID для всех записей личного режима ───────────────────────
  static const String kInstitutionId = 'personal';
  static const String kTeacherId = 'personal_teacher';
  static const String kDefaultGroupId = 'personal_group';
  static const String kDefaultStudentId = 'personal_student';

  final AppDatabase _db;

  PersonalModeService(this._db);

  // ── Инициализация БД ──────────────────────────────────────────────────────

  /// Создаёт базовые записи в Drift. Idempotent — можно вызывать повторно.
  Future<void> initializeIfNeeded(PersonalRole role) async {
    await _db.transaction(() async {
      // Учреждение
      await _db.into(_db.institutions).insertOnConflictUpdate(
            InstitutionsCompanion.insert(
              id: kInstitutionId,
              name: 'Личный режим',
            ),
          );

      // Преподаватель (нужен всегда — как владелец расписания)
      await _db.into(_db.teachers).insertOnConflictUpdate(
            TeachersCompanion.insert(
              id: kTeacherId,
              name: 'Личный',
              surname: 'режим',
            ),
          );

      if (role != PersonalRole.teacher) {
        // Группа по умолчанию для студента/старосты
        await _db.into(_db.groups).insertOnConflictUpdate(
              GroupsCompanion(
                id: const Value(kDefaultGroupId),
                institutionId: const Value(kInstitutionId),
                name: const Value('Моя группа'),
              ),
            );

        // Профиль студента/старосты
        await _db.into(_db.students).insertOnConflictUpdate(
              StudentsCompanion.insert(
                id: kDefaultStudentId,
                name: 'Я',
                surname: 'Студент',
                groupId: kDefaultGroupId,
                isHeadman: role == PersonalRole.headman,
              ),
            );
      }
    });
  }

  // ── Модели для провайдеров ────────────────────────────────────────────────

  StudentModel buildStudentModel(PersonalRole role) => StudentModel(
        id: kDefaultStudentId,
        name: 'Я',
        surname: 'Студент',
        groupId: kDefaultGroupId,
        groupName: 'Моя группа',
        isHeadman: role == PersonalRole.headman,
        institution_id: kInstitutionId,
      );

  TeacherModel buildTeacherModel() => TeacherModel(
        id: kTeacherId,
        institutionId: kInstitutionId,
        name: 'Личный',
        surname: 'режим',
        email: '',
        password: '',
        login: '',
        createdAt: DateTime.now(),
      );

  // ── Вспомогательные запросы ───────────────────────────────────────────────

  Future<List<Subject>> getSubjects() =>
      (_db.select(_db.subjects)
            ..where((s) => s.institutionId.equals(kInstitutionId))
            ..orderBy([(s) => OrderingTerm.asc(s.name)]))
          .get();

  Future<List<Group>> getGroups() =>
      (_db.select(_db.groups)
            ..where((g) => g.institutionId.equals(kInstitutionId))
            ..orderBy([(g) => OrderingTerm.asc(g.name)]))
          .get();

  Future<List<Student>> getStudentsForGroup(String groupId) =>
      (_db.select(_db.students)
            ..where((s) => s.groupId.equals(groupId))
            ..orderBy([(s) => OrderingTerm.asc(s.surname)]))
          .get();

  // ── CRUD субъектов ────────────────────────────────────────────────────────

  Future<void> insertSubject(String id, String name) =>
      _db.into(_db.subjects).insert(
            SubjectsCompanion.insert(
              id: id,
              institutionId: kInstitutionId,
              name: name,
            ),
          );

  Future<void> deleteSubject(String id) =>
      (_db.delete(_db.subjects)..where((s) => s.id.equals(id))).go();

  // ── CRUD групп ────────────────────────────────────────────────────────────

  Future<void> insertGroup(String id, String name) =>
      _db.into(_db.groups).insert(
            GroupsCompanion(
              id: Value(id),
              institutionId: const Value(kInstitutionId),
              name: Value(name),
            ),
          );

  Future<void> deleteGroup(String id) async {
    // Удаляем студентов группы (посещаемость каскадно не удалится без ON DELETE CASCADE,
    // поэтому сначала чистим вручную)
    final students = await getStudentsForGroup(id);
    for (final s in students) {
      await deleteStudent(s.id);
    }
    await (_db.delete(_db.groups)..where((g) => g.id.equals(id))).go();
  }

  // ── CRUD студентов ────────────────────────────────────────────────────────

  Future<void> insertStudent({
    required String id,
    required String name,
    required String surname,
    required String groupId,
    bool isHeadman = false,
  }) =>
      _db.into(_db.students).insert(
            StudentsCompanion.insert(
              id: id,
              name: name,
              surname: surname,
              groupId: groupId,
              isHeadman: isHeadman,
            ),
          );

  Future<void> deleteStudent(String id) async {
    // Снимаем ссылки посещаемости
    await (_db.delete(_db.lessonAttendances)
          ..where((a) => a.studentId.equals(id)))
        .go();
    await (_db.delete(_db.students)..where((s) => s.id.equals(id))).go();
  }

  // ── CRUD расписания ───────────────────────────────────────────────────────

  /// Создаёт запись расписания и соответствующий урок (status = 'free').
  Future<void> insertScheduleWithLesson({
    required String scheduleId,
    required String lessonId,
    required String subjectId,
    required String groupId,
    required DateTime date,
    required String startTime,
    required String endTime,
  }) =>
      _db.transaction(() async {
        await _db.into(_db.schedules).insert(
              SchedulesCompanion.insert(
                id: scheduleId,
                institutionId: kInstitutionId,
                subjectId: subjectId,
                groupId: groupId,
                startTime: startTime,
                endTime: endTime,
                teacherId: kTeacherId,
                date: date,
                weekday: date.weekday,
              ),
            );

        await _db.into(_db.lessons).insert(
              LessonsCompanion.insert(
                id: lessonId,
                scheduleId: scheduleId,
                attendanceStatus: 'free',
              ),
            );
      });

  Future<void> deleteSchedule(String scheduleId) async {
    // Удаляем уроки и их посещаемость
    final lessonRows = await (_db.select(_db.lessons)
          ..where((l) => l.scheduleId.equals(scheduleId)))
        .get();
    for (final l in lessonRows) {
      await (_db.delete(_db.lessonAttendances)
            ..where((a) => a.lessonId.equals(l.id)))
          .go();
    }
    await (_db.delete(_db.lessons)
          ..where((l) => l.scheduleId.equals(scheduleId)))
        .go();
    await (_db.delete(_db.schedules)..where((s) => s.id.equals(scheduleId)))
        .go();
  }
}

final personalModeServiceProvider = Provider<PersonalModeService>(
  (ref) => PersonalModeService(ref.watch(appDatabaseProvider)),
);
