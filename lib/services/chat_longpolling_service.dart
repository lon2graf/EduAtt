import 'package:edu_att/services/lesson_chat_service.dart';
import 'package:edu_att/models/chat_message_model.dart';
import 'dart:async';

class ChatLongpollingService {
  Timer? _timer;
  int? _currentLessonId;
  DateTime? _lastMessageTime;

  void startForLesson({
    required int lessonId,
    required DateTime lastMessageDateTime,
    required,
    required void Function(List<ChatMessage>) onNewMessage,
    Duration interval = const Duration(seconds: 5),
  }) async {
    stop();

    if (_lastMessageTime == null) return;

    try {
      final newMessages = await LessonChatService.getNewMessageSince(
        lessonId: lessonId,
        since: lastMessageDateTime,
      );

      if (newMessages.isNotEmpty) {
        onNewMessage(newMessages);

        _lastMessageTime = newMessages.last.timestamp;
      }
    } catch (e) {
      print('Ошибка polling для урока $lessonId: $e');
    }
  }

  void updateLastMessageTime(DateTime newTime) {
    _lastMessageTime = newTime;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _currentLessonId = null;
    _lastMessageTime = null;
  }

  bool isActiveForLesson(int lessonId) =>
      _timer != null && _currentLessonId == lessonId;
}
