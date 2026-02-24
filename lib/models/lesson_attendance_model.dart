import 'package:edu_att/models/attendance_status.dart';

class LessonAttendanceModel {
  final String? id; // Изменено на nullable
  final String lessonId;
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
    this.id, // Вернули nullable
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

    // Парсим lesson_id как String
    final lessonId = json["lesson_id"];
    final String lessonIdString;

    if (lessonId is int) {
      lessonIdString = lessonId.toString();
    } else if (lessonId is String) {
      lessonIdString = lessonId;
    } else {
      lessonIdString = '0';
    }

    // Парсим id как String (может быть null)
    final id = json["id"];
    final String? idString;

    if (id == null) {
      idString = null;
    } else if (id is int) {
      idString = id.toString();
    } else if (id is String) {
      idString = id;
    } else {
      idString = null; // Возвращаем null если тип не распознан
    }

    // Парсим student_id как String
    final studentId = json["student_id"];
    final String studentIdString;

    if (studentId is int) {
      studentIdString = studentId.toString();
    } else if (studentId is String) {
      studentIdString = studentId;
    } else {
      studentIdString = '';
    }

    return LessonAttendanceModel(
      id: idString, // Может быть null
      lessonId: lessonIdString,
      studentId: studentIdString,
      studentName: studentName.isEmpty ? null : studentName,
      status: status,
      lessonDate:
          schedule["date"] != null ? DateTime.tryParse(schedule["date"]) : null,
      lessonStart: schedule["start_time"] as String?,
      lessonEnd: schedule["end_time"] as String?,
      subjectName: subject["name"] as String?,
      teacherName: teacher["name"] as String?,
      teacherSurname: teacher["surname"] as String?,
      groupId: schedule["group_id"] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // Добавляем id только если он есть
      'lesson_id': lessonId,
      'student_id': studentId,
      'status': status?.toDbValue,
    };
  }

  LessonAttendanceModel copyWith({String? id, AttendanceStatus? status}) {
    return LessonAttendanceModel(
      // Если передали новое значение — берем его, иначе оставляем старое
      id: id ?? this.id,
      status: status ?? this.status,
      lessonId: this.lessonId,
      studentId: this.studentId,
      studentName: this.studentName,
      lessonDate: this.lessonDate,
      lessonStart: this.lessonStart,
      lessonEnd: this.lessonEnd,
      subjectName: this.subjectName,
      teacherName: this.teacherName,
      teacherSurname: this.teacherSurname,
      groupId: this.groupId,
    );
  }
}
