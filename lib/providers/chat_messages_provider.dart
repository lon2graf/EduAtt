import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:edu_att/models/chat_message_model.dart';
import 'package:edu_att/services/lesson_chat_service.dart';
import 'package:flutter_riverpod/legacy.dart';

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
      error: error,
    );
  }
}

/// Провайдер для чата конкретного урока
final chatMessagesProvider = StateNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, ChatState, String>((ref, lessonId) {
      return ChatMessagesNotifier(lessonId);
    });

class ChatMessagesNotifier extends StateNotifier<ChatState> {
  final String lessonId;
  StreamSubscription<List<Map<String, dynamic>>>? _chatSubscription;

  ChatMessagesNotifier(this.lessonId)
    : super(const ChatState(isLoading: true)) {
    _startChatStream();
  }

  void _startChatStream() {
    final supabase = Supabase.instance.client;

    _chatSubscription = supabase
        .from('lesson_comment')
        .stream(primaryKey: ['id'])
        .eq('lesson_id', lessonId)
        .order('timestamp', ascending: true)
        .listen(
          (List<Map<String, dynamic>> data) {
            final newMessages =
                data.map((json) => ChatMessage.fromJson(json)).toList();

            state = state.copyWith(
              messages: newMessages,
              isLoading: false,
              error: null,
            );
          },
          onError: (error) {
            state = state.copyWith(
              isLoading: false,
              error: 'Ошибка связи с Фросей: ${error.toString()}',
            );
          },
        );
  }

  /// Отправка сообщения
  Future<void> sendMessage({
    required String text,
    required String senderId,
    required String senderType,
    required String senderName,
    required String senderSurname,
  }) async {
    // Мы не добавляем сообщение в список вручную (Optimistic UI),
    // потому что Stream поймает его из БД и обновит экран почти мгновенно.

    final errorString = await LessonChatService.sendMessage(
      lessonId: lessonId,
      message: text,
      senderId: senderId,
      senderType: senderType,
      senderName: senderName,
      senderSurname: senderSurname,
    );

    if (errorString != null) {
      state = state.copyWith(error: errorString);
    }
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }
}
