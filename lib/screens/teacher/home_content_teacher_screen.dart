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
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/services/lesson_service.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final teacher = ref.watch(teacherProvider);
    final lesson = ref.watch(currentLessonProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Привет, ${teacher?.name ?? 'Преподаватель'}! 👋',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Текущее занятие'),
              const SizedBox(height: 12),
              _buildCurrentLessonCard(context, lesson),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLessonCard(BuildContext context, LessonModel? lesson) {
    final colorScheme = Theme.of(context).colorScheme;

    if (lesson == null || lesson.id == null) {
      return _buildCard(
        context,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text(
              'Сегодня занятий нет',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    String formattedStartTime = _formatTime(lesson.startTime);
    String formattedEndTime = _formatTime(lesson.endTime);

    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.subjectName ?? 'Предмет',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                '$formattedStartTime - $formattedEndTime',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.group_outlined,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Группа: ${lesson.groupId}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/lesson_chat'),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Чат урока'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          _buildTeacherAction(context, lesson),
        ],
      ),
    );
  }

  Widget _buildTeacherAction(BuildContext context, LessonModel lesson) {
    final colorScheme = Theme.of(context).colorScheme;

    String btnText = 'Начать перекличку';
    Color btnColor = colorScheme.primary;
    IconData btnIcon = Icons.edit_square;
    bool isDangerAction = false;

    switch (lesson.status) {
      case LessonAttendanceStatus.free:
        btnText = 'Начать перекличку';
        break;
      case LessonAttendanceStatus.onHeadmanEditing:
        btnText = 'Перехватить у старосты';
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
        btnColor = colorScheme.primary;
        break;
      case LessonAttendanceStatus.confirmed:
        btnText = 'Изменить (Подтверждено)';
        btnColor = colorScheme.onSurfaceVariant.withOpacity(0.6);
        btnIcon = Icons.lock_open;
        break;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final freshStatus = await LessonService.getFreshStatus(lesson.id!);

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

          if (isDangerAction) {
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (ctx) => AlertDialog(
                    title: const Text('Перехватить управление?'),
                    content: const Text(
                      'Ведомость сейчас заполняет староста. Данные будут сброшены.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Отмена'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                        ),
                        child: const Text(
                          'Перехватить',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
            );
            if (confirm != true) return;
          }

          _enterEditMode(lesson);
        },
        icon: Icon(btnIcon, size: 18),
        label: Text(btnText),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Future<void> _enterEditMode(LessonModel lesson) async {
    try {
      await LessonService.updateLessonStatus(
        lesson.id!,
        LessonAttendanceStatus.onTeacherEditing,
      );
      ref
          .read(currentLessonProvider.notifier)
          .updateStatus(LessonAttendanceStatus.onTeacherEditing);

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

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '--:--';
    List<String> parts = timeString.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : timeString;
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
