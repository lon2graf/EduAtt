import 'package:edu_att/models/chat_message_model.dart';
import 'package:edu_att/services/lesson_chat_service.dart';
import 'package:edu_att/services/chat_longpolling_service.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Состояние чата
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Провайдер чата для конкретного урока (lessonId)
final chatMessagesProvider = StateNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, ChatState, String>((ref, lessonId) {
      // ✅ int → String в типе family
      return ChatMessagesNotifier(lessonId);
    });

class ChatMessagesNotifier extends StateNotifier<ChatState> {
  final String lessonId; // ✅ int → String
  final ChatLongpollingService _pollingService = ChatLongpollingService();

  ChatMessagesNotifier(this.lessonId)
    : super(const ChatState(isLoading: true)) {
    _loadInitialMessages();
  }

  /// Загружает историю и запускает long polling
  Future<void> _loadInitialMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final messages = await LessonChatService.getAllMessages(lessonId);
      final lastTime =
          messages.isEmpty
              ? DateTime.now().subtract(const Duration(days: 30))
              : messages.last.timestamp;

      state = state.copyWith(messages: messages, isLoading: false);

      _pollingService.startForLesson(
        lessonId: lessonId,
        lastMessageDateTime: lastTime,
        onNewMessage: _handleNewMessages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить чат',
      );
    }
  }

  /// Обработка новых сообщений из long polling
  void _handleNewMessages(List<ChatMessage> newMessages) {
    // Фильтруем: не добавляем, если message с таким id уже есть
    final existingIds = {
      for (final msg in state.messages)
        if (msg.id != null && msg.id != '-1')
          msg.id!, // ✅ Сравнение с '-1' для строкового id
    };

    final unique =
        newMessages.where((m) => !existingIds.contains(m.id)).toList();

    if (unique.isNotEmpty) {
      state = state.copyWith(messages: [...state.messages, ...unique]);
    }
  }

  /// Отправка сообщения с optimistic UI
  Future<void> sendMessage({
    required String text,
    required String senderId,
    required String senderType,
    String? senderName,
    String? senderSurname,
  }) async {
    // 1. Создаём временное сообщение
    final tempMessage = ChatMessage.temporary(
      lessonId: lessonId,
      message: text,
      senderId: senderId,
      senderType: senderType,
      senderName: senderName,
      senderSurname: senderSurname,
    );

    // 2. Сразу показываем в UI
    state = state.copyWith(messages: [...state.messages, tempMessage]);

    // 3. Отправляем на сервер
    final error = await LessonChatService.sendMessage(
      lessonId: lessonId,
      message: text,
      senderId: senderId,
      senderType: senderType,
    );

    if (error != null) {
      // Ошибка → удаляем временное сообщение
      state = state.copyWith(
        messages: state.messages.where((m) => m != tempMessage).toList(),
        error: error,
      );
    } else {
      // Успех → перезагружаем чат, чтобы получить id
      await Future.delayed(const Duration(milliseconds: 300));
      _loadInitialMessages();
    }
  }

  @override
  void dispose() {
    _pollingService.stop();
    super.dispose();
  }
}
