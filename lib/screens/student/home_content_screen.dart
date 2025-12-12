import 'package:edu_att/services/lesson_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/providers/group_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';

class HomeContentScreen extends ConsumerWidget {
  const HomeContentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProvider);
    final List<LessonAttendanceModel> allAttendances = ref.watch(
      attendanceProvider,
    );

    final DateTime now = DateTime.now();
    final int absencesCount = LessonsAttendanceService.countAbsencesForMonth(
      allAttendances,
      now,
    );

    // Теперь используем LayoutBuilder, чтобы растянуть градиент на всё пространство
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight, // Растягиваем на всю высоту
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
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06)),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (student != null && student.id != null) {
                    await ref
                        .read(attendanceProvider.notifier)
                        .loadStudentAttendances(student.id!);
                    await ref
                        .read(currentLessonProvider.notifier)
                        .loadCurrentLesson(student.groupId);
                  }
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🔹 Приветствие
                      Text(
                        'Привет, ${student?.name ?? 'Студент'}! 😊',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 🔹 Краткая статистика
                      _buildCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Статистика за месяц',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    absencesCount.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getAbsencesText(absencesCount),
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 🔹 Текущее занятие
                      _buildSectionTitle('Текущее занятие'),
                      const SizedBox(height: 10),
                      _buildCurrentLessonCard(student, ref, context),
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

  String _getAbsencesText(int count) {
    if (count == 0) return 'пропусков';
    if (count == 1) return 'пропуск';
    if (count >= 2 && count <= 4) return 'пропуска';
    return 'пропусков';
  }

  Widget _buildCurrentLessonCard(
    StudentModel? student,
    WidgetRef ref,
    BuildContext context,
  ) {
    final lesson = ref.watch(currentLessonProvider);

    // !!! 1. Получаем список всех посещений студента (старосты)
    final allAttendances = ref.watch(attendanceProvider);

    if (lesson == null) {
      return _buildCard(
        child: const Center(
          child: Text(
            'Сейчас занятий нет',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    // !!! 2. Проверяем, есть ли уже отметка для ЭТОГО урока
    // (ищем в списке посещений запись с таким же lessonId)
    final bool isAlreadyMarked = allAttendances.any(
      (attendance) => attendance.lessonId == lesson.id,
    );

    String formattedStartTime = _formatTime(lesson.startTime);
    String formattedEndTime = _formatTime(lesson.endTime);

    String teacherFullName =
        '${lesson.teacherName ?? ''} ${lesson.teacherSurname ?? ''}'.trim();
    if (teacherFullName.isEmpty) {
      teacherFullName = 'Не указан';
    }

    // Кнопку показываем только старосте
    bool showMarkButton = student?.isHeadman == true;

    return _buildCard(
      height: showMarkButton ? 160 : 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            lesson.subjectName ?? 'Предмет',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$formattedStartTime - $formattedEndTime',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'Преподаватель: $teacherFullName',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),

          if (showMarkButton) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                // !!! 3. Блокируем кнопку, если уже отмечено
                onPressed:
                    isAlreadyMarked
                        ? null // Если null, кнопка станет серой и неактивной
                        : () async {
                          if (student != null) {
                            ref
                                .read(groupStudentsProvider.notifier)
                                .loadGroupStudents(student.groupId);
                            context.go('/student/mark');
                          }
                        },
                // !!! 4. Меняем иконку в зависимости от статуса
                icon: Icon(
                  isAlreadyMarked
                      ? Icons
                          .check_circle // Галочка, если уже отмечено
                      : Icons.edit_square, // Карандаш, если нужно отметить
                  size: 16,
                ),
                // !!! 5. Меняем текст кнопки
                label: Text(
                  isAlreadyMarked ? 'Уже отмечено' : 'Отметить',
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  // !!! 6. Меняем цвет: серый если отмечено, фиолетовый если нет
                  backgroundColor:
                      isAlreadyMarked
                          ? Colors.white.withOpacity(0.1)
                          : Colors.purple.shade700,
                  foregroundColor:
                      isAlreadyMarked ? Colors.white60 : Colors.white,
                  elevation: isAlreadyMarked ? 0 : 4,
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
          ],
        ],
      ),
    );
  }

  // Вспомогательный метод для форматирования времени
  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '--:--';
    List<String> parts = timeString.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}'; // Возвращаем HH:mm
    }
    return timeString; // Если формат непонятный, возвращаем как есть
  }

  Widget _buildCard({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.8),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
