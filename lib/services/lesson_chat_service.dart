import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:edu_att/models/chat_message_model.dart';

class LessonChatService {
  //метод отправки сообщения
  //возвращает null если все хорошо либо строку с ошибкой
  static Future<String?> sendMessage({
    required int lessonId,
    required String message,
    required String senderId,
    required String senderType,
  }) async {
    final supClient = Supabase.instance.client;

    try {
      final validationError = _validateMessage(message);

      if (validationError != null) {
        return validationError;
      }

      final Map<String, dynamic> messageData = {
        'lesson_id': lessonId,
        'message': message.trim(),
      };

      if (senderType == 'teacher') {
        messageData['sender_teacher_id'] = senderId;
      } else if (senderType == 'student') {
        messageData['sender_student_id'] = senderId;
      } else {
        return 'Неверный тип отправителя: $senderType';
      }

      await supClient.from('lesson_comment').insert(messageData);
    } catch (e) {
      final errorMessage = 'Ошибка отправки сообщения: ${e.toString()}';
      print(errorMessage);
      return errorMessage;
    }
  }

  static String? _validateMessage(String message) {
    final trimmed = message.trim();

    // Проверка на пустоту
    if (trimmed.isEmpty) {
      return 'Сообщение не может быть пустым';
    }

    // Проверка максимальной длины
    if (trimmed.length > 2000) {
      return 'Сообщение слишком длинное. Максимум 2000 символов';
    }

    // Проверка на сообщение только из пробелов (уже обработано trim)
    // Дополнительные проверки можно добавить здесь

    return null; // Сообщение валидно
  }

  static Future<List<ChatMessage>> getAllMessages(int lessonId) async {
    final supClient = Supabase.instance.client;

    try {
      final response = await supClient
          .from('lesson_comment')
          .select('''
      *,
      teachers(name, surname),
      students(name, surname)  
    ''')
          .eq('lesson_id', lessonId)
          .order('timestamp');
      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      print('Ошибка загрузки сообщений урока $lessonId: $e');
      return [];
    }
  }

  static Future<List<ChatMessage>> getNewMessageSince({
    required int lessonId,
    required DateTime since,
  }) async {
    final supClient = Supabase.instance.client;

    try {
      final sinceUtc = since.toUtc().toIso8601String();
      final response = await supClient
          .from('lesson_comment')
          .select('''
      *,
      teachers(name, surname),
      students(name, surname)  
    ''')
          .eq('lesson_id', lessonId)
          .gt('timestamp', sinceUtc)
          .order('timestamp', ascending: true);

      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      print(
        'Ошибка получения новых сообщений урока $lessonId после $since: $e',
      );
      return [];
    }
  }
}
