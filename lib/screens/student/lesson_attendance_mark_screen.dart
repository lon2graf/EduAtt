import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
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
    final students = ref.watch(groupStudentsProvider);
    final attendanceList = ref.watch(lessonAttendanceMarkProvider);

    if (students.isNotEmpty && attendanceList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(lessonAttendanceMarkProvider.notifier)
            .initializeAttendance(
              students,
              ref.read(currentLessonProvider), // если нужен текущий урок
            );
      });
    }

    if (students.isEmpty || attendanceList.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A148C), // Глубокий фиолетовый
              Color(0xFF6A1B9A), // Темно-фиолетовый
              Color(0xFF7B1FA2), // Ярче посередине
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final currentStudent = students[currentStudentIndex];
    final currentAttendance = attendanceList.firstWhere(
      (item) => item.studentId == currentStudent.id,
    );

    // --- Основной Scaffold ---
    return Scaffold(
      // Устанавливаем градиент как фон всего экрана
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF4A148C), // Глубокий фиолетовый
              Color(0xFF6A1B9A), // Темно-фиолетовый
              Color(0xFF7B1FA2), // Ярче посередине
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // --- AppBar ---
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4A148C), Color(0xFF6A1B9A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  // Тень для отделения от контента
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => context.go('/student/home'),
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
                      const SizedBox(width: 24), // Для симметрии
                    ],
                  ),
                ),
              ),
            ),

            // --- Основной контент ---
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                ), // Вуаль
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // --- Информация о студенте ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              currentStudent.name,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currentStudent.surname,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // --- Текущий статус ---
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Текущий статус: ${currentAttendance.status ?? 'не отмечен'}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white60,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // --- Кнопки для отметки ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statusButton(
                            "Присутствует",
                            Colors.green,
                            currentStudent.id!,
                          ),
                          _statusButton(
                            "Отсутствует",
                            Colors.red,
                            currentStudent.id!,
                          ),
                          _statusButton(
                            "Опоздал",
                            Colors.orange,
                            currentStudent.id!,
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // --- Переключатель студентов ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (currentStudentIndex > 0)
                            IconButton(
                              onPressed:
                                  () => setState(() => currentStudentIndex--),
                              icon: const Icon(
                                Icons.chevron_left,
                                size: 36,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(8.0),
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                            )
                          else
                            const SizedBox(width: 48),

                          Text(
                            "${currentStudentIndex + 1} / ${students.length}",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          if (currentStudentIndex < students.length - 1)
                            IconButton(
                              onPressed:
                                  () => setState(() => currentStudentIndex++),
                              icon: const Icon(
                                Icons.chevron_right,
                                size: 36,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(8.0),
                              constraints: const BoxConstraints(
                                minWidth: 48,
                                minHeight: 48,
                              ),
                            )
                          else
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await ref
                                      .read(
                                        lessonAttendanceMarkProvider.notifier,
                                      )
                                      .saveAttendance();
                                  context.go('/student/home');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                ),
                                child: const Text(
                                  "Сохранить",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
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

  Widget _statusButton(String label, Color color, String studentId) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ElevatedButton(
        onPressed: () {
          ref
              .read(lessonAttendanceMarkProvider.notifier)
              .setAttendanceStatus(studentId, label);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.9),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.15),
          padding: const EdgeInsets.all(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
