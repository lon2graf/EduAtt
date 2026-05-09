import 'dart:async';

import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentServices extends BaseService {
  /// Returns null for wrong credentials; throws on network errors (offline).
  static Future<StudentModel?> loginStudent(
    String institutionId,
    String email,
    String password,
  ) async {
    try {
      final response = await BaseService.client
          .from('students')
          .select('''
      id,
      name,
      surname,
      email,
      login,
      group_id,
      isheadman,
      groups!inner (name, institution_id)
    ''')
          .eq('email', email)
          .eq('password', password)
          .eq('groups.institution_id', institutionId)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      if (response == null) return null;
      return StudentModel.fromJson(response);
    } on PostgrestException catch (e) {
      AppLogger.warning('loginStudent: ${e.message}', 'StudentService');
      return null;
    }
    // SocketException / TimeoutException bubble up to caller for offline fallback
  }

  static Future<List<StudentModel>> getStudentsByGroupId(String groupId) async {
    try {
      final response = await BaseService.client
          .from('students')
          .select('''
        id,
        name,
        surname,
        group_id,
        isheadman
      ''')
          .eq('group_id', groupId);

      AppLogger.debug('Запрос студентов группы: $groupId', 'StudentService');
      AppLogger.debug('Ответ БД: ${response.length} студентов', 'StudentService');

      return (response as List)
          .map((item) => StudentModel.fromJson(item))
          .toList();
    } on PostgrestException catch (e) {
      AppLogger.warning('getStudentsByGroupId: ${e.message}', 'StudentService');
      return [];
    } catch (e) {
      AppLogger.error('getStudentsByGroupId', e, null, 'StudentService');
      return [];
    }
  }
}
