import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';

class GroupDao {
  final AppDatabase _db;

  GroupDao(this._db);

  Stream<List<Group>> watchForInstitution(String institutionId) =>
      (_db.select(_db.groups)
            ..where((g) => g.institutionId.equals(institutionId))
            ..orderBy([(g) => OrderingTerm.asc(g.name)]))
          .watch();

  Future<void> upsertAll(List<GroupsCompanion> companions) =>
      _db.batch((b) => b.insertAllOnConflictUpdate(_db.groups, companions));
}
