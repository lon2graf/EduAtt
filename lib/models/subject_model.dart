class SubjectModel {
  final String? id; // nullable, присваивается Supabase
  final String institutionId;
  final String name;
  final String teacherId;
  final DateTime createdAt;

  SubjectModel({
    this.id,
    required this.institutionId,
    required this.name,
    required this.teacherId,
    required this.createdAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String?,
      institutionId: json['institution_id'] as String,
      name: json['name'] as String,
      teacherId: json['teacher_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // отправляем только если id уже есть
      'institution_id': institutionId,
      'name': name,
      'teacher_id': teacherId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
