import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Модели и Провайдеры
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/providers/group_provider.dart';
import 'package:edu_att/providers/lesson_attendance_mark_provider.dart';

// Сервисы и Утилиты
import 'package:edu_att/data/remote/lessons_attendace_service.dart';
import 'package:edu_att/data/remote/lesson_service.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';

// Маскот
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';

// --- ВСПОМОГАТЕЛЬНЫЙ ВИДЖЕТ: Пульсирующая точка ---
class LiveIndicator extends StatefulWidget {
  const LiveIndicator({super.key});

  @override
  State<LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<LiveIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// --- ОСНОВНОЙ ЭКРАН ---
class HomeContentScreen extends ConsumerStatefulWidget {
  const HomeContentScreen({super.key});

  @override
  ConsumerState<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends ConsumerState<HomeContentScreen> {
  Timer? _ticker;
  bool _isPreparing = false; // Состояние загрузки для кнопки старосты

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    // Обновляем UI каждую минуту для прогресс-бара
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
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
    final colorScheme = Theme.of(context).colorScheme;
    final student = ref.watch(currentStudentProvider);
    final lesson = ref.watch(currentLessonProvider);
    final allAttendances = ref.watch(attendanceProvider);

    final absencesCount = LessonsAttendanceService.countAbsencesForMonth(
      allAttendances,
      DateTime.now(),
    );

    // Realtime слушатель перехвата
    ref.listen<LessonModel?>(currentLessonProvider, (prev, next) {
      if (prev?.status != next?.status &&
          next?.status == LessonAttendanceStatus.onTeacherEditing) {
        EduSnackBar.showForbidden(context, ref);
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 24),
            _buildHeader(context, student),
            const SizedBox(height: 24),
            _buildStatsRow(context, absencesCount, allAttendances.length),
            const SizedBox(height: 32),
            _buildSectionTitle(context, 'Активное занятие'),
            const SizedBox(height: 12),

            lesson != null
                ? _buildLiveLessonCard(context, lesson, student, allAttendances)
                : _buildNoLessonState(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, StudentModel? student) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Привет,',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            Text(
              '${student?.name ?? 'Студент'}! 👋',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const EduMascot(state: MascotState.idle, height: 45),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, int absences, int total) {
    final attendanceRate =
        total > 0 ? ((total - absences) / total * 100).toInt() : 100;
    return Row(
      children: [
        _buildSmallStatCard(
          context,
          '$attendanceRate%',
          'Посещаемость',
          Icons.analytics_outlined,
        ),
        const SizedBox(width: 12),
        _buildSmallStatCard(
          context,
          absences.toString(),
          'Пропусков',
          Icons.event_busy_outlined,
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveLessonCard(
    BuildContext context,
    LessonModel lesson,
    StudentModel? student,
    List<LessonAttendanceModel> attendances,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    double progress = _calculateTimeProgress(lesson.startTime, lesson.endTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLiveBadge(),
              Text(
                '${lesson.startTime} - ${lesson.endTime}',
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            lesson.subjectName ?? 'Предмет',
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Преподаватель: ${lesson.teacherName}',
            style: TextStyle(
              color: colorScheme.onPrimary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 20),
          _buildStatusInfoText(lesson), // Статус (редактируется и т.д.)

          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colorScheme.onPrimary.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
            ),
          ),

          const SizedBox(height: 24),
          _buildCardActions(context, lesson, student, attendances),
        ],
      ),
    );
  }

  Widget _buildStatusInfoText(LessonModel lesson) {
    String text = "Занятие активно";
    if (lesson.status == LessonAttendanceStatus.onTeacherEditing)
      text = "📝 Преподаватель вносит правки";
    if (lesson.status == LessonAttendanceStatus.waitConfirmation)
      text = "⏳ Ведомость на проверке";
    if (lesson.status == LessonAttendanceStatus.confirmed)
      text = "✅ Учет завершен";

    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LiveIndicator(),
          SizedBox(width: 8),
          Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardActions(
    BuildContext context,
    LessonModel lesson,
    StudentModel? student,
    List<LessonAttendanceModel> attendances,
  ) {
    if (student == null) return const SizedBox.shrink();

    // Проверяем, отмечен ли уже студент
    final bool isMarked = attendances.any(
      (a) => a.lessonId == lesson.id && a.status == AttendanceStatus.present,
    );

    return Row(
      children: [
        // ЧАТ
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: () => context.go('/lesson_chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Icon(Icons.chat_bubble_outline, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        // ДЕЙСТВИЕ
        Expanded(
          flex: 5,
          child:
              student.isHeadman
                  ? _buildHeadmanButton(context, lesson)
                  : _buildStudentPresenceButton(
                    context,
                    lesson,
                    student,
                    isMarked,
                  ),
        ),
      ],
    );
  }

  Widget _buildStudentPresenceButton(
    BuildContext context,
    LessonModel lesson,
    StudentModel student,
    bool isMarked,
  ) {
    return ElevatedButton(
      onPressed:
          isMarked
              ? null
              : () async {
                try {
                  await LessonsAttendanceService.markSelfPresent(
                    lessonId: lesson.id!,
                    studentId: student.id!,
                  );
                  await _loadInitialData();
                  if (context.mounted)
                    EduSnackBar.showSuccess(context, ref, "Вы в списке! 🐾");
                } catch (e) {
                  if (context.mounted)
                    EduSnackBar.showError(context, ref, "Ошибка отметки");
                }
              },
      style: ElevatedButton.styleFrom(
        backgroundColor: isMarked ? Colors.green.shade400 : Colors.white,
        foregroundColor: isMarked ? Colors.white : Colors.green.shade800,
        disabledBackgroundColor: Colors.white.withOpacity(0.3),
        disabledForegroundColor: Colors.white60,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        isMarked ? "ВЫ ОТМЕЧЕНЫ ✅" : "Я НА ПАРЕ",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeadmanButton(BuildContext context, LessonModel lesson) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isLocked = lesson.status == LessonAttendanceStatus.onTeacherEditing;

    return ElevatedButton.icon(
      onPressed:
          (isLocked || _isPreparing)
              ? () => isLocked ? EduSnackBar.showForbidden(context, ref) : null
              : () async {
                setState(() => _isPreparing = true);
                try {
                  // 1. ПРОВЕРКА: берем свежий статус из БД перед началом
                  final freshStatus = await LessonService.getFreshStatus(
                    lesson.id!,
                  );
                  if (freshStatus != LessonAttendanceStatus.free &&
                      freshStatus != LessonAttendanceStatus.onHeadmanEditing) {
                    EduSnackBar.showInfo(
                      context,
                      ref,
                      "Статус изменился. Фрося обновляет данные...",
                    );
                    _loadInitialData();
                    return;
                  }

                  // 2. КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: Меняем статус на "Староста редактирует" в БД
                  if (lesson.status == LessonAttendanceStatus.free) {
                    await LessonService.updateLessonStatus(
                      lesson.id!,
                      LessonAttendanceStatus.onHeadmanEditing,
                    );
                    // Обновляем локально, чтобы UI сразу среагировал
                    ref
                        .read(currentLessonProvider.notifier)
                        .updateStatus(LessonAttendanceStatus.onHeadmanEditing);
                  }

                  // 3. Грузим данные для ведомости
                  await ref
                      .read(groupStudentsProvider.notifier)
                      .loadGroupStudents(lesson.groupId);
                  final students = ref.read(groupStudentsProvider);
                  await ref
                      .read(lessonAttendanceMarkProvider.notifier)
                      .initializeAttendance(students, lesson);

                  if (context.mounted) {
                    context.go('/student/mark');
                  }
                } catch (e) {
                  if (context.mounted)
                    EduSnackBar.showError(
                      context,
                      ref,
                      "Не удалось занять ведомость",
                    );
                } finally {
                  if (mounted) setState(() => _isPreparing = false);
                }
              },
      icon:
          _isPreparing
              ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Icon(
                isLocked ? Icons.lock_outline : Icons.edit_square,
                size: 20,
              ),
      label: Text(
        _isPreparing
            ? "ЗАГРУЗКА..."
            : (isLocked ? "ЗАБЛОКИРОВАНО" : "ВЕДОМОСТЬ"),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isLocked ? Colors.white.withOpacity(0.3) : Colors.white,
        foregroundColor: isLocked ? Colors.white70 : colorScheme.primary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  double _calculateTimeProgress(String startStr, String endStr) {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final start = today.add(
        Duration(
          hours: int.parse(startStr.split(':')[0]),
          minutes: int.parse(startStr.split(':')[1]),
        ),
      );
      final end = today.add(
        Duration(
          hours: int.parse(endStr.split(':')[0]),
          minutes: int.parse(endStr.split(':')[1]),
        ),
      );
      if (now.isBefore(start)) return 0.0;
      if (now.isAfter(end)) return 1.0;
      return now.difference(start).inSeconds / end.difference(start).inSeconds;
    } catch (e) {
      return 0.0;
    }
  }

  Widget _buildNoLessonState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 60),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}
