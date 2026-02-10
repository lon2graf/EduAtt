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
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/services/lesson_service.dart';

class HomeContentScreen extends ConsumerStatefulWidget {
  const HomeContentScreen({super.key});

  @override
  ConsumerState<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends ConsumerState<HomeContentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final student = ref.read(currentStudentProvider);
    if (student != null) {
      await ref
          .read(attendanceProvider.notifier)
          .loadStudentAttendances(student.id!);
      await ref
          .read(currentLessonProvider.notifier)
          .loadCurrentLesson(student.groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final student = ref.watch(currentStudentProvider);
    final List<LessonAttendanceModel> allAttendances = ref.watch(
      attendanceProvider,
    );

    final DateTime now = DateTime.now();
    final int absencesCount = LessonsAttendanceService.countAbsencesForMonth(
      allAttendances,
      now,
    );

    return Scaffold(
      // backgroundColor подтянется автоматически
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Привет, ${student?.name ?? 'Студент'}! 😊',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Карточка статистики
              _buildCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статистика за месяц',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            absencesCount.toString(),
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _getAbsencesText(absencesCount),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Текущее занятие'),
              const SizedBox(height: 12),

              _buildCurrentLessonCard(context, student),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLessonCard(BuildContext context, StudentModel? student) {
    final lesson = ref.watch(currentLessonProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (lesson == null) {
      return _buildCard(
        context,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'Сейчас занятий нет',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLessonInfo(context, lesson),
          const SizedBox(height: 20),
          _buildActionButtons(context, lesson, student),
        ],
      ),
    );
  }

  Widget _buildLessonInfo(BuildContext context, LessonModel lesson) {
    final colorScheme = Theme.of(context).colorScheme;

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
              Icons.person_outline,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              'Преподаватель: $teacherFullName',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    LessonModel lesson,
    StudentModel? student,
  ) {
    bool isHeadman = student?.isHeadman == true;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
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
        if (isHeadman && lesson.id != null) ...[
          const SizedBox(height: 12),
          _buildHeadmanAction(context, lesson),
        ],
      ],
    );
  }

  Widget _buildHeadmanAction(BuildContext context, LessonModel lesson) {
    final colorScheme = Theme.of(context).colorScheme;

    bool isLocked =
        lesson.status == LessonAttendanceStatus.onTeacherEditing ||
        lesson.status == LessonAttendanceStatus.confirmed ||
        lesson.status == LessonAttendanceStatus.waitConfirmation;

    if (isLocked) {
      String statusText;
      IconData statusIcon;

      switch (lesson.status) {
        case LessonAttendanceStatus.confirmed:
          statusText = "Ведомость закрыта";
          statusIcon = Icons.lock_outline;
          break;
        case LessonAttendanceStatus.waitConfirmation:
          statusText = "На проверке";
          statusIcon = Icons.hourglass_empty;
          break;
        default:
          statusText = "Заполняет преподаватель";
          statusIcon = Icons.edit_off_outlined;
          break;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(statusIcon, color: colorScheme.onSurfaceVariant, size: 18),
            const SizedBox(width: 10),
            Text(
              statusText,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    String labelText = 'Отметить посещаемость';
    Color btnColor = colorScheme.primary;
    if (lesson.status == LessonAttendanceStatus.onHeadmanEditing) {
      labelText = 'Продолжить отмечать';
      btnColor = Colors.orange.shade800;
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          final freshStatus = await LessonService.getFreshStatus(lesson.id!);
          if (freshStatus != LessonAttendanceStatus.free &&
              freshStatus != LessonAttendanceStatus.onHeadmanEditing) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Статус изменился. Доступ закрыт.'),
                ),
              );
              _loadInitialData();
            }
            return;
          }

          try {
            if (lesson.status == LessonAttendanceStatus.free) {
              await LessonService.updateLessonStatus(
                lesson.id!,
                LessonAttendanceStatus.onHeadmanEditing,
              );
              ref
                  .read(currentLessonProvider.notifier)
                  .updateStatus(LessonAttendanceStatus.onHeadmanEditing);
            }
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
        icon: const Icon(Icons.edit_square, size: 18),
        label: Text(labelText),
        style: ElevatedButton.styleFrom(
          backgroundColor: btnColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  String _getAbsencesText(int count) {
    if (count == 0) return 'пропусков';
    if (count == 1) return 'пропуск';
    if (count >= 2 && count <= 4) return 'пропуска';
    return 'пропусков';
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
