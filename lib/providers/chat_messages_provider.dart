import 'dart:async';

import 'package:edu_att/data/repositories/chat_repository.dart';
import 'package:edu_att/models/chat_message_model.dart';
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
  }) => ChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

final chatMessagesProvider = StateNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, ChatState, String>((ref, lessonId) {
      return ChatMessagesNotifier(lessonId, ref.watch(chatRepositoryProvider));
    });

class ChatMessagesNotifier extends StateNotifier<ChatState> {
  final String lessonId;
  final ChatRepository _repository;
  StreamSubscription<List<ChatMessage>>? _chatSubscription;

  ChatMessagesNotifier(this.lessonId, this._repository)
      : super(const ChatState(isLoading: true)) {
    _startChatStream();
  }

  void _startChatStream() {
    _chatSubscription = _repository.watchMessages(lessonId).listen(
      (messages) {
        state = state.copyWith(messages: messages, isLoading: false, error: null);
      },
      onError: (error) {
        state = state.copyWith(
          isLoading: false,
          error: 'Ошибка связи с Фросей: ${error.toString()}',
        );
      },
    );
  }

  Future<void> sendMessage({
    required String text,
    required String senderId,
    required String senderType,
    required String senderName,
    required String senderSurname,
  }) async {
    final errorString = await _repository.sendMessage(
      lessonId: lessonId,
      text: text,
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
