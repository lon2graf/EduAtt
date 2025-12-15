// lib/screens/lesson_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/providers/chat_messages_provider.dart';
import 'package:edu_att/models/chat_message_model.dart';
import 'package:go_router/go_router.dart';

class LessonChatScreen extends ConsumerStatefulWidget {
  const LessonChatScreen({super.key});

  @override
  ConsumerState<LessonChatScreen> createState() => _LessonChatScreenState();
}

class _LessonChatScreenState extends ConsumerState<LessonChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // 1. Получаем текущий урок
    final currentLesson = ref.watch(currentLessonProvider);
    if (currentLesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Чат урока')),
        body: const Center(child: Text('Сейчас занятий нет')),
      );
    }

    // 2. Получаем данные текущего пользователя
    final student = ref.watch(currentStudentProvider);
    final teacher = ref.watch(teacherProvider);

    String? currentUserId;
    String? currentUserType;
    String currentUserLabel = 'Вы';

    if (student != null) {
      currentUserId = student.id;
      currentUserType = 'student';
      currentUserLabel = student.isHeadman ? 'Вы (староста)' : 'Вы';
    } else if (teacher != null) {
      currentUserId = teacher.id;
      currentUserType = 'teacher';
      currentUserLabel = 'Вы (преподаватель)';
    }

    // 3. Подключаем чат
    if (currentLesson.id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Чат урока')),
        body: const Center(
          child: Text('Невозможно открыть чат: у урока нет ID'),
        ),
      );
    }

    final chatState = ref.watch(chatMessagesProvider(currentLesson.id!));

    // 4. Обработка ошибок
    if (chatState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(chatState.error!)));
        // Очистка ошибки (опционально)
      });
    }

    // 5. Отправка сообщения
    void _sendMessage() {
      final text = _textController.text.trim();
      if (text.isEmpty || currentUserId == null || currentUserType == null)
        return;

      ref
          .read(chatMessagesProvider(currentLesson.id!).notifier)
          .sendMessage(
            text: text,
            senderId: currentUserId!,
            senderType: currentUserType!,
            senderName: student?.name ?? teacher?.name,
            senderSurname: student?.surname ?? teacher?.surname,
          );
      _textController.clear();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple,
        title: Text('Чат: ${currentLesson.subjectName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.go('/student/home');
          },
        ),
      ),
      body: Column(
        children: [
          // → Список сообщений
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                final isOwn = msg.senderId == currentUserId;
                final displayName =
                    isOwn ? currentUserLabel : msg.senderFullName;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Align(
                    alignment:
                        isOwn ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isOwn
                                ? Colors.purple.shade300
                                : Colors.grey.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            isOwn
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                        children: [
                          // Имя отправителя
                          Text(
                            displayName,
                            style: TextStyle(
                              color: isOwn ? Colors.white70 : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Текст сообщения
                          Text(
                            msg.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Время
                          Text(
                            '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // → Поле ввода (только если авторизован)
          if (currentUserId != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Сообщение...',
                        filled: true,
                        fillColor: Colors.white24,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
