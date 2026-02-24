import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';

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
    final lesson = ref.watch(currentLessonProvider);

    final DateTime now = DateTime.now();
    final int absencesCount = LessonsAttendanceService.countAbsencesForMonth(
      allAttendances,
      now,
    );

    // Слушатель для Realtime изменений статуса
    ref.listen<LessonModel?>(currentLessonProvider, (previous, next) {
      if (previous?.status != next?.status) {
        if (next?.status == LessonAttendanceStatus.onTeacherEditing) {
          EduSnackBar.showForbidden(context, ref);
        } else if (next?.status == LessonAttendanceStatus.confirmed) {
          EduSnackBar.showSuccess(context, ref, 'Ведомость утверждена');
        }
      }
    });

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
                'Привет, ${student?.name ?? 'Студент'}! 👋',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Блок статистики
              _buildStatsCard(context, absencesCount),

              const SizedBox(height: 32),
              _buildSectionTitle(context, 'Текущее занятие'),
              const SizedBox(height: 12),

              // ОЦЕНКА СОСТОЯНИЯ: Урок есть или нет
              lesson != null
                  ? _buildActiveLessonCard(context, lesson, student)
                  : _buildNoLessonState(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. КАРТОЧКА АКТИВНОГО УРОКА ---
  Widget _buildActiveLessonCard(
    BuildContext context,
    LessonModel lesson,
    StudentModel? student,
  ) {
    return _buildCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLessonInfo(context, lesson),
          const SizedBox(height: 20),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 20),
          _buildCardActions(context, lesson, student),
        ],
      ),
    );
  }

  // --- 2. КНОПКИ ВНУТРИ КАРТОЧКИ ---
  Widget _buildCardActions(
    BuildContext context,
    LessonModel lesson,
    StudentModel? student,
  ) {
    if (student == null) return const SizedBox.shrink();

    return Row(
      children: [
        // Кнопка ЧАТА (Вспомогательная)
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/lesson_chat'),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text("Чат"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Кнопка ДЕЙСТВИЯ (Основная)
        Expanded(
          flex: 3,
          child:
              student.isHeadman
                  ? _buildHeadmanButton(context, lesson)
                  : _buildSelfCheckInButton(context, lesson, student),
        ),
      ],
    );
  }

  // Кнопка "Я ТУТ" для обычного студента
  Widget _buildSelfCheckInButton(
    BuildContext context,
    LessonModel lesson,
    StudentModel student,
  ) {
    return ElevatedButton.icon(
      onPressed: () async {
        try {
          await LessonsAttendanceService.markSelfPresent(
            lessonId: lesson.id!,
            studentId: student.id!,
          );
          if (context.mounted) {
            EduSnackBar.showSuccess(
              context,
              ref,
              "Вы в списке! Хорошей пары 🐾",
            );
          }
        } catch (e) {
          if (context.mounted)
            EduSnackBar.showError(context, ref, "Ошибка отметки");
        }
      },
      icon: const Icon(Icons.check_circle, size: 20),
      label: const Text("Я ТУТ", style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Кнопка для Старосты (Переход к ведомости)
  Widget _buildHeadmanButton(BuildContext context, LessonModel lesson) {
    final colorScheme = Theme.of(context).colorScheme;

    // Определяем состояния блокировки
    final bool isLockedByTeacher =
        lesson.status == LessonAttendanceStatus.onTeacherEditing;
    final bool isWaiting =
        lesson.status == LessonAttendanceStatus.waitConfirmation;
    final bool isConfirmed = lesson.status == LessonAttendanceStatus.confirmed;
    final bool isBlocked = isLockedByTeacher || isWaiting || isConfirmed;

    // Выбираем текст кнопки в зависимости от статуса
    String buttonText = "ВЕДОМОСТЬ";
    IconData buttonIcon = Icons.edit_square;

    if (isLockedByTeacher) {
      buttonText = "ПРЕПОДАВАТЕЛЬ ЗАПОЛНЯЕТ";
      buttonIcon = Icons.lock_person_outlined;
    } else if (isWaiting) {
      buttonText = "НА ПРОВЕРКЕ";
      buttonIcon = Icons.hourglass_empty;
    } else if (isConfirmed) {
      buttonText = "УТВЕРЖДЕНО";
      buttonIcon = Icons.verified_user_outlined;
    }

    return ElevatedButton.icon(
      onPressed: () {
        if (isLockedByTeacher) {
          // Если заблокировано преподом — Фрося-охранник
          EduSnackBar.showForbidden(context, ref);
        } else if (isWaiting) {
          EduSnackBar.showInfo(
            context,
            ref,
            "Ведомость уже отправлена. Ждём ответа преподавателя.",
          );
        } else if (isConfirmed) {
          EduSnackBar.showSuccess(
            context,
            ref,
            "Эта ведомость уже закрыта. Всё отлично!",
          );
        } else {
          // Если всё ок — идем на экран отметки
          context.go('/student/mark');
        }
      },
      icon: Icon(buttonIcon, size: 20),
      label: Text(
        buttonText,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        // Если заблокировано — делаем кнопку серой/тусклой
        backgroundColor:
            isBlocked
                ? colorScheme.onSurface.withOpacity(0.12)
                : colorScheme.primary,
        foregroundColor:
            isBlocked ? colorScheme.onSurface.withOpacity(0.38) : Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // --- 3. ЗАГЛУШКА: НЕТ УРОКА ---
  Widget _buildNoLessonState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          const EduMascot(state: MascotState.empty, height: 200),
          const SizedBox(height: 16),
          Text(
            'Пар пока нет, Фрося отдыхает...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // --- ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ (Инфо, Статистика) ---
  Widget _buildStatsCard(BuildContext context, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildCard(
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
                  count.toString(),
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getAbsencesText(count),
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
    );
  }

  Widget _buildLessonInfo(BuildContext context, LessonModel lesson) {
    final colorScheme = Theme.of(context).colorScheme;
    String teacherFullName =
        '${lesson.teacherName ?? ''} ${lesson.teacherSurname ?? ''}'.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lesson.subjectName ?? 'Предмет',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.access_time, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              '${_formatTime(lesson.startTime)} - ${_formatTime(lesson.endTime)}',
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
              'Преподаватель: ${teacherFullName.isEmpty ? 'Не указан' : teacherFullName}',
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
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
}
