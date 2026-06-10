import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/utils/app_logger.dart';

class ExcuseService extends BaseService {
  static Future<void> submit(Map<String, dynamic> json) async {
    try {
      await BaseService.client.from('excuse_requests').upsert(
        json,
        onConflict: 'lesson_id,student_id',
      );
    } catch (e) {
      AppLogger.warning('ExcuseService.submit: $e', 'ExcuseService');
      rethrow;
    }
  }

  static Future<void> updateStatus({
    required String excuseId,
    required String status,
    required String reviewedBy,
    required String reviewedAt,
  }) async {
    await BaseService.client.from('excuse_requests').update({
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt,
    }).eq('id', excuseId);
  }

  static Future<void> updateAttendanceExcused({
    required String attendanceId,
    required bool isExcused,
  }) async {
    await BaseService.client
        .from('lesson_attendances')
        .update({'is_excused': isExcused})
        .eq('id', attendanceId);
  }

  static Future<List<Map<String, dynamic>>> getForLesson(
    String lessonId,
  ) async {
    final response = await BaseService.client
        .from('excuse_requests')
        .select('id, lesson_id, student_id, reason_type, description, status, created_at, reviewed_by, reviewed_at')
        .eq('lesson_id', lessonId);
    return (response as List).cast<Map<String, dynamic>>();
  }

  static Future<List<Map<String, dynamic>>> getForStudent(
    String studentId,
  ) async {
    final response = await BaseService.client
        .from('excuse_requests')
        .select('id, lesson_id, student_id, reason_type, description, status, created_at, reviewed_by, reviewed_at')
        .eq('student_id', studentId);
    return (response as List).cast<Map<String, dynamic>>();
  }
}
