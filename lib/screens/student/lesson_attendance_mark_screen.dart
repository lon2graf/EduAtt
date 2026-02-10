import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/services/lesson_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/group_provider.dart';
import 'package:edu_att/providers/lesson_attendance_mark_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:go_router/go_router.dart';

class AttendanceMarkScreen extends ConsumerStatefulWidget {
  const AttendanceMarkScreen({super.key});

  @override
  ConsumerState<AttendanceMarkScreen> createState() =>
      _AttendanceMarkScreenState();
}

class _AttendanceMarkScreenState extends ConsumerState<AttendanceMarkScreen> {
  int currentStudentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final students = ref.watch(groupStudentsProvider);
    final attendanceList = ref.watch(lessonAttendanceMarkProvider);
    final lesson = ref.watch(currentLessonProvider);

    // Инициализация данных
    if (students.isNotEmpty && attendanceList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(lessonAttendanceMarkProvider.notifier)
            .initializeAttendance(students, lesson);
      });
    }

    // Экран загрузки
    if (students.isEmpty || attendanceList.isEmpty) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    final currentStudent = students[currentStudentIndex];
    final currentAttendance = attendanceList.firstWhere(
      (item) => item.studentId == currentStudent.id,
      orElse: () => attendanceList.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Отметка посещаемости"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/student/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Карточка студента ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    currentStudent.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentStudent.surname,
                    style: TextStyle(
                      fontSize: 20,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- Текущий статус ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Статус: ${currentAttendance.status?.label ?? 'не отмечен'}",
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- Кнопки выбора ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statusButton(
                  context,
                  AttendanceStatus.present,
                  currentStudent.id!,
                ),
                _statusButton(
                  context,
                  AttendanceStatus.absent,
                  currentStudent.id!,
                ),
                _statusButton(
                  context,
                  AttendanceStatus.late,
                  currentStudent.id!,
                ),
              ],
            ),

            const SizedBox(height: 60),

            // --- Навигация и Сохранение ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Назад
                currentStudentIndex > 0
                    ? IconButton(
                      onPressed: () => setState(() => currentStudentIndex--),
                      icon: Icon(
                        Icons.chevron_left,
                        size: 40,
                        color: colorScheme.primary,
                      ),
                    )
                    : const SizedBox(width: 48),

                // Счетчик
                Text(
                  "${currentStudentIndex + 1} / ${students.length}",
                  style: TextStyle(
                    fontSize: 18,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Вперед или Сохранить
                if (currentStudentIndex < students.length - 1)
                  IconButton(
                    onPressed: () => setState(() => currentStudentIndex++),
                    icon: Icon(
                      Icons.chevron_right,
                      size: 40,
                      color: colorScheme.primary,
                    ),
                  )
                else
                  _buildSaveButton(context, lesson),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, var lesson) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: () async {
        if (lesson == null || lesson.id == null) return;

        final freshStatus = await LessonService.getFreshStatus(lesson.id!);
        if (freshStatus != LessonAttendanceStatus.onHeadmanEditing) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ошибка! Управление перехвачено преподавателем.'),
                backgroundColor: Colors.red,
              ),
            );
            ref
                .read(currentLessonProvider.notifier)
                .loadCurrentLesson(lesson.groupId);
            context.go('/student/home');
          }
          return;
        }

        try {
          await ref
              .read(lessonAttendanceMarkProvider.notifier)
              .saveAttendance();
          await LessonService.updateLessonStatus(
            lesson.id!,
            LessonAttendanceStatus.waitConfirmation,
          );
          ref
              .read(currentLessonProvider.notifier)
              .updateStatus(LessonAttendanceStatus.waitConfirmation);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Отправлено на проверку!'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/student/home');
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Text(
        "Сохранить",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statusButton(
    BuildContext context,
    AttendanceStatus status,
    String studentId,
  ) {
    return SizedBox(
      width: 85,
      height: 85,
      child: ElevatedButton(
        onPressed: () {
          ref
              .read(lessonAttendanceMarkProvider.notifier)
              .setAttendanceStatus(studentId, status);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: status.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          padding: const EdgeInsets.all(8),
        ),
        child: Text(
          status.label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
