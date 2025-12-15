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

class TeacherHomeContentScreen extends ConsumerWidget {
  const TeacherHomeContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                onRefresh: () async {
                  print("ищу текущее занятие");
                  if (teacher == null) return;
                  await ref
                      .read(currentLessonProvider.notifier)
                      .loadCurrentLessonForTeacher(teacher.id!);
                },

                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Приветствие
                      Text(
                        'Привет, ${teacher?.name ?? 'Преподаватель'}! 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Текущее занятие
                      _buildSectionTitle('Текущее занятие'),
                      const SizedBox(height: 10),
                      _buildCurrentLessonCard(ref, context, lesson),
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

  Widget _buildCurrentLessonCard(
    WidgetRef ref,
    BuildContext context,
    LessonModel? lesson,
  ) {
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
    String teacherFullName =
        '${lesson.teacherName ?? ''} ${lesson.teacherSurname ?? ''}'.trim();
    if (teacherFullName.isEmpty) teacherFullName = 'Не указан';

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
            'Преподаватель: $teacherFullName',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 12),

          // 🔹 Кнопка "Чат урока" — для всех преподавателей
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('/lesson_chat');
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: const Text('Чат урока', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade700,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 🔸 Кнопка "Отметить" (с логикой проверки)
          FutureBuilder<bool>(
            future: LessonsAttendanceService.isLessonMarked(lesson.id!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                );
              }

              final bool isMarked = snapshot.data ?? false;

              return ElevatedButton.icon(
                onPressed:
                    isMarked
                        ? null
                        : () async {
                          if (lesson.groupId.isNotEmpty) {
                            await ref
                                .read(groupStudentsProvider.notifier)
                                .loadGroupStudents(lesson.groupId);
                            if (context.mounted) {
                              context.go('/teacher/mark');
                            }
                          }
                        },
                icon: Icon(
                  isMarked
                      ? Icons.check_circle
                      : Icons.check_circle_outline_rounded,
                  size: 16,
                ),
                label: Text(
                  isMarked ? 'Уже отмечено' : 'Отметить',
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isMarked
                          ? Colors.white.withOpacity(0.1)
                          : Colors.purple.shade700,
                  foregroundColor: isMarked ? Colors.white60 : Colors.white,
                  elevation: isMarked ? 0 : 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '--:--';
    final parts = timeString.split(':');
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
