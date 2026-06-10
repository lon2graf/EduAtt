import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/data/local_db/app_database.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class LessonAttendanceModel {
  final String? id;
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
  final String? topic;

  // null = не рассмотрено/без объяснительной, true = уважительная, false = неуважительная
  final bool? isExcused;

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
    this.topic,
    this.isExcused,
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

    final lessonId = json["lesson_id"];
    final String lessonIdString;
    if (lessonId is int) {
      lessonIdString = lessonId.toString();
    } else if (lessonId is String) {
      lessonIdString = lessonId;
    } else {
      lessonIdString = '0';
    }

    final id = json["id"];
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
      id: idString,
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
      isExcused: json["is_excused"] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'lesson_id': lessonId,
      'student_id': studentId,
      'status': status?.toDbValue,
      if (isExcused != null) 'is_excused': isExcused,
    };
  }

  LessonAttendanceModel copyWith({
    String? id,
    AttendanceStatus? status,
    bool? isExcused,
  }) {
    return LessonAttendanceModel(
      id: id ?? this.id,
      status: status ?? this.status,
      isExcused: isExcused ?? this.isExcused,
      lessonId: lessonId,
      studentId: studentId,
      studentName: studentName,
      lessonDate: lessonDate,
      lessonStart: lessonStart,
      lessonEnd: lessonEnd,
      subjectName: subjectName,
      teacherName: teacherName,
      teacherSurname: teacherSurname,
      groupId: groupId,
      topic: topic,
    );
  }

  factory LessonAttendanceModel.fromDrift(LessonAttendance data) {
    return LessonAttendanceModel(
      id: data.id,
      lessonId: data.lessonId,
      studentId: data.studentId,
      status: AttendanceStatus.fromString(data.status),
      isExcused: data.isExcused,
    );
  }

  LessonAttendancesCompanion toCompanion({bool isSynced = true}) {
    return LessonAttendancesCompanion(
      id: Value(id ?? const Uuid().v4()),
      lessonId: Value(lessonId),
      studentId: Value(studentId),
      status: Value(status?.toDbValue),
      isSynced: Value(isSynced),
      updatedAt: Value(DateTime.now()),
      isExcused: Value(isExcused),
    );
  }
}
