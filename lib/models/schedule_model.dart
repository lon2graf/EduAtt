class ScheduleModel {
  final String id;
  final String? topic;
  final String startTime; // HH:mm:ss из Supabase
  final String endTime;
  final DateTime date;
  final int weekday;
  final String subjectName;
  final String teacherFullName;
  final String groupName;

  const ScheduleModel({
    required this.id,
    this.topic,
    required this.startTime,
    required this.endTime,
    required this.date,
    required this.weekday,
    required this.subjectName,
    required this.teacherFullName,
    required this.groupName,
  });

  /// Отображаемое время начала (HH:mm)
  String get startTimeShort =>
      startTime.length >= 5 ? startTime.substring(0, 5) : startTime;

  /// Отображаемое время конца (HH:mm)
  String get endTimeShort =>
      endTime.length >= 5 ? endTime.substring(0, 5) : endTime;

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    final subject = json['subjects'] as Map<String, dynamic>? ?? {};
    final teacher = json['teachers'] as Map<String, dynamic>? ?? {};
    final group = json['groups'] as Map<String, dynamic>? ?? {};

    // Supabase может вернуть lessons как List (one-to-many) или Map (one-to-one),
    // в зависимости от того, есть ли UNIQUE constraint на lessons.schedule_id.
    final dynamic lessonsRaw = json['lessons'];
    final String? topic;
    if (lessonsRaw is List) {
      topic = lessonsRaw.isNotEmpty
          ? lessonsRaw.first['topic'] as String?
          : null;
    } else if (lessonsRaw is Map) {
      topic = lessonsRaw['topic'] as String?;
    } else {
      topic = null;
    }

    final teacherName =
        '${teacher['surname'] ?? ''} ${teacher['name'] ?? ''}'.trim();

    return ScheduleModel(
      id: json['id'] as String,
      topic: topic,
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      weekday: json['weekday'] as int? ?? 0,
      subjectName: subject['name'] as String? ?? '',
      teacherFullName: teacherName,
      groupName: group['name'] as String? ?? '',
    );
  }
}
