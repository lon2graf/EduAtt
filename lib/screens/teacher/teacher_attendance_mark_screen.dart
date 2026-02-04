import 'package:edu_att/models/attendance_status.dart'; // 1. Импорт Enum
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
    final students = ref.watch(groupStudentsProvider);
    final attendanceList = ref.watch(lessonAttendanceMarkProvider);
    final lesson = ref.watch(currentLessonProvider);

    if (students.isNotEmpty && attendanceList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(lessonAttendanceMarkProvider.notifier)
            .initializeAttendance(students, lesson);
      });
    }

    if (students.isEmpty || attendanceList.isEmpty) {
      return _loadingScreen();
    }

    final student = students[currentIndex];
    // Безопасное получение статуса
    final studentAttendance = attendanceList.firstWhere(
      (a) => a.studentId == student.id,
      orElse: () => attendanceList.first,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStudentCard(student),
                      const SizedBox(height: 24),
                      _buildCurrentStatus(
                        studentAttendance,
                      ), // Передаем модель целиком
                      const SizedBox(height: 36),
                      _buildActionButtons(student.id!),
                      const SizedBox(height: 36),
                      _buildNavigationControls(students.length),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => context.go('/teacher/home'),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    "Отметка посещаемости",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(StudentModel student) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
      ),
      child: Column(
        children: [
          Text(
            student.name,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            student.surname,
            style: const TextStyle(fontSize: 20, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  // 2. Используем label из Enum
  Widget _buildCurrentStatus(attendance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        "Текущий статус: ${attendance.status?.label ?? 'не отмечен'}",
        style: const TextStyle(fontSize: 16, color: Colors.white60),
      ),
    );
  }

  // 3. Используем Enum в кнопках
  Widget _buildActionButtons(String studentId) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statusButton(AttendanceStatus.present, studentId),
        _statusButton(AttendanceStatus.absent, studentId),
        _statusButton(AttendanceStatus.late, studentId),
      ],
    );
  }

  // 4. Метод принимает AttendanceStatus и берет цвет/текст из него
  Widget _statusButton(AttendanceStatus status, String studentId) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          ref
              .read(lessonAttendanceMarkProvider.notifier)
              .setAttendanceStatus(studentId, status);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: status.color.withOpacity(0.9), // Цвет из Enum
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Text(
          status.label, // Текст из Enum
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildNavigationControls(int total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (currentIndex > 0)
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 36, color: Colors.white),
            onPressed: () => setState(() => currentIndex--),
          )
        else
          const SizedBox(width: 48),

        Text(
          "${currentIndex + 1} / $total",
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),

        if (currentIndex < total - 1)
          IconButton(
            icon: const Icon(
              Icons.chevron_right,
              size: 36,
              color: Colors.white,
            ),
            onPressed: () => setState(() => currentIndex++),
          )
        else
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final lesson = ref.read(currentLessonProvider);

                try {
                  // 1. Сохраняем данные посещаемости
                  await ref
                      .read(lessonAttendanceMarkProvider.notifier)
                      .saveAttendance();

                  // 2. Ставим статус "Confirmed"
                  if (lesson?.id != null) {
                    await LessonService.updateLessonStatus(
                      lesson!.id!,
                      LessonAttendanceStatus.confirmed,
                    );

                    // Обновляем локально, чтобы кнопка стала серой
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
              // Зеленый цвет для подтверждения
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: const Text(
                "Подтвердить",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
