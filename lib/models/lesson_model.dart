import 'package:edu_att/models/lesson_attendance_status.dart';

class LessonModel {
  final String? id; // Изменено int? → String?
  final String? topic;
  final String date;
  final String startTime;
  final String endTime;
  final String groupId;
  final String groupName;
  final String subjectName;
  final String teacherName;
  final String teacherSurname;
  final LessonAttendanceStatus status;

  LessonModel({
    this.id,
    this.topic,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.groupId,
    required this.groupName,
    required this.subjectName,
    required this.teacherName,
    required this.teacherSurname,
    this.status = LessonAttendanceStatus.free,
  });

  /// True если занятие ещё не началось (используется для отображения «Скоро»).
  bool get isUpcoming {
    try {
      final now = DateTime.now();
      final parts = startTime.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return now.hour * 60 + now.minute < h * 60 + m;
    } catch (_) {
      return false;
    }
  }

  String get startTimeShort {
    final parts = startTime.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : startTime;
  }

  LessonModel copyWith({LessonAttendanceStatus? status}) {
    return LessonModel(
      id: this.id,
      topic: this.topic,
      date: this.date,
      startTime: this.startTime,
      endTime: this.endTime,
      groupId: this.groupId,
      groupName: this.groupName,
      subjectName: this.subjectName,
      teacherName: this.teacherName,
      teacherSurname: this.teacherSurname,
      status: status ?? this.status,
    );
  }

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'] as Map<String, dynamic>? ?? {};

    // Безопасно получаем объект группы
    final groups = schedule['groups'] as Map<String, dynamic>? ?? {};

    // Остальные объекты
    final subjects = schedule['subjects'] as Map<String, dynamic>? ?? {};
    final teachers = schedule['teachers'] as Map<String, dynamic>? ?? {};

    // Парсинг id (твоя логика верна)
    final id = json['id'];
    final String? idString = id?.toString();

    return LessonModel(
      id: idString,
      topic: json['topic'] as String?,
      date: (schedule['date'] ?? '') as String,
      startTime: (schedule['start_time'] ?? '') as String,
      endTime: (schedule['end_time'] ?? '') as String,
      groupId: (schedule['group_id'] ?? '') as String,
      groupName:
          (groups['name'] ?? 'Без группы')
              as String, // Если null, напишет "Без группы"
      subjectName: (subjects['name'] ?? '') as String,
      teacherName: (teachers['name'] ?? '') as String,
      teacherSurname: (teachers['surname'] ?? '') as String,
      status: LessonAttendanceStatus.fromString(
        json['attendance_status'] as String?,
      ),
    );
  }
}
