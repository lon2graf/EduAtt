import 'package:edu_att/models/attendance_status.dart';

class LessonAttendanceModel {
  final int? id;
  final int lessonId;
  final String studentId;
  final String? studentName;
  AttendanceStatus? status;

  final DateTime? lessonDate;
  final String? lessonStart;
  final String? lessonEnd;
  final String? subjectName;
  final String? teacherName;
  final String? teacherSurname;
  final String? groupId;

  LessonAttendanceModel({
    this.id,
    required this.lessonId,
    required this.studentId,
    this.studentName,
    this.status,
    this.lessonDate,
    this.lessonStart,
    this.lessonEnd,
    this.subjectName,
    this.teacherName,
    this.teacherSurname,
    this.groupId,
  });

  factory LessonAttendanceModel.fromNestedJson(Map<String, dynamic> json) {
    final lesson = json["lessons"] as Map<String, dynamic>? ?? {};
    final schedule = lesson["schedule"] as Map<String, dynamic>? ?? {};
    final subject = schedule["subjects"] as Map<String, dynamic>? ?? {};
    final teacher = schedule["teachers"] as Map<String, dynamic>? ?? {};
    final students = json["students"] as Map<String, dynamic>? ?? {};
    final status = AttendanceStatus.fromString(json["status"]);

    final studentName =
        '${students["name"] ?? ""} ${students["surname"] ?? ""}'.trim();

    return LessonAttendanceModel(
      id: json["id"] as int?,
      lessonId: json["lesson_id"] as int,
      studentId: json["student_id"].toString(),
      studentName: studentName.isEmpty ? null : studentName,
      status: status,
      lessonDate:
          schedule["date"] != null ? DateTime.tryParse(schedule["date"]) : null,
      lessonStart: schedule["start_time"] as String?,
      lessonEnd: schedule["end_time"] as String?,
      subjectName: subject["name"] as String?,
      teacherName: teacher["name"] as String?,
      teacherSurname: teacher["surname"] as String?,
      groupId: schedule["group_id"] as String?, // ← безопасно извлекаем
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'lesson_id': lessonId,
      'student_id': studentId,
      'status': status,
    };
  }
}
