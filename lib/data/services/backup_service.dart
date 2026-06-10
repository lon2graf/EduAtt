import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/remote/shared_preferences_service.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/providers/personal_mode_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  final AppDatabase _db;

  BackupService(this._db);

  // ── Экспорт ───────────────────────────────────────────────────────────────

  /// Возвращает путь к сохранённому файлу, либо null если пользователь отменил.
  Future<String?> exportToFile() async {
    final json = await _buildJson();
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    final now = DateTime.now();
    final fileName =
        'eduatt_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';

    return FilePicker.platform.saveFile(
      dialogTitle: 'Сохранить резервную копию',
      fileName: fileName,
      bytes: bytes,
    );
  }

  /// Открывает системный share sheet с JSON-бэкапом.
  Future<void> shareFile() async {
    final json = await _buildJson();
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode(json)));
    final now = DateTime.now();
    final fileName =
        'eduatt_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';

    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/$fileName');
    await tempFile.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(tempFile.path, mimeType: 'application/json')],
      subject: 'EduAtt резервная копия',
    );
  }

  Future<Map<String, dynamic>> _buildJson() async {
    final institutions = await _db.select(_db.institutions).get();
    final teachers = await _db.select(_db.teachers).get();
    final groups = await _db.select(_db.groups).get();
    final students = await _db.select(_db.students).get();
    final subjects = await _db.select(_db.subjects).get();
    final schedules = await _db.select(_db.schedules).get();
    final lessons = await _db.select(_db.lessons).get();
    final attendances = await _db.select(_db.lessonAttendances).get();

    final role = await SharedPreferencesService.getPersonalRole();

    return {
      'version': 1,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
      'data': {
        'institutions': institutions
            .map((r) => {'id': r.id, 'name': r.name})
            .toList(),
        'teachers': teachers
            .map((r) => {
                  'id': r.id,
                  'name': r.name,
                  'surname': r.surname,
                  'department': r.department,
                })
            .toList(),
        'groups': groups
            .map((r) => {
                  'id': r.id,
                  'name': r.name,
                  'institution_id': r.institutionId,
                  'curator_id': r.curatorId,
                })
            .toList(),
        'students': students
            .map((r) => {
                  'id': r.id,
                  'name': r.name,
                  'surname': r.surname,
                  'group_id': r.groupId,
                  'is_headman': r.isHeadman,
                })
            .toList(),
        'subjects': subjects
            .map((r) => {
                  'id': r.id,
                  'institution_id': r.institutionId,
                  'name': r.name,
                })
            .toList(),
        'schedules': schedules
            .map((r) => {
                  'id': r.id,
                  'institution_id': r.institutionId,
                  'subject_id': r.subjectId,
                  'group_id': r.groupId,
                  'start_time': r.startTime,
                  'end_time': r.endTime,
                  'teacher_id': r.teacherId,
                  'date': r.date.toIso8601String(),
                  'weekday': r.weekday,
                })
            .toList(),
        'lessons': lessons
            .map((r) => {
                  'id': r.id,
                  'schedule_id': r.scheduleId,
                  'topic': r.topic,
                  'attendance_status': r.attendanceStatus,
                })
            .toList(),
        'lesson_attendances': attendances
            .map((r) => {
                  'id': r.id,
                  'lesson_id': r.lessonId,
                  'student_id': r.studentId,
                  'status': r.status,
                  'is_synced': r.isSynced,
                })
            .toList(),
      },
    };
  }

  // ── Импорт ────────────────────────────────────────────────────────────────

  /// Импортирует данные из JSON и возвращает роль из файла (или null).
  /// Активацию провайдеров выполняет вызывающая сторона.
  Future<PersonalRole?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.first.bytes;
    if (bytes == null) throw Exception('Не удалось прочитать файл');

    final Map<String, dynamic> json = jsonDecode(utf8.decode(bytes));
    _validateBackup(json);

    await _db.clearAllData();
    await _restoreFromJson(json['data'] as Map<String, dynamic>);

    final roleStr = json['role'] as String?;
    final role = PersonalRoleExt.fromString(roleStr);
    if (role != null) {
      await SharedPreferencesService.savePersonalMode(role.storedValue);
    }
    return role;
  }

  void _validateBackup(Map<String, dynamic> json) {
    if (json['version'] == null || json['data'] == null) {
      throw FormatException('Неверный формат файла резервной копии');
    }
  }

  Future<void> _restoreFromJson(Map<String, dynamic> data) async {
    await _db.transaction(() async {
      for (final r in (data['institutions'] as List? ?? [])) {
        await _db.into(_db.institutions).insertOnConflictUpdate(
              InstitutionsCompanion(
                id: Value(r['id'] as String),
                name: Value(r['name'] as String),
              ),
            );
      }

      for (final r in (data['teachers'] as List? ?? [])) {
        await _db.into(_db.teachers).insertOnConflictUpdate(
              TeachersCompanion(
                id: Value(r['id'] as String),
                name: Value(r['name'] as String),
                surname: Value(r['surname'] as String),
                department: Value(r['department'] as String?),
              ),
            );
      }

      for (final r in (data['groups'] as List? ?? [])) {
        await _db.into(_db.groups).insertOnConflictUpdate(
              GroupsCompanion(
                id: Value(r['id'] as String),
                name: Value(r['name'] as String),
                institutionId: Value(r['institution_id'] as String),
                curatorId: Value(r['curator_id'] as String?),
              ),
            );
      }

      for (final r in (data['students'] as List? ?? [])) {
        await _db.into(_db.students).insertOnConflictUpdate(
              StudentsCompanion(
                id: Value(r['id'] as String),
                name: Value(r['name'] as String),
                surname: Value(r['surname'] as String),
                groupId: Value(r['group_id'] as String),
                isHeadman: Value(r['is_headman'] as bool),
              ),
            );
      }

      for (final r in (data['subjects'] as List? ?? [])) {
        await _db.into(_db.subjects).insertOnConflictUpdate(
              SubjectsCompanion(
                id: Value(r['id'] as String),
                institutionId: Value(r['institution_id'] as String),
                name: Value(r['name'] as String),
              ),
            );
      }

      for (final r in (data['schedules'] as List? ?? [])) {
        await _db.into(_db.schedules).insertOnConflictUpdate(
              SchedulesCompanion(
                id: Value(r['id'] as String),
                institutionId: Value(r['institution_id'] as String),
                subjectId: Value(r['subject_id'] as String),
                groupId: Value(r['group_id'] as String),
                startTime: Value(r['start_time'] as String),
                endTime: Value(r['end_time'] as String),
                teacherId: Value(r['teacher_id'] as String),
                date: Value(DateTime.parse(r['date'] as String)),
                weekday: Value(r['weekday'] as int),
              ),
            );
      }

      for (final r in (data['lessons'] as List? ?? [])) {
        await _db.into(_db.lessons).insertOnConflictUpdate(
              LessonsCompanion(
                id: Value(r['id'] as String),
                scheduleId: Value(r['schedule_id'] as String),
                topic: Value(r['topic'] as String?),
                attendanceStatus: Value(r['attendance_status'] as String),
              ),
            );
      }

      for (final r in (data['lesson_attendances'] as List? ?? [])) {
        await _db.into(_db.lessonAttendances).insertOnConflictUpdate(
              LessonAttendancesCompanion(
                id: Value(r['id'] as String),
                lessonId: Value(r['lesson_id'] as String),
                studentId: Value(r['student_id'] as String),
                status: Value(r['status'] as String?),
                isSynced: Value(r['is_synced'] as bool? ?? false),
              ),
            );
      }
    });
  }
}

final backupServiceProvider = Provider<BackupService>(
  (ref) => BackupService(ref.watch(appDatabaseProvider)),
);

