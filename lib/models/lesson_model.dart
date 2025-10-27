class LessonModel {
  final int? id; // nullable, присваивается Supabase
  final String scheduleId;
  final String? topic;

  LessonModel({this.id, required this.scheduleId, this.topic});

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'] as int?,
      scheduleId: json['schedule_id'] as String,
      topic: json['topic'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // отправляем только если нужно
      'schedule_id': scheduleId,
      'topic': topic,
    };
  }
}
