import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Institutions extends Table {
  TextColumn get id => text()();
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
  TextColumn get curatorId => text().nullable().references(Teachers, #id)();
  @override
  Set<Column> get primaryKey => {id};
}

class Students extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get surname => text()();
  TextColumn get groupId => text().references(Groups, #id)();
  BoolColumn get isHeadman => boolean().withDefault(const Constant(false))();
  @override
  Set<Column> get primaryKey => {id};
}

class Lessons extends Table {
  TextColumn get id => text()();
  TextColumn get subjectName => text()();
  TextColumn get teacherName => text()();
  TextColumn get groupId => text()();
  TextColumn get attendanceStatus => text()();
  @override
  Set<Column> get primaryKey => {id};
}

class LessonAttendances extends Table {
  TextColumn get id => text()();
  TextColumn get lessonId => text().references(Lessons, #id)();
  TextColumn get studentId => text().references(Students, #id)();
  TextColumn get status => text().nullable()();
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
    Lessons,
    LessonAttendances,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'edu_att_local_db'));

  @override
  int get schemaVersion => 1;
}
