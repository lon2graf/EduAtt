import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/providers/group_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/models/lesson_attendance_status.dart'; // Enum
import 'package:edu_att/services/lesson_service.dart'; // Service

// 1. Делаем Stateful, чтобы загружать данные при входе
class TeacherHomeContentScreen extends ConsumerStatefulWidget {
  const TeacherHomeContentScreen({super.key});

  @override
  ConsumerState<TeacherHomeContentScreen> createState() =>
      _TeacherHomeContentScreenState();
}

class _TeacherHomeContentScreenState
    extends ConsumerState<TeacherHomeContentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final teacher = ref.read(teacherProvider);
    if (teacher != null) {
      await ref
          .read(currentLessonProvider.notifier)
          .loadCurrentLessonForTeacher(teacher.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacher = ref.watch(teacherProvider);
    final lesson = ref.watch(currentLessonProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06)),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadInitialData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Привет, ${teacher?.name ?? 'Преподаватель'}! 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Текущее занятие'),
                      const SizedBox(height: 10),
                      _buildCurrentLessonCard(lesson),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentLessonCard(LessonModel? lesson) {
    if (lesson == null || lesson.id == null) {
      return _buildCard(
        child: const Center(
          child: Text(
            'Сегодня занятий нет',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    String formattedStartTime = _formatTime(lesson.startTime);
    String formattedEndTime = _formatTime(lesson.endTime);

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.subjectName ?? 'Предмет',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$formattedStartTime - $formattedEndTime',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'Группа: ${lesson.groupId}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('/lesson_chat');
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Чат урока', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. Умная кнопка действия
          _buildTeacherAction(lesson),
        ],
      ),
    );
  }

  Widget _buildTeacherAction(LessonModel lesson) {
    String btnText = 'Начать перекличку';
    Color btnColor = Colors.purple.shade700;
    IconData btnIcon = Icons.edit_square;
    bool isDangerAction = false; // Флаг для перехвата

    switch (lesson.status) {
      case LessonAttendanceStatus.free:
        btnText = 'Начать перекличку';
        break;
      case LessonAttendanceStatus.onHeadmanEditing:
        btnText = 'Перехватить у старосты'; // Опасное действие
        btnColor = Colors.orange.shade800;
        btnIcon = Icons.warning_amber_rounded;
        isDangerAction = true;
        break;
      case LessonAttendanceStatus.waitConfirmation:
        btnText = 'Проверить и Подтвердить';
        btnColor = Colors.blue.shade700;
        btnIcon = Icons.fact_check_outlined;
        break;
      case LessonAttendanceStatus.onTeacherEditing:
        btnText = 'Продолжить заполнение';
        break;
      case LessonAttendanceStatus.confirmed:
        btnText = 'Изменить (Подтверждено)';
        btnColor = Colors.grey.withOpacity(0.4);
        btnIcon = Icons.lock_open;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // 1. Проверяем свежий статус перед действием
          final freshStatus = await LessonService.getFreshStatus(lesson.id!);

          // Если мы думали что Free, а там уже кто-то сидит -> Обновляем и выходим
          if (freshStatus != lesson.status) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Статус урока изменился. Обновление...'),
                ),
              );
              _loadInitialData();
            }
            return;
          }

          // 2. Если это перехват (староста сидит) -> Показываем диалог
          if (isDangerAction) {
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Перехватить управление?'),
                    content: const Text(
                      'Ведомость сейчас заполняет староста. Если вы продолжите, его несохраненные данные будут потеряны, и заполнение начнется заново.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Отмена'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Перехватить'),
                      ),
                    ],
                  ),
            );

            if (confirm != true) return; // Если нажал отмену
          }

          // 3. Выполняем переход
          _enterEditMode(lesson);
        },
        icon: Icon(btnIcon, size: 18),
        label: Text(btnText),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _enterEditMode(LessonModel lesson) async {
    try {
      // 1. Обновляем статус в БД (Занимаем урок)
      await LessonService.updateLessonStatus(
        lesson.id!,
        LessonAttendanceStatus.onTeacherEditing,
      );

      // 2. Обновляем локально
      ref
          .read(currentLessonProvider.notifier)
          .updateStatus(LessonAttendanceStatus.onTeacherEditing);

      // 3. Грузим студентов и переходим
      if (lesson.groupId.isNotEmpty) {
        await ref
            .read(groupStudentsProvider.notifier)
            .loadGroupStudents(lesson.groupId);
        if (mounted) context.go('/teacher/mark');
      }
    } catch (e) {
      print("Ошибка при входе: $e");
    }
  }

  // ... (методы _formatTime, _buildCard, _buildSectionTitle) ...
  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '--:--';
    List<String> parts = timeString.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeString;
  }

  Widget _buildCard({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
