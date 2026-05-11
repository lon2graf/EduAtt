import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/group_provider.dart';
import 'package:edu_att/providers/lesson_attendance_mark_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/providers/connectivity_provider.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _handleBackNavigation() async {
    final lesson = ref.read(currentLessonProvider);
    if (lesson != null &&
        lesson.status == LessonAttendanceStatus.onHeadmanEditing) {
      await ref
          .read(currentLessonProvider.notifier)
          .updateLessonStatus(LessonAttendanceStatus.free);
    }
    if (mounted) context.go('/student/home');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final students = ref.watch(groupStudentsProvider);
    final attendanceList = ref.watch(lessonAttendanceMarkProvider);
    final lesson = ref.watch(currentLessonProvider);
    final isOffline = ref.watch(isOfflineProvider);

    if (lesson?.status == LessonAttendanceStatus.onTeacherEditing) {
      return _buildLockedScreen(colorScheme);
    }

    if (students.isEmpty || attendanceList.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EduMascot(state: MascotState.searching, height: 150),
              const SizedBox(height: 20),
              CircularProgressIndicator(color: colorScheme.primary),
            ],
          ),
        ),
      );
    }

    final currentStudent = students[currentStudentIndex];
    final currentAttendance = attendanceList.firstWhere(
      (a) => a.studentId == currentStudent.id,
      orElse: () => attendanceList.first,
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Студент ${currentStudentIndex + 1} / ${students.length}"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: _handleBackNavigation,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colorScheme.primary),
              child: Center(
                child: Text(
                  "Список группы",
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final s = students[index];
                  final a = attendanceList.firstWhere(
                    (att) => att.studentId == s.id,
                  );
                  String statusText = "Не отмечен";
                  Color statusColor = Colors.grey;
                  if (a.status == AttendanceStatus.present) {
                    statusText = "Есть";
                    statusColor = Colors.green;
                  } else if (a.status == AttendanceStatus.absent) {
                    statusText = "Нет";
                    statusColor = Colors.red;
                  } else if (a.status == AttendanceStatus.late) {
                    statusText = "Опоздал";
                    statusColor = Colors.orange;
                  }

                  return ListTile(
                    title: Text('${s.surname} ${s.name}'),
                    subtitle: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(Icons.circle, size: 10, color: statusColor),
                    selected: index == currentStudentIndex,
                    onTap: () {
                      setState(() => currentStudentIndex = index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const Spacer(),
            _buildStudentCard(context, currentStudent),
            const SizedBox(height: 32),
            _buildStatusSelector(currentStudent.id!, currentAttendance.status),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed:
                        currentStudentIndex > 0
                            ? () => setState(() => currentStudentIndex--)
                            : null,
                    icon: const Icon(Icons.chevron_left, size: 44),
                  ),
                  Text(
                    "${currentStudentIndex + 1} / ${students.length}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  currentStudentIndex < students.length - 1
                      ? IconButton(
                        onPressed: () => setState(() => currentStudentIndex++),
                        icon: const Icon(Icons.chevron_right, size: 44),
                      )
                      : _buildSaveButton(context, lesson, isOffline),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            student.name,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            student.surname,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector(
    String studentId,
    AttendanceStatus? currentStatus,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _statusOption(
            studentId,
            AttendanceStatus.present,
            "Есть",
            Icons.check,
            Colors.green,
            currentStatus == AttendanceStatus.present,
          ),
          _statusOption(
            studentId,
            AttendanceStatus.absent,
            "Нет",
            Icons.close,
            Colors.red,
            currentStatus == AttendanceStatus.absent,
          ),
          _statusOption(
            studentId,
            AttendanceStatus.late,
            "Опоздал",
            Icons.access_time,
            Colors.orange,
            currentStatus == AttendanceStatus.late,
          ),
        ],
      ),
    );
  }

  Widget _statusOption(
    String studentId,
    AttendanceStatus status,
    String label,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.lightImpact();
            ref
                .read(lessonAttendanceMarkProvider.notifier)
                .setAttendanceStatus(studentId, status);
          },
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color : Colors.transparent,
            foregroundColor: isSelected ? Colors.white : Colors.black87,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, var lesson, bool isOffline) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton(
      onPressed: () async {
        if (isOffline) {
          EduSnackBar.showInfo(context, ref, "Для работы с ведомостью нужен интернет");
          return;
        }
        if (lesson == null) return;
        try {
          await ref
              .read(lessonAttendanceMarkProvider.notifier)
              .saveAttendance();
          await ref
              .read(currentLessonProvider.notifier)
              .updateLessonStatus(LessonAttendanceStatus.waitConfirmation);
          if (context.mounted) {
            EduSnackBar.showSuccess(context, ref, "Отправлено! ✨");
            context.go('/student/home');
          }
        } catch (e) {
          if (context.mounted) {
            EduSnackBar.showError(context, ref, "Ошибка: $e");
          }
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: const Text(
        "Сохранить",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLockedScreen(ColorScheme colorScheme) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EduMascot(state: MascotState.forbidden, height: 150),
            const SizedBox(height: 24),
            Text(
              'Доступ ограничен',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/student/home'),
              child: const Text('Вернуться'),
            ),
          ],
        ),
      ),
    );
  }
}
