import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/providers/chat_messages_provider.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentLesson = ref.watch(currentLessonProvider);

    // Состояние, если урок не найден
    if (currentLesson == null || currentLesson.id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Чат урока')),
        body: const Center(child: Text('Занятие не найдено или завершено')),
      );
    }

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

    final chatState = ref.watch(chatMessagesProvider(currentLesson.id!));

    // Обработка ошибок
    if (chatState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(chatState.error!),
            backgroundColor: colorScheme.error,
          ),
        );
      });
    }

    void sendMessage() {
      final text = _textController.text.trim();
      if (text.isEmpty || currentUserId == null) return;

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
      // Прокрутка вниз при отправке
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Чат занятия', style: TextStyle(fontSize: 16)),
            Text(
              currentLesson.subjectName ?? '',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _navigateBack,
        ),
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: ListView.builder(
              reverse: true, // Сообщения снизу вверх
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                // Поскольку reverse: true, берем сообщения с конца
                final msg =
                    chatState.messages[chatState.messages.length - 1 - index];
                final isOwn = msg.senderId == currentUserId;
                final displayName =
                    isOwn ? currentUserLabel : msg.senderFullName;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment:
                        isOwn ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment:
                          isOwn
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isOwn
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft:
                                  isOwn
                                      ? const Radius.circular(16)
                                      : Radius.zero,
                              bottomRight:
                                  isOwn
                                      ? Radius.zero
                                      : const Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                msg.message,
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      isOwn
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: (isOwn
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant)
                                      .withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Поле ввода
          _buildInputArea(context, sendMessage),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, VoidCallback onSend) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textController,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Сообщение...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onSend,
            icon: const Icon(Icons.send_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateBack() {
    final isTeacher = ref.read(teacherProvider) != null;
    context.go(isTeacher ? '/teacher/home' : '/student/home');
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
