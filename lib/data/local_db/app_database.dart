import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// --- Ядро ---
class Institutions extends Table {
  TextColumn get id => text()(); // UUID
  TextColumn get name => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class Teachers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get surname => text()();
  TextColumn get department => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Groups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get institutionId => text().references(Institutions, #id)();
  TextColumn get curatorId => text().nullable().references(Teachers, #id)();
  @override
  Set<Column> get primaryKey => {id};
}

class Students extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get surname => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  BoolColumn get isHeadman => boolean()(); // isheadman в БД
  @override
  Set<Column> get primaryKey => {id};
}

class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get institutionId => text().references(Institutions, #id)();
  TextColumn get name => text()();
  @override
  Set<Column> get primaryKey => {id};
}

// --- Учебный процесс ---
class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get institutionId => text().references(Institutions, #id)();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get groupId => text().references(Groups, #id)();
  TextColumn get startTime => text()(); // time в SQL -> text в Drift
  TextColumn get endTime => text()();
  TextColumn get teacherId => text().references(Teachers, #id)();
  DateTimeColumn get date => dateTime()();
  IntColumn get weekday => integer()();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get scheduleId => text().references(Schedules, #id)();
  TextColumn get topic => text().nullable()();
  TextColumn get attendanceStatus => text()(); // статус ведомости
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class LessonAttendances extends Table {
  TextColumn get id => text()();
  TextColumn get lessonId => text().references(Lessons, #id)();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get status => text().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  // Время последнего локального изменения (для conflict resolution)
  DateTimeColumn get updatedAt => dateTime().nullable()();
  // Время изменения на сервере Supabase — используется для delta sync
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  // null = не рассмотрено, true = уважительная, false = неуважительная
  BoolColumn get isExcused => boolean().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

// --- Объяснительные ---
class ExcuseRequests extends Table {
  TextColumn get id => text()();
  TextColumn get lessonId => text().references(Lessons, #id)();
  TextColumn get studentId => text().references(Students, #id)();
  // illness / family / transport / event / other
  TextColumn get reasonType => text()();
  TextColumn get description => text().nullable()();
  // pending / approved / rejected
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get reviewedBy => text().nullable()(); // teacher_id
  DateTimeColumn get reviewedAt => dateTime().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Institutions,
    Teachers,
    Groups,
    Students,
    Subjects,
    Schedules,
    Lessons,
    LessonAttendances,
    ExcuseRequests,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'edu_att_local_db'));

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement(
          'ALTER TABLE lesson_attendances ADD COLUMN updated_at INTEGER',
        );
      }
      if (from < 3) {
        await customStatement(
          'ALTER TABLE lesson_attendances ADD COLUMN server_updated_at INTEGER',
        );
      }
      if (from < 4) {
        await customStatement(
          'ALTER TABLE schedules ADD COLUMN server_updated_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE lessons ADD COLUMN server_updated_at INTEGER',
        );
      }
      if (from < 5) {
        await customStatement(
          'ALTER TABLE lesson_attendances ADD COLUMN is_excused INTEGER',
        );
        await customStatement('''
          CREATE TABLE IF NOT EXISTS excuse_requests (
            id TEXT NOT NULL PRIMARY KEY,
            lesson_id TEXT NOT NULL REFERENCES lessons(id),
            student_id TEXT NOT NULL REFERENCES students(id),
            reason_type TEXT NOT NULL,
            description TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            created_at INTEGER NOT NULL,
            reviewed_by TEXT,
            reviewed_at INTEGER,
            is_synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      }
    },
  );

  /// Удаляет все локальные данные в порядке, обратном FK-зависимостям.
  Future<void> clearAllData() => transaction(() async {
    await customStatement('DELETE FROM excuse_requests');
    await delete(lessonAttendances).go();
    await delete(lessons).go();
    await delete(schedules).go();
    await delete(students).go();
    await delete(groups).go();
    await delete(subjects).go();
    await delete(teachers).go();
    await delete(institutions).go();
  });
}
