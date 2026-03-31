import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:edu_att/models/chat_message_model.dart';

class LessonChatService {
  /// Метод отправки сообщения
  static Future<String?> sendMessage({
    required String lessonId,
    required String message,
    required String senderId,
    required String senderType, // Оставляем в параметрах для логики
    required String senderName,
    required String senderSurname,
  }) async {
    final supClient = Supabase.instance.client;

    try {
      final Map<String, dynamic> messageData = {
        'lesson_id': lessonId,
        'message': message.trim(),
        'sender_name': senderName,
        'sender_surname': senderSurname,
      };

      // Раскладываем ID в нужную колонку
      if (senderType == 'teacher') {
        messageData['sender_teacher_id'] = senderId;
      } else {
        messageData['sender_student_id'] = senderId;
      }

      await supClient.from('lesson_comment').insert(messageData);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<List<ChatMessage>> getAllMessages(String lessonId) async {
    final supClient = Supabase.instance.client;
    try {
      final response = await supClient
          .from('lesson_comment')
          .select('*')
          .eq('lesson_id', lessonId)
          .order('timestamp', ascending: true);

      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      print('Ошибка загрузки истории чата: $e');
      return [];
    }
  }

  static Future<List<ChatMessage>> getNewMessagesSince({
    required String lessonId,
    required DateTime since,
  }) async {
    final supClient = Supabase.instance.client;
    try {
      final response = await supClient
          .from('lesson_comment')
          .select('*')
          .eq('lesson_id', lessonId)
          .gt('timestamp', since.toUtc().toIso8601String())
          .order('timestamp', ascending: true);

      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      print('Ошибка загрузки новых сообщений: $e');
      return [];
    }
  }
}
