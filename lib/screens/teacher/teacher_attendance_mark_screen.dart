import 'package:edu_att/models/attendance_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/providers/group_provider.dart';
import 'package:edu_att/providers/lesson_attendance_mark_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/services/lesson_service.dart';

class TeacherAttendanceMarkScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceMarkScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceMarkScreen> createState() =>
      _TeacherAttendanceMarkScreenState();
}

class _TeacherAttendanceMarkScreenState
    extends ConsumerState<TeacherAttendanceMarkScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final students = ref.watch(groupStudentsProvider);
    final attendanceList = ref.watch(lessonAttendanceMarkProvider);
    final lesson = ref.watch(currentLessonProvider);

    if (students.isEmpty || attendanceList.isEmpty) {
      return _loadingScreen(context);
    }

    if (students.isEmpty || attendanceList.isEmpty) {
      return _loadingScreen(context);
    }

    final student = students[currentIndex];
    final studentAttendance = attendanceList.firstWhere(
      (a) => a.studentId == student.id,
      orElse: () => attendanceList.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("Отметка посещаемости"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/teacher/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Карточка студента ---
            _buildStudentCard(context, student),

            const SizedBox(height: 32),

            // --- Текущий статус ---
            _buildCurrentStatus(context, studentAttendance),

            const SizedBox(height: 40),

            // --- Кнопки выбора ---
            _buildActionButtons(context, student.id!),

            const SizedBox(height: 60),

            // --- Управление навигацией и Подтверждение ---
            _buildNavigationControls(context, students.length, lesson),
          ],
        ),
      ),
    );
  }

  Widget _loadingScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentModel student) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
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

  Widget _buildCurrentStatus(BuildContext context, var attendance) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Текущий статус: ${attendance.status?.label ?? 'не отмечен'}",
        style: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String studentId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statusButton(context, AttendanceStatus.present, studentId),
        _statusButton(context, AttendanceStatus.absent, studentId),
        _statusButton(context, AttendanceStatus.late, studentId),
      ],
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

  Widget _buildNavigationControls(BuildContext context, int total, var lesson) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Назад
        currentIndex > 0
            ? IconButton(
              icon: Icon(
                Icons.chevron_left,
                size: 40,
                color: colorScheme.primary,
              ),
              onPressed: () => setState(() => currentIndex--),
            )
            : const SizedBox(width: 48),

        // Счетчик
        Text(
          "${currentIndex + 1} / $total",
          style: TextStyle(
            fontSize: 18,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Вперед или Подтвердить
        if (currentIndex < total - 1)
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              size: 40,
              color: colorScheme.primary,
            ),
            onPressed: () => setState(() => currentIndex++),
          )
        else
          _buildConfirmButton(context, lesson),
      ],
    );
  }

  Widget _buildConfirmButton(BuildContext context, var lesson) {
    return ElevatedButton(
      onPressed: () async {
        try {
          // 1. Сохраняем данные
          await ref
              .read(lessonAttendanceMarkProvider.notifier)
              .saveAttendance();

          // 2. Ставим статус "Confirmed"
          if (lesson?.id != null) {
            await LessonService.updateLessonStatus(
              lesson!.id!,
              LessonAttendanceStatus.confirmed,
            );
            ref
                .read(currentLessonProvider.notifier)
                .updateStatus(LessonAttendanceStatus.confirmed);
          }

          if (context.mounted) {
            context.go('/teacher/home');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ведомость подтверждена!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          print("Ошибка сохранения: $e");
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Text(
        "Подтвердить",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
