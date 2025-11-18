class LessonModel {
  final int? id;
  final String? topic;
  final String date;
  final String startTime;
  final String endTime;
  final String groupId;
  final String subjectName;
  final String teacherName;
  final String teacherSurname;

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
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    final schedule = json['schedule'] as Map<String, dynamic>;
    return LessonModel(
      id: json['id'] as int?,
      topic: json['topic'] as String?,
      date: schedule['date'] as String,
      startTime: schedule['start_time'] as String,
      endTime: schedule['end_time'] as String,
      groupId: schedule['group_id'] as String,
      subjectName: (schedule['subjects']?['name'] ?? '') as String,
      teacherName: (schedule['teachers']?['name'] ?? '') as String,
      teacherSurname: (schedule['teachers']?['surname'] ?? '') as String,
    );
  }
}
