import 'package:edu_att/models/attendance_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для вибрации
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/providers/group_provider.dart';
import 'package:edu_att/providers/lesson_attendance_mark_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/data/remote/lesson_service.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';

class TeacherAttendanceMarkScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceMarkScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceMarkScreen> createState() =>
      _TeacherAttendanceMarkScreenState();
}

class _TeacherAttendanceMarkScreenState
    extends ConsumerState<TeacherAttendanceMarkScreen> {
  int currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

    final student = students[currentIndex];
    final studentAttendance = attendanceList.firstWhere(
      (a) => a.studentId == student.id,
      orElse: () => attendanceList.first,
    );

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Студент ${currentIndex + 1} / ${students.length}"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/teacher/home'),
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
                    selected: index == currentIndex,
                    onTap: () {
                      setState(() => currentIndex = index);
                      Navigator.pop(context); // Закрываем боковую панель
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Spacer(),
            // --- Карточка студента ---
            _buildStudentCard(context, student),

            const SizedBox(height: 32),

            // --- Кнопки выбора ---
            _buildStatusSelector(student.id!, studentAttendance.status),

            const Spacer(),

            // --- Управление навигацией и Подтверждение ---
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed:
                        currentIndex > 0
                            ? () {
                              HapticFeedback.lightImpact();
                              setState(() => currentIndex--);
                            }
                            : null,
                    icon: const Icon(Icons.chevron_left, size: 44),
                  ),
                  Text(
                    "${currentIndex + 1} / ${students.length}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  currentIndex < students.length - 1
                      ? IconButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() => currentIndex++);
                        },
                        icon: const Icon(Icons.chevron_right, size: 44),
                      )
                      : _buildConfirmButton(context, lesson),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingScreen(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EduMascot(state: MascotState.searching, height: 150),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Фрося готовит список...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(BuildContext context, StudentModel student) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
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
        color: colorScheme.surfaceVariant,
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

  Widget _buildConfirmButton(BuildContext context, var lesson) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton(
      onPressed: () async {
        try {
          await ref
              .read(lessonAttendanceMarkProvider.notifier)
              .saveAttendance();

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: const Text(
        "Подтвердить",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
