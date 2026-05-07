import 'package:edu_att/models/lesson_attendance_model.dart';

abstract class IAttendanceRepository {
  /// Загружает посещаемость урока: сначала из локальной БД, при её отсутствии — из Supabase.
  Future<List<LessonAttendanceModel>> getForLesson(String lessonId);

  /// Сохраняет записи локально с флагом isSynced = false.
  Future<void> saveLocally(List<LessonAttendanceModel> attendances);

  /// Отправляет все несинхронизированные записи в Supabase и помечает их как synced.
  Future<void> syncToRemote();

  /// Realtime-поток изменений посещаемости из Supabase.
  Stream<List<Map<String, dynamic>>> watchLesson(String lessonId);
}
