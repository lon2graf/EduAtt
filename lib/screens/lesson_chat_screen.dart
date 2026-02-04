import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/providers/chat_messages_provider.dart';
// import 'package:edu_att/models/chat_message_model.dart'; // Если нужен
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
        appBar: AppBar(
          title: const Text('Чат урока'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(), // Используем умную навигацию
          ),
        ),
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
        appBar: AppBar(
          title: const Text('Чат урока'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateBack(),
          ),
        ),
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
      });
    }

    // Функция отправки
    void sendMessage() {
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
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        title: Text(
          'Чат: ${currentLesson.subjectName}',
          style: const TextStyle(fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _navigateBack(), // <--- ИСПРАВЛЕНО ТУТ
        ),
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: chatState.messages.length,
              itemBuilder: (context, index) {
                final msg = chatState.messages[index];
                final isOwn = msg.senderId == currentUserId;

                // Отображаемое имя
                final displayName =
                    isOwn ? currentUserLabel : msg.senderFullName;

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Align(
                    alignment:
                        isOwn ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isOwn
                                ? Colors.purple.shade100
                                : Colors.grey.shade200,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          topRight: const Radius.circular(12),
                          bottomLeft:
                              isOwn ? const Radius.circular(12) : Radius.zero,
                          bottomRight:
                              isOwn ? Radius.zero : const Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color:
                                  isOwn
                                      ? Colors.purple.shade900
                                      : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.message,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black45,
                              ),
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

          // Поле ввода
          if (currentUserId != null)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Сообщение...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: Colors.purple.shade700),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- НОВЫЙ МЕТОД НАВИГАЦИИ ---
  void _navigateBack() {
    // Проверяем, кто залогинен
    final isTeacher = ref.read(teacherProvider) != null;

    if (isTeacher) {
      context.go('/teacher/home');
    } else {
      context.go('/student/home');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
