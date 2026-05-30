import 'dart:async';
import 'dart:io';

import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/remote/shared_preferences_service.dart';
import 'package:edu_att/data/remote/teacher_service.dart';
import 'package:edu_att/data/services/initial_sync_service.dart';
import 'package:edu_att/models/teacher_model.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/providers/connectivity_provider.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:edu_att/utils/data_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final teacherProvider = StateNotifierProvider<TeacherNotifier, TeacherModel?>(
  (ref) => TeacherNotifier(
    ref.watch(initialSyncServiceProvider),
    ref.watch(appDatabaseProvider),
    ref,
  ),
);

class TeacherNotifier extends StateNotifier<TeacherModel?> {
  final InitialSyncService _syncService;
  final AppDatabase _db;
  final Ref _ref;

  TeacherNotifier(this._syncService, this._db, this._ref) : super(null);

  /// Вызывается при старте: мгновенный вход из Drift + фоновая проверка.
  Future<bool> autoLogin({
    required String email,
    required String password,
    required String institutionId,
  }) async {
    final teacherId = await SharedPreferencesService.getTeacherId();
    if (teacherId != null) {
      final driftTeacher = await _loadTeacherFromDrift(
        teacherId,
        institutionId,
        email,
        password,
      );
      if (driftTeacher != null) {
        state = driftTeacher;
        _ref.read(offlineModeProvider.notifier).state = true;
        _backgroundAuthCheck(email: email, password: password, institutionId: institutionId);
        return true;
      }
    }
    return loginTeacher(email: email, password: password, institutionId: institutionId);
  }

  Future<bool> loginTeacher({
    required String email,
    required String password,
    required String institutionId,
    void Function(String message)? onProgress,
  }) async {
    try {
      final teacher = await TeacherService.loginTeacher(
        email: email,
        password: password,
        institutionId: institutionId,
      );
      if (teacher == null) return false;

      final syncResult = await _syncService.syncAllForTeacher(
        teacher: teacher,
        onProgress: onProgress,
      );

      if (syncResult is Failure) {
        AppLogger.warning('Начальная синхронизация преподавателя не удалась', 'TeacherNotifier');
      }

      state = teacher;
      _ref.read(offlineModeProvider.notifier).state = false;

      await SharedPreferencesService.saveTeacherCredentials(
        login: email,
        password: password,
        institutionId: institutionId,
      );
      await SharedPreferencesService.saveTeacherId(teacher.id!);
      return true;
    } on SocketException {
      return _tryOfflineLogin(email: email, password: password, institutionId: institutionId);
    } on TimeoutException {
      return _tryOfflineLogin(email: email, password: password, institutionId: institutionId);
    } catch (e) {
      AppLogger.error('Ошибка при логине преподавателя', e, null, 'TeacherNotifier');
      return false;
    }
  }

  Future<void> logout() async {
    state = null;
    _ref.read(offlineModeProvider.notifier).state = false;
    await _db.clearAllData();
    await SharedPreferencesService.clearAllData();
  }

  /// Вход в личный режим без Supabase — устанавливает состояние из локальных данных.
  void loginPersonal(TeacherModel teacher) {
    state = teacher;
    _ref.read(offlineModeProvider.notifier).state = true;
  }

  bool get isLoggedIn => state != null;

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<TeacherModel?> _loadTeacherFromDrift(
    String teacherId,
    String institutionId,
    String email,
    String password,
  ) async {
    try {
      final row = await (_db.select(_db.teachers)
            ..where((t) => t.id.equals(teacherId)))
          .getSingleOrNull();
      if (row == null) return null;

      return TeacherModel(
        id: row.id,
        name: row.name,
        surname: row.surname,
        department: row.department,
        institutionId: institutionId,
        email: email,
        password: password,
        login: email,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      AppLogger.error('Ошибка загрузки преподавателя из Drift', e, null, 'TeacherNotifier');
      return null;
    }
  }

  Future<bool> _tryOfflineLogin({
    required String email,
    required String password,
    required String institutionId,
  }) async {
    try {
      final saved = await SharedPreferencesService.getTeacherCredentials();
      if (saved == null) return false;
      if (saved['login'] != email ||
          saved['password'] != password ||
          saved['institutionId'] != institutionId) {
        return false;
      }

      final teacherId = await SharedPreferencesService.getTeacherId();
      if (teacherId == null) return false;

      final driftTeacher = await _loadTeacherFromDrift(
        teacherId,
        institutionId,
        email,
        password,
      );
      if (driftTeacher == null) return false;

      state = driftTeacher;
      _ref.read(offlineModeProvider.notifier).state = true;
      return true;
    } catch (e) {
      AppLogger.error('Ошибка оффлайн-входа преподавателя', e, null, 'TeacherNotifier');
      return false;
    }
  }

  /// Проверяет сессию онлайн без сброса DB. При успехе снимает offline-флаг.
  void _backgroundAuthCheck({
    required String email,
    required String password,
    required String institutionId,
  }) {
    TeacherService.loginTeacher(email: email, password: password, institutionId: institutionId)
        .timeout(const Duration(seconds: 30))
        .then((fresh) {
          if (fresh != null && mounted) {
            state = fresh;
            _ref.read(offlineModeProvider.notifier).state = false;
          }
        })
        .catchError((_) {});
  }
}
