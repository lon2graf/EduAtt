import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/data/remote/lesson_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для вибрации
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/group_provider.dart';
import 'package:edu_att/providers/lesson_attendance_mark_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';

class AttendanceMarkScreen extends ConsumerStatefulWidget {
  const AttendanceMarkScreen({super.key});

  @override
  ConsumerState<AttendanceMarkScreen> createState() =>
      _AttendanceMarkScreenState();
}

class _AttendanceMarkScreenState extends ConsumerState<AttendanceMarkScreen> {
  int currentStudentIndex = 0;

  // Метод для безопасного выхода с освобождением статуса
  Future<void> _handleBackNavigation() async {
    final lesson = ref.read(currentLessonProvider);

    // Если мы выходим и ведомость была в режиме редактирования старостой - освобождаем её
    if (lesson != null &&
        lesson.status == LessonAttendanceStatus.onHeadmanEditing) {
      await LessonService.updateLessonStatus(
        lesson.id!,
        LessonAttendanceStatus.free,
      );
      ref
          .read(currentLessonProvider.notifier)
          .updateStatus(LessonAttendanceStatus.free);
    }

    if (mounted) context.go('/student/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final students = ref.watch(groupStudentsProvider);
    final attendanceList = ref.watch(lessonAttendanceMarkProvider);
    final lesson = ref.watch(currentLessonProvider);

    // 1. БЛОКИРОВКА ПРИ ПЕРЕХВАТЕ ПРЕПОДАВАТЕЛЕМ (Realtime)
    if (lesson?.status == LessonAttendanceStatus.onTeacherEditing) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EduMascot(state: MascotState.forbidden, height: 200),
                const SizedBox(height: 24),
                Text(
                  'Доступ ограничен',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Преподаватель перехватил управление ведомостью. Ваши правки больше не принимаются.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/student/home'),
                  child: const Text('Вернуться на главную'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. ЭКРАН ЗАГРУЗКИ С ФРОСЕЙ
    if (students.isEmpty || attendanceList.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EduMascot(state: MascotState.searching, height: 150),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                color: colorScheme.primary,
                strokeWidth: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Фрося готовит список...',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
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
          onPressed:
              _handleBackNavigation, // Шлифовка: вызов метода смены статуса
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const Spacer(),
            // --- Карточка студента ---
            _buildStudentCard(context, currentStudent),

            const SizedBox(height: 32),

            // --- Текущий статус (Текст) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
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

            const Spacer(),

            // --- Навигация и Сохранение ---
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Кнопка Назад
                  currentStudentIndex > 0
                      ? IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() => currentStudentIndex--);
                        },
                        icon: Icon(
                          Icons.chevron_left,
                          size: 44,
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

                  // Кнопка Вперед или Сохранить
                  if (currentStudentIndex < students.length - 1)
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => currentStudentIndex++);
                      },
                      icon: Icon(
                        Icons.chevron_right,
                        size: 44,
                        color: colorScheme.primary,
                      ),
                    )
                  else
                    _buildSaveButton(context, lesson),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, var student) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            student.name,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            student.surname,
            style: TextStyle(
              fontSize: 20,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
            EduSnackBar.showError(
              context,
              ref,
              "Управление перехвачено преподавателем!",
            );
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
            EduSnackBar.showSuccess(context, ref, "Отправлено на проверку! ✨");
            context.go('/student/home');
          }
        } catch (e) {
          if (context.mounted)
            EduSnackBar.showError(context, ref, "Ошибка: $e");
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          HapticFeedback.mediumImpact(); // Вибрация при выборе статуса
          ref
              .read(lessonAttendanceMarkProvider.notifier)
              .setAttendanceStatus(studentId, status);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: status.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
