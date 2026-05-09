import 'dart:async';
import 'dart:io';

import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/services/initial_sync_service.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/data/remote/student_service.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:edu_att/utils/data_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:flutter_riverpod/legacy.dart';
import 'package:edu_att/data/remote/shared_preferences_service.dart';

final offlineModeProvider = StateProvider<bool>((ref) => false);

final currentStudentProvider =
    StateNotifierProvider<StudentNotifier, StudentModel?>(
      (ref) => StudentNotifier(
        ref.watch(initialSyncServiceProvider),
        ref.watch(appDatabaseProvider),
        ref,
      ),
    );

class StudentNotifier extends StateNotifier<StudentModel?> {
  final InitialSyncService _syncService;
  final AppDatabase _db;
  final Ref _ref;

  StudentNotifier(this._syncService, this._db, this._ref) : super(null);

  /// Called on app startup. Loads from Drift instantly if possible,
  /// then syncs in background. Falls through to online login if no local data.
  Future<bool> autoLogin({
    required String institutionId,
    required String email,
    required String password,
  }) async {
    final studentId = await SharedPreferencesService.getStudentId();
    if (studentId != null) {
      final driftStudent = await _loadStudentFromDrift(studentId);
      if (driftStudent != null) {
        state = driftStudent;
        _ref.read(offlineModeProvider.notifier).state = true;
        _backgroundAuthCheck(institutionId, email, password);
        return true;
      }
    }
    return login(institutionId, email, password);
  }

  Future<bool> login(
    String institutionId,
    String email,
    String password, {
    void Function(String message)? onProgress,
  }) async {
    try {
      final student = await StudentServices.loginStudent(
        institutionId,
        email,
        password,
      );
      if (student == null) return false;

      final syncResult = await _syncService.syncAll(
        student: student,
        onProgress: onProgress,
      );

      if (syncResult is Failure) {
        AppLogger.warning(
          'Начальная синхронизация не удалась',
          'StudentNotifier',
        );
      }

      state = student;
      _ref.read(offlineModeProvider.notifier).state = false;
      await SharedPreferencesService.saveStudentCredentials(
        login: email,
        password: password,
        institutionId: institutionId,
      );
      await SharedPreferencesService.saveStudentId(student.id!);
      return true;
    } on SocketException {
      return _tryOfflineLogin(institutionId, email, password);
    } on TimeoutException {
      return _tryOfflineLogin(institutionId, email, password);
    } catch (e) {
      AppLogger.error('Ошибка при логине студента', e, null, 'StudentNotifier');
      return false;
    }
  }

  Future<void> logout() async {
    state = null;
    _ref.read(offlineModeProvider.notifier).state = false;
    await _db.clearAllData();
    await SharedPreferencesService.clearAllData();
  }

  bool get isLoggined => state != null;

  /// Validates credentials against saved SharedPreferences, then loads from Drift.
  Future<bool> _tryOfflineLogin(
    String institutionId,
    String email,
    String password,
  ) async {
    try {
      final saved = await SharedPreferencesService.getStudentCredentials();
      if (saved == null) return false;
      if (saved['login'] != email ||
          saved['password'] != password ||
          saved['institutionId'] != institutionId) {
        return false;
      }

      final studentId = await SharedPreferencesService.getStudentId();
      if (studentId == null) return false;

      final driftStudent = await _loadStudentFromDrift(studentId);
      if (driftStudent == null) return false;

      state = driftStudent;
      _ref.read(offlineModeProvider.notifier).state = true;
      return true;
    } catch (e) {
      AppLogger.error('Ошибка оффлайн-входа', e, null, 'StudentNotifier');
      return false;
    }
  }

  Future<StudentModel?> _loadStudentFromDrift(String studentId) async {
    try {
      final studentRow = await (_db.select(_db.students)
            ..where((s) => s.id.equals(studentId)))
          .getSingleOrNull();
      if (studentRow == null) return null;

      final groupRow = await (_db.select(_db.groups)
            ..where((g) => g.id.equals(studentRow.groupId)))
          .getSingleOrNull();

      return StudentModel(
        id: studentRow.id,
        name: studentRow.name,
        surname: studentRow.surname,
        groupId: studentRow.groupId,
        groupName: groupRow?.name,
        isHeadman: studentRow.isHeadman,
        institution_id: groupRow?.institutionId,
      );
    } catch (e) {
      AppLogger.error(
        'Ошибка загрузки студента из Drift',
        e,
        null,
        'StudentNotifier',
      );
      return null;
    }
  }

  /// Verifies credentials online without clearing the DB.
  /// On success, clears offline mode so the UI updates.
  void _backgroundAuthCheck(
    String institutionId,
    String email,
    String password,
  ) {
    StudentServices.loginStudent(institutionId, email, password)
        .timeout(const Duration(seconds: 30))
        .then((freshStudent) {
          if (freshStudent != null && mounted) {
            state = freshStudent;
            _ref.read(offlineModeProvider.notifier).state = false;
          }
        })
        .catchError((_) {});
  }
}
