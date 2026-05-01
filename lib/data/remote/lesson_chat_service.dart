import 'package:edu_att/models/chat_message_model.dart';
import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/utils/data_result.dart';

class LessonChatService extends BaseService {
  /// Метод отправки сообщения
  static Future<String?> sendMessage({
    required String lessonId,
    required String message,
    required String senderId,
    required String senderType,
    required String senderName,
    required String senderSurname,
  }) async {
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

      await BaseService.client.from('lesson_comment').insert(messageData);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  static Future<List<ChatMessage>> getAllMessages(String lessonId) async {
    final result = await BaseService.executeSafely<List<ChatMessage>>(
      operation: () async {
        final response = await BaseService.client
            .from('lesson_comment')
            .select('*')
            .eq('lesson_id', lessonId)
            .order('timestamp', ascending: true);

        return (response as List)
            .map((json) => ChatMessage.fromJson(json))
            .toList();
      },
      errorContext: 'getAllMessages',
    );

    return switch (result) {
      Success(:final data) => data,
      Failure() => [],
    };
  }

  static Future<List<ChatMessage>> getNewMessagesSince({
    required String lessonId,
    required DateTime since,
  }) async {
    final result = await BaseService.executeSafely<List<ChatMessage>>(
      operation: () async {
        final response = await BaseService.client
            .from('lesson_comment')
            .select('*')
            .eq('lesson_id', lessonId)
            .gt('timestamp', since.toUtc().toIso8601String())
            .order('timestamp', ascending: true);

        return (response as List)
            .map((json) => ChatMessage.fromJson(json))
            .toList();
      },
      errorContext: 'getNewMessagesSince',
    );

    return switch (result) {
      Success(:final data) => data,
      Failure() => [],
    };
  }
}
