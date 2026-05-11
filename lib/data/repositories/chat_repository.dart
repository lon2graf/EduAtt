import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/data/remote/lesson_chat_service.dart';
import 'package:edu_att/models/chat_message_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatRepositoryProvider = Provider<ChatRepository>((_) => ChatRepository());

class ChatRepository {
  Stream<List<ChatMessage>> watchMessages(String lessonId) =>
      BaseService.client
          .from('lesson_comment')
          .stream(primaryKey: ['id'])
          .eq('lesson_id', lessonId)
          .order('timestamp', ascending: true)
          .map((data) => data.map(ChatMessage.fromJson).toList());

  Future<String?> sendMessage({
    required String lessonId,
    required String text,
    required String senderId,
    required String senderType,
    required String senderName,
    required String senderSurname,
  }) =>
      LessonChatService.sendMessage(
        lessonId: lessonId,
        message: text,
        senderId: senderId,
        senderType: senderType,
        senderName: senderName,
        senderSurname: senderSurname,
      );
}
