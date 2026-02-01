import 'package:edu_att/models/lesson_attendance_status.dart';

class LessonModel {
  final String? id; // Изменено int? → String?
  final String? topic;
  final String date;
  final String startTime;
  final String endTime;
  final String groupId;
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
    required this.subjectName,
    required this.teacherName,
    required this.teacherSurname,
    this.status = LessonAttendanceStatus.free,
  });

  LessonModel copyWith({LessonAttendanceStatus? status}) {
    return LessonModel(
      id: this.id,
      topic: this.topic,
      date: this.date,
      startTime: this.startTime,
      endTime: this.endTime,
      groupId: this.groupId,
      subjectName: this.subjectName,
      teacherName: this.teacherName,
      teacherSurname: this.teacherSurname,
      status: status ?? this.status,
    );
  }

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'] as Map<String, dynamic>;

    // Парсим id как String
    final id = json['id'];
    final String? idString;

    if (id == null) {
      idString = null;
    } else if (id is int) {
      idString = id.toString();
    } else if (id is String) {
      idString = id;
    } else {
      idString = null;
    }

    return LessonModel(
      id: idString, // Теперь String?
      topic: json['topic'] as String?,
      date: schedule['date'] as String,
      startTime: schedule['start_time'] as String,
      endTime: schedule['end_time'] as String,
      groupId: schedule['group_id'] as String,
      subjectName: (schedule['subjects']?['name'] ?? '') as String,
      teacherName: (schedule['teachers']?['name'] ?? '') as String,
      teacherSurname: (schedule['teachers']?['surname'] ?? '') as String,
      status: LessonAttendanceStatus.fromString(
        json['attendance_status'] as String?,
      ),
    );
  }
}
