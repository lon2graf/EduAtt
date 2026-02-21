import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/providers/chat_messages_provider.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';
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
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateBack() {
    final isTeacher = ref.read(teacherProvider) != null;
    context.go(isTeacher ? '/teacher/home' : '/student/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentLesson = ref.watch(currentLessonProvider);

    // 1. Базовая проверка на наличие урока
    if (currentLesson == null || currentLesson.id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Чат')),
        body: const Center(child: Text('Урок не найден')),
      );
    }

    // 2. Получаем данные текущего юзера для отправки
    final student = ref.watch(currentStudentProvider);
    final teacher = ref.watch(teacherProvider);
    final String currentUserId = student?.id ?? teacher?.id ?? '';
    final String currentUserType = student != null ? 'student' : 'teacher';

    // 3. Подключаем Realtime провайдер сообщений
    final chatState = ref.watch(chatMessagesProvider(currentLesson.id!));

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
          // Список сообщений или заглушка с Фросей
          Expanded(
            child:
                chatState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : chatState.messages.isEmpty
                    ? _buildEmptyState(context)
                    : _buildMessageList(chatState, currentUserId),
          ),

          // Поле ввода
          _buildInputArea(
            context,
            currentLesson.id!,
            currentUserId,
            currentUserType,
            student,
            teacher,
          ),
        ],
      ),
    );
  }

  // Виджет, если сообщений нет
  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EduMascot(state: MascotState.waiting, height: 180),
          const SizedBox(height: 16),
          Text(
            'Сообщений пока нет.\nФрося ждет вашей весточки!',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // Список сообщений
  Widget _buildMessageList(ChatState chatState, String currentUserId) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: chatState.messages.length,
      itemBuilder: (context, index) {
        final msg = chatState.messages[index];
        final isOwn = msg.senderId == currentUserId;

        return _buildChatBubble(context, msg, isOwn);
      },
    );
  }

  // Пузырь сообщения
  Widget _buildChatBubble(BuildContext context, var msg, bool isOwn) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color:
              isOwn ? colorScheme.primaryContainer : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isOwn ? const Radius.circular(16) : Radius.zero,
            bottomRight: isOwn ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isOwn)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  msg.senderFullName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
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
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}",
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Зона ввода
  Widget _buildInputArea(
    BuildContext context,
    String lessonId,
    String userId,
    String userType,
    var student,
    var teacher,
  ) {
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
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: 'Сообщение...',
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted:
                  (_) =>
                      _handleSend(lessonId, userId, userType, student, teacher),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed:
                () => _handleSend(lessonId, userId, userType, student, teacher),
            icon: const Icon(Icons.send_rounded),
          ),
        ],
      ),
    );
  }

  void _handleSend(
    String lessonId,
    String userId,
    String userType,
    var student,
    var teacher,
  ) {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Вызываем метод провайдера с новыми плоскими данными
    ref
        .read(chatMessagesProvider(lessonId).notifier)
        .sendMessage(
          text: text,
          senderId: userId,
          senderType: userType,
          senderName: student?.name ?? teacher?.name ?? 'Аноним',
          senderSurname: student?.surname ?? teacher?.surname ?? '',
        );

    _textController.clear();
    // Скролл вниз при отправке
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
}
