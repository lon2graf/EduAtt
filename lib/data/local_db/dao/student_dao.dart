import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';

class StudentDao {
  final AppDatabase _db;

  StudentDao(this._db);

  Future<void> upsertAll(List<StudentsCompanion> companions) =>
      _db.batch((b) => b.insertAllOnConflictUpdate(_db.students, companions));

  Future<List<Student>> getStudentsByGroup(String groupId) =>
      (_db.select(_db.students)
            ..where((s) => s.groupId.equals(groupId))
            ..orderBy([(s) => OrderingTerm.asc(s.surname)]))
          .get();
}
