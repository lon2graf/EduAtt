class ChatMessage {
  final String? id;
  final String lessonId;
  final String message;
  final DateTime timestamp;

  // Идентификаторы отправителя
  final String? senderTeacherId;
  final String? senderStudentId;

  // Плоские данные об отправителе (из таблицы lesson_comment)
  final String? senderName;
  final String? senderSurname;
  final String senderType;

  bool get isTemporary => id == null || id == '-1';

  ChatMessage({
    this.id,
    required this.lessonId,
    required this.message,
    required this.timestamp,
    this.senderTeacherId,
    this.senderStudentId,
    this.senderName,
    this.senderSurname,
    required this.senderType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Определяем, кто отправитель, по наличию ID
    final teacherId = json['sender_teacher_id']?.toString();
    final studentId = json['sender_student_id']?.toString();

    // Если teacherId не null, значит отправил учитель
    final isTeacher = teacherId != null;

    return ChatMessage(
      id: json['id']?.toString(),
      lessonId: json['lesson_id']?.toString() ?? '0',
      message: json['message'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),

      senderTeacherId: teacherId,
      senderStudentId: studentId,
      senderName: json['sender_name'] as String?,
      senderSurname: json['sender_surname'] as String?,
      // Тип вычисляем «на лету»
      senderType: isTeacher ? 'teacher' : 'student',
    );
  }

  // Красивое полное имя
  String get senderFullName {
    if (senderName != null && senderSurname != null) {
      return '$senderName $senderSurname';
    }
    return senderName ??
        senderSurname ??
        (isTeacher ? 'Преподаватель' : 'Студент');
  }

  String get senderId => senderTeacherId ?? senderStudentId ?? '';
  bool get isTeacher => senderType == 'teacher';
  bool get isStudent => senderType == 'student';

  Map<String, dynamic> toJson() {
    return {
      'lesson_id': lessonId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'sender_name': senderName,
      'sender_surname': senderSurname,
      if (senderTeacherId != null) 'sender_teacher_id': senderTeacherId,
      if (senderStudentId != null) 'sender_student_id': senderStudentId,
    };
  }

  factory ChatMessage.temporary({
    required String lessonId,
    required String message,
    required String senderId,
    required String senderType,
    String? senderName,
    String? senderSurname,
  }) {
    return ChatMessage(
      id: '-1',
      lessonId: lessonId,
      message: message,
      timestamp: DateTime.now(),
      senderTeacherId: senderType == 'teacher' ? senderId : null,
      senderStudentId: senderType == 'student' ? senderId : null,
      senderName: senderName,
      senderSurname: senderSurname,
      senderType: senderType,
    );
  }
}
