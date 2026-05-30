import 'dart:async';

import 'package:edu_att/models/attendance_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/providers/group_provider.dart';
import 'package:edu_att/providers/lesson_attendance_mark_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';

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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Timer? _autoAdvanceTimer;

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleAutoAdvance(int total) {
    _autoAdvanceTimer?.cancel();
    if (currentIndex >= total - 1) return;
    _autoAdvanceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => currentIndex++);
    });
  }

  void _markAllPresent(List<StudentModel> students) {
    HapticFeedback.mediumImpact();
    final notifier = ref.read(lessonAttendanceMarkProvider.notifier);
    for (final student in students) {
      notifier.setAttendanceStatus(student.id!, AttendanceStatus.present);
    }
  }

  void _showMarkAllDialog(BuildContext context, List<StudentModel> students) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отметить всех?'),
        content: Text(
          'Все ${students.length} студентов получат статус «Присутствует».\n'
          'Отдельные отметки можно изменить после.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _markAllPresent(students);
            },
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Отметить всех'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final students = ref.watch(groupStudentsProvider);
    final attendanceList = ref.watch(lessonAttendanceMarkProvider);
    final lesson = ref.watch(currentLessonProvider);

    if (students.isEmpty || attendanceList.isEmpty) {
      return _loadingScreen(context);
    }

    final attendanceMap = {for (final a in attendanceList) a.studentId: a};

    final student = students[currentIndex];
    final studentAttendance = attendanceMap[student.id] ?? attendanceList.first;

    final unmarked = attendanceList.where((a) => a.status == null).length;

    final filteredStudents = _searchQuery.isEmpty
        ? students
        : students
            .where(
              (s) =>
                  '${s.surname} ${s.name}'
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()),
            )
            .toList();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          unmarked > 0
              ? 'Студент ${currentIndex + 1} / ${students.length}  •  осталось $unmarked'
              : 'Студент ${currentIndex + 1} / ${students.length}  ✓',
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/teacher/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Все присутствуют',
            onPressed: () => _showMarkAllDialog(context, students),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Список группы',
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: Column(
          children: [
            // Шапка с поиском
            Material(
              color: colorScheme.primary,
              elevation: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Список группы',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _searchQuery.isEmpty
                                ? '${students.length} чел.'
                                : '${filteredStudents.length} / ${students.length}',
                            style: TextStyle(
                              color: colorScheme.onPrimary.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Поиск по фамилии...',
                          hintStyle: TextStyle(
                            color: colorScheme.onPrimary.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onPrimary.withValues(alpha: 0.7),
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.clear,
                                    color: colorScheme.onPrimary
                                        .withValues(alpha: 0.7),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: colorScheme.onPrimary.withValues(alpha: 0.15),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Список студентов
            Expanded(
              child: filteredStudents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Не найдено',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final s = filteredStudents[index];
                        final fullIndex = students.indexOf(s);
                        final a = attendanceMap[s.id] ?? attendanceList.first;

                        String statusText = 'Не отмечен';
                        Color statusColor = Colors.grey;
                        if (a.status == AttendanceStatus.present) {
                          statusText = 'Есть';
                          statusColor = Colors.green;
                        } else if (a.status == AttendanceStatus.absent) {
                          statusText = 'Нет';
                          statusColor = Colors.red;
                        } else if (a.status == AttendanceStatus.late) {
                          statusText = 'Опоздал';
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
                          trailing: Icon(
                            Icons.circle,
                            size: 10,
                            color: statusColor,
                          ),
                          selected: fullIndex == currentIndex,
                          onTap: () {
                            _autoAdvanceTimer?.cancel();
                            setState(() {
                              currentIndex = fullIndex;
                              _searchController.clear();
                              _searchQuery = '';
                            });
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
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Spacer(),
            _buildStudentCard(context, student),
            const SizedBox(height: 32),
            _buildStatusSelector(student.id!, studentAttendance.status, students.length),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: currentIndex > 0
                        ? () {
                            HapticFeedback.lightImpact();
                            _autoAdvanceTimer?.cancel();
                            setState(() => currentIndex--);
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left, size: 44),
                  ),
                  Text(
                    '${currentIndex + 1} / ${students.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  currentIndex < students.length - 1
                      ? IconButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _autoAdvanceTimer?.cancel();
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
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
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
    int total,
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
            'Есть',
            Icons.check,
            Colors.green,
            currentStatus == AttendanceStatus.present,
            total,
          ),
          _statusOption(
            studentId,
            AttendanceStatus.absent,
            'Нет',
            Icons.close,
            Colors.red,
            currentStatus == AttendanceStatus.absent,
            total,
          ),
          _statusOption(
            studentId,
            AttendanceStatus.late,
            'Опоздал',
            Icons.access_time,
            Colors.orange,
            currentStatus == AttendanceStatus.late,
            total,
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
    int total,
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
            _scheduleAutoAdvance(total);
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
    return ElevatedButton(
      onPressed: () async {
        bool synced;
        try {
          synced = await ref
              .read(lessonAttendanceMarkProvider.notifier)
              .saveAttendance();
        } catch (e) {
          AppLogger.error(
            'Ошибка локального сохранения посещаемости',
            e,
            null,
            'TeacherAttendanceMarkScreen',
          );
          if (context.mounted) {
            EduSnackBar.showError(context, ref, 'Ошибка сохранения');
          }
          return;
        }

        await ref
            .read(currentLessonProvider.notifier)
            .updateLessonStatus(LessonAttendanceStatus.confirmed);

        if (context.mounted) {
          context.go('/teacher/home');
          if (synced) {
            EduSnackBar.showSuccess(context, ref, 'Ведомость подтверждена!');
          } else {
            EduSnackBar.showInfo(
              context,
              ref,
              'Сохранено локально, отправим при подключении',
            );
          }
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
        'Подтвердить',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
