import 'package:edu_att/models/lesson_attendance_model.dart';

abstract class IAttendanceRepository {
  /// Загружает посещаемость урока: сначала из локальной БД, при её отсутствии — из Supabase.
  Future<List<LessonAttendanceModel>> getForLesson(String lessonId);

  /// Сохраняет записи локально с флагом isSynced = false.
  Future<void> saveLocally(List<LessonAttendanceModel> attendances);

  /// Отправляет все несинхронизированные записи в Supabase и помечает их как synced.
  Future<void> syncToRemote();

  /// Realtime-поток изменений посещаемости из Supabase (для экрана преподавателя).
  Stream<List<Map<String, dynamic>>> watchLesson(String lessonId);

  /// Реактивный Drift-стрим посещаемости студента с данными о предмете/учителе.
  Stream<List<LessonAttendanceModel>> watchStudentAttendance(String studentId);

  /// Delta sync: скачивает из Supabase только записи, изменённые после последней синхронизации.
  Future<void> syncDelta(String studentId);

  /// Записывает данные из Supabase (real-time или delta) в локальную БД.
  Future<void> upsertFromRemote(List<Map<String, dynamic>> raw);

  /// Отмечает студента присутствующим самостоятельно.
  Future<void> markSelfPresent({required String lessonId, required String studentId});

  /// Realtime-поток посещаемости студента из Supabase (для синхронизации в Drift).
  Stream<List<Map<String, dynamic>>> watchRemoteStudent(String studentId);

  /// Возвращает данные посещаемости группы за неделю.
  Future<List<LessonAttendanceModel>> getWeeklyGroupAttendance({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Возвращает посещаемость группы за произвольный диапазон дат из локальной БД.
  Future<List<LessonAttendanceModel>> getGroupAttendanceInRange({
    required String groupId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
