class LessonAttendanceModel {
  final int? id; // nullable, присваивается Supabase
  final int lessonId;
  final String studentId;
  final String? status;

  LessonAttendanceModel({
    this.id,
    required this.lessonId,
    required this.studentId,
    this.status,
  });

  factory LessonAttendanceModel.fromJson(Map<String, dynamic> json) {
    return LessonAttendanceModel(
      id: json['id'] as int?,
      lessonId: json['lesson_id'] as int,
      studentId: json['student_id'] as String,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // отправляем только если id уже есть
      'lesson_id': lessonId,
      'student_id': studentId,
      'status': status,
    };
  }
}
