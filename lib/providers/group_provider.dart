import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/local_db/dao/student_dao.dart';
import 'package:edu_att/data/remote/student_service.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:flutter_riverpod/legacy.dart';

final groupStudentsProvider =
    StateNotifierProvider<GroupStudentsNotifier, List<StudentModel>>(
      (ref) => GroupStudentsNotifier(ref.watch(appDatabaseProvider)),
    );

class GroupStudentsNotifier extends StateNotifier<List<StudentModel>> {
  final StudentDao _dao;

  GroupStudentsNotifier(AppDatabase db)
    : _dao = StudentDao(db),
      super([]);

  /// Offline-first: Drift → Supabase (фоновый fallback при пустом кэше).
  Future<void> loadGroupStudents(String groupId) async {
    state = [];

    final cached = await _dao.getStudentsByGroup(groupId);
    if (cached.isNotEmpty) {
      state = cached.map(_fromDrift).toList();
      _backgroundRefresh(groupId);
      return;
    }

    // Кэш пуст — загружаем из Supabase и сохраняем в Drift
    try {
      final remote = await StudentServices.getStudentsByGroupId(groupId);
      if (remote.isNotEmpty) {
        await _dao.upsertAll(
          remote
              .map(
                (m) => StudentsCompanion.insert(
                  id: m.id!,
                  name: m.name,
                  surname: m.surname,
                  groupId: m.groupId,
                  isHeadman: m.isHeadman,
                ),
              )
              .toList(),
        );
      }
      state = remote;
    } catch (e) {
      AppLogger.error('loadGroupStudents: сеть недоступна', e, null, 'GroupStudentsNotifier');
      state = [];
    }
  }

  void clear() => state = [];

  List<StudentModel> getStudentsExcludingHeadman() =>
      state.where((s) => !s.isHeadman).toList();

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Обновляет кэш в фоне без изменения UI-состояния.
  void _backgroundRefresh(String groupId) {
    StudentServices.getStudentsByGroupId(groupId).then((remote) async {
      if (remote.isNotEmpty) {
        await _dao.upsertAll(
          remote
              .map(
                (m) => StudentsCompanion.insert(
                  id: m.id!,
                  name: m.name,
                  surname: m.surname,
                  groupId: m.groupId,
                  isHeadman: m.isHeadman,
                ),
              )
              .toList(),
        );
        if (mounted) state = remote;
      }
    }).catchError((_) {});
  }

  StudentModel _fromDrift(Student row) => StudentModel(
    id: row.id,
    name: row.name,
    surname: row.surname,
    groupId: row.groupId,
    isHeadman: row.isHeadman,
  );
}
