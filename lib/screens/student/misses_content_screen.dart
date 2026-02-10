import 'package:edu_att/models/attendance_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';

class MissesContentScreen extends ConsumerStatefulWidget {
  const MissesContentScreen({super.key});

  @override
  ConsumerState<MissesContentScreen> createState() =>
      _MissesContentScreenState();
}

class _MissesContentScreenState extends ConsumerState<MissesContentScreen> {
  DateTime _selectedDate = DateTime.now();

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final List<LessonAttendanceModel> allAttendances = ref.watch(
      attendanceProvider,
    );
    final student = ref.watch(currentStudentProvider);

    List<LessonAttendanceModel> filteredRecords =
        LessonsAttendanceService.filterAttendancesByDate(
          allAttendances,
          _selectedDate,
        );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildDateNavigationHeader(context),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  if (student?.id != null) {
                    await ref
                        .read(attendanceProvider.notifier)
                        .loadStudentAttendances(student!.id!);
                  }
                },
                child: _buildAttendanceList(context, filteredRecords),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigationHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousDay,
            icon: Icon(
              Icons.chevron_left,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getWeekdayName(_selectedDate.weekday).toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      '${_selectedDate.day} ${_getMonthName(_selectedDate.month).toUpperCase()}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _goToNextDay,
            icon: Icon(
              Icons.chevron_right,
              size: 32,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(
    BuildContext context,
    List<LessonAttendanceModel> records,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: colorScheme.outline.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Занятий не найдено',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder:
          (context, index) => _buildAttendanceCard(context, records[index]),
    );
  }

  Widget _buildAttendanceCard(
    BuildContext context,
    LessonAttendanceModel record,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusEnum = record.status;
    final Color statusColor = statusEnum?.color ?? Colors.grey;

    IconData statusIcon = Icons.help_outline_rounded;
    if (statusEnum == AttendanceStatus.present)
      statusIcon = Icons.check_circle_rounded;
    if (statusEnum == AttendanceStatus.absent)
      statusIcon = Icons.event_busy_rounded;
    if (statusEnum == AttendanceStatus.late)
      statusIcon = Icons.access_time_filled_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        if (record.subjectName != null) {
                          context.push(
                            '/student/subject_absences?subject=${Uri.encodeComponent(record.subjectName!)}',
                          );
                        }
                      },
                      child: Text(
                        record.subjectName ?? 'Предмет не указан',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          decoration:
                              statusEnum == AttendanceStatus.absent
                                  ? TextDecoration.underline
                                  : null,
                        ),
                      ),
                    ),
                    Text(
                      '${record.lessonStart ?? '??'} - ${record.lessonEnd ?? '??'}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Преподаватель: ${record.teacherName ?? ''} ${record.teacherSurname ?? ''}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusEnum?.label ?? 'Не отмечено',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const days = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    return (weekday >= 1 && weekday <= 7) ? days[weekday - 1] : '';
  }

  String _getMonthName(int month) {
    const months = [
      'Января',
      'Февраля',
      'Марта',
      'Апреля',
      'Мая',
      'Июня',
      'Июля',
      'Августа',
      'Сентября',
      'Октября',
      'Ноября',
      'Декабря',
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : '';
  }
}
