class ChatMessage {
  final int? id; // INT, может быть null при отправке
  final int lessonId; // INT
  final String message;
  final DateTime timestamp;

  // Отправитель
  final String? senderTeacherId;
  final String? senderStudentId;

  // Информация об отправителе
  final String? senderName;
  final String? senderSurname;
  final String senderType;

  bool get isTemporary => id == null || id == -1;

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
    final isTeacher = json['sender_teacher_id'] != null;

    // Извлекаем имя отправителя
    String? senderName;
    String? senderSurname;

    if (isTeacher && json['teachers'] != null) {
      final teacher = json['teachers'] as Map<String, dynamic>;
      senderName = teacher['name'] as String?;
      senderSurname = teacher['surname'] as String?;
    } else if (!isTeacher && json['students'] != null) {
      final student = json['students'] as Map<String, dynamic>;
      senderName = student['name'] as String?;
      senderSurname = student['surname'] as String?;
    }

    // Парсим id как int
    final id = json['id'];
    final int? idInt;

    if (id is int) {
      idInt = id;
    } else if (id is String) {
      idInt = int.tryParse(id);
    } else {
      idInt = null;
    }

    // Парсим lesson_id как int
    final lessonId = json['lesson_id'];
    final int lessonIdInt;

    if (lessonId is int) {
      lessonIdInt = lessonId;
    } else if (lessonId is String) {
      lessonIdInt = int.tryParse(lessonId) ?? 0;
    } else {
      lessonIdInt = 0;
    }

    return ChatMessage(
      id: idInt, // ← int?
      lessonId: lessonIdInt, // ← int
      message: json['message'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      senderTeacherId: json['sender_teacher_id'] as String?,
      senderStudentId: json['sender_student_id'] as String?,
      senderName: senderName,
      senderSurname: senderSurname,
      senderType: isTeacher ? 'teacher' : 'student',
    );
  }

  String get senderFullName {
    if (senderName != null && senderSurname != null) {
      return '$senderName $senderSurname';
    } else if (senderName != null) {
      return senderName!;
    } else if (senderSurname != null) {
      return senderSurname!;
    }
    return senderType == 'teacher' ? 'Преподаватель' : 'Студент';
  }

  String get senderId => senderTeacherId ?? senderStudentId ?? '';

  bool get isTeacher => senderType == 'teacher';
  bool get isStudent => senderType == 'student';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'lesson_id': lessonId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };

    if (senderTeacherId != null) {
      json['sender_teacher_id'] = senderTeacherId;
    } else if (senderStudentId != null) {
      json['sender_student_id'] = senderStudentId;
    }

    return json;
  }

  // Создание временного сообщения
  factory ChatMessage.temporary({
    required int lessonId,
    required String message,
    required String senderId,
    required String senderType,
    String? senderName,
    String? senderSurname,
  }) {
    return ChatMessage(
      id: -1, // ← специальное значение для временных
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
