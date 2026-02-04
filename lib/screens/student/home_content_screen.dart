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
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/models/lesson_attendance_status.dart'; // Наш Enum
import 'package:edu_att/services/lesson_service.dart'; // Наш Сервис

// 1. Используем StatefulWidget для авто-загрузки данных
class HomeContentScreen extends ConsumerStatefulWidget {
  const HomeContentScreen({super.key});

  @override
  ConsumerState<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends ConsumerState<HomeContentScreen> {
  @override
  void initState() {
    super.initState();
    // Автоматическая загрузка при входе на экран
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final student = ref.read(currentStudentProvider);
    if (student != null) {
      // Грузим пропуски (для статистики)
      await ref
          .read(attendanceProvider.notifier)
          .loadStudentAttendances(student.id!);
      // Грузим текущий урок (для карточки)
      await ref
          .read(currentLessonProvider.notifier)
          .loadCurrentLesson(student.groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(currentStudentProvider);
    final List<LessonAttendanceModel> allAttendances = ref.watch(
      attendanceProvider,
    );

    final DateTime now = DateTime.now();
    final int absencesCount = LessonsAttendanceService.countAbsencesForMonth(
      allAttendances,
      now,
    );

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
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06)),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _loadInitialData, // Обновление по свайпу
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      _buildSectionTitle('Текущее занятие'),
                      const SizedBox(height: 10),

                      // Карточка урока с новой логикой
                      _buildCurrentLessonCard(student),
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

  // --- Карточка урока ---
  Widget _buildCurrentLessonCard(StudentModel? student) {
    final lesson = ref.watch(currentLessonProvider);

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

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Информация (Текст)
          _buildLessonInfo(lesson),

          const SizedBox(height: 16),

          // 2. Кнопки (Логика статусов)
          _buildActionButtons(lesson, student),
        ],
      ),
    );
  }

  Widget _buildLessonInfo(LessonModel lesson) {
    String formattedStartTime = _formatTime(lesson.startTime);
    String formattedEndTime = _formatTime(lesson.endTime);
    String teacherFullName =
        '${lesson.teacherName ?? ''} ${lesson.teacherSurname ?? ''}'.trim();
    if (teacherFullName.isEmpty) teacherFullName = 'Не указан';

    return Column(
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
      ],
    );
  }

  Widget _buildActionButtons(LessonModel lesson, StudentModel? student) {
    bool isHeadman = student?.isHeadman == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Кнопка ЧАТА (доступна всем)
        SizedBox(
          width: double.infinity,
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ),

        // Кнопка ОТМЕТИТЬ (только для старосты)
        if (isHeadman && lesson.id != null) ...[
          const SizedBox(height: 8),
          _buildHeadmanAction(lesson),
        ],
      ],
    );
  }

  // --- УМНАЯ КНОПКА СТАРОСТЫ ---
  Widget _buildHeadmanAction(LessonModel lesson) {
    // 1. СПИСОК БЛОКИРУЮЩИХ СТАТУСОВ
    // Теперь сюда входит и waitConfirmation
    bool isLocked =
        lesson.status == LessonAttendanceStatus.onTeacherEditing ||
        lesson.status == LessonAttendanceStatus.confirmed ||
        lesson.status == LessonAttendanceStatus.waitConfirmation;

    if (isLocked) {
      // Определяем текст сообщения для блокировки
      String statusText;
      IconData statusIcon;

      switch (lesson.status) {
        case LessonAttendanceStatus.confirmed:
          statusText = "Ведомость закрыта преподавателем";
          statusIcon = Icons.lock;
          break;
        case LessonAttendanceStatus.waitConfirmation:
          statusText = "Отправлено на проверку преподавателю";
          statusIcon = Icons.hourglass_top; // Иконка ожидания
          break;
        case LessonAttendanceStatus.onTeacherEditing:
        default:
          statusText = "Преподаватель заполняет ведомость";
          statusIcon = Icons.edit_off;
          break;
      }

      // Рисуем неактивную плашку с информацией
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: Colors.white38, size: 16),
            const SizedBox(width: 8),
            Text(
              statusText,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    // 2. АКТИВНАЯ КНОПКА (Только для Free и OnHeadmanEditing)
    String labelText = 'Отметить посещаемость';
    Color btnColor = const Color(0xFF7B1FA2);
    IconData btnIcon = Icons.edit_square;

    if (lesson.status == LessonAttendanceStatus.onHeadmanEditing) {
      labelText = 'Продолжить отмечать';
      btnColor = Colors.orange.shade700;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          // Check: Проверка перед входом
          final freshStatus = await LessonService.getFreshStatus(lesson.id!);

          // Если статус любой кроме Free или OnHeadmanEditing - не пускаем
          if (freshStatus != LessonAttendanceStatus.free &&
              freshStatus != LessonAttendanceStatus.onHeadmanEditing) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Статус урока уже был изменен преподавателем. Доступ закрыт.',
                  ),
                ),
              );
              _loadInitialData(); // Обновляем UI
            }
            return;
          }

          try {
            // Act: Занимаем урок, если он был свободен
            if (lesson.status == LessonAttendanceStatus.free) {
              await LessonService.updateLessonStatus(
                lesson.id!,
                LessonAttendanceStatus.onHeadmanEditing,
              );
              // Обновляем локально
              ref
                  .read(currentLessonProvider.notifier)
                  .updateStatus(LessonAttendanceStatus.onHeadmanEditing);
            }

            // Переход
            if (mounted) {
              await ref
                  .read(groupStudentsProvider.notifier)
                  .loadGroupStudents(lesson.groupId);
              context.go('/student/mark');
            }
          } catch (e) {
            print("Ошибка при входе: $e");
          }
        },
        icon: Icon(btnIcon, size: 16),
        label: Text(labelText, style: const TextStyle(fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ... (методы _getAbsencesText, _formatTime, _buildCard, _buildSectionTitle - без изменений) ...
  String _getAbsencesText(int count) {
    if (count == 0) return 'пропусков';
    if (count == 1) return 'пропуск';
    if (count >= 2 && count <= 4) return 'пропуска';
    return 'пропусков';
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '--:--';
    List<String> parts = timeString.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
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
