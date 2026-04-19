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
  @override
  Set<Column> get primaryKey => {id};
}

class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get scheduleId => text().references(Schedules, #id)();
  TextColumn get topic => text().nullable()();
  TextColumn get attendanceStatus => text()(); // статус ведомости
  @override
  Set<Column> get primaryKey => {id};
}

class LessonAttendances extends Table {
  TextColumn get id => text()();
  TextColumn get lessonId => text().references(Lessons, #id)();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get status => text().nullable()();
  // Добавляем поле для оффлайн-логики
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'edu_att_local_db'));

  @override
  int get schemaVersion => 1;
}
