import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/local_db/dao/group_dao.dart';
import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/models/group_model.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GroupRepository {
  final GroupDao _dao;

  GroupRepository(AppDatabase db) : _dao = GroupDao(db);

  /// Реактивный стрим групп из локальной БД (SSoT для UI).
  Stream<List<GroupModel>> watchForInstitution(String institutionId) =>
      _dao.watchForInstitution(institutionId).map(
        (rows) => rows.map((r) => GroupModel(id: r.id, name: r.name)).toList(),
      );

  /// Синхронизирует группы учреждения из Supabase в Drift.
  Future<void> syncForInstitution(String institutionId) async {
    final response = await BaseService.client
        .from('groups')
        .select('id, name, institution_id, curator_id')
        .eq('institution_id', institutionId)
        .order('name', ascending: true);

    await _dao.upsertAll(
      (response as List).cast<Map<String, dynamic>>().map(
        (row) => GroupsCompanion.insert(
          id: row['id'] as String,
          name: row['name'] as String,
          institutionId: row['institution_id'] as String,
          curatorId: Value(row['curator_id'] as String?),
        ),
      ).toList(),
    );

    AppLogger.debug(
      'Синхронизировано ${response.length} групп для учреждения $institutionId',
      'GroupRepository',
    );
  }
}

final groupRepositoryProvider = Provider<GroupRepository>(
  (ref) => GroupRepository(ref.watch(appDatabaseProvider)),
);
