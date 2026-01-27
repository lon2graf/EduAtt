import 'package:edu_att/models/attendance_status.dart'; // Не забудь импортировать Enum!
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';

// Вкладка "Посещаемость"
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
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day - 1,
      );
    });
  }

  void _goToNextDay() {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + 1,
      );
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
    final List<LessonAttendanceModel> allAttendances = ref.watch(
      attendanceProvider,
    );
    final student = ref.watch(currentStudentProvider);

    List<LessonAttendanceModel> filteredRecords =
        LessonsAttendanceService.filterAttendancesByDate(
          allAttendances,
          _selectedDate,
        );

    // Используем LayoutBuilder, чтобы растянуть градиент на всё пространство
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
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
            ), // Вуаль
            child: SafeArea(
              child: Column(
                children: [
                  _buildDateNavigationHeader(),
                  const SizedBox(height: 14),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        if (student != null && student.id != null) {
                          await ref
                              .read(attendanceProvider.notifier)
                              .loadStudentAttendances(student.id!);
                        }
                      },
                      child: _buildAttendanceList(filteredRecords),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateNavigationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousDay,
            icon: const Icon(Icons.chevron_left, size: 36, color: Colors.white),
            padding: const EdgeInsets.all(6.0),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_getWeekdayName(_selectedDate.weekday).toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_selectedDate.day} ${_getMonthName(_selectedDate.month).toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _goToNextDay,
            icon: const Icon(
              Icons.chevron_right,
              size: 36,
              color: Colors.white,
            ),
            padding: const EdgeInsets.all(6.0),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList(List<LessonAttendanceModel> records) {
    if (records.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 56,
              color: Colors.white60,
            ),
            SizedBox(height: 14),
            Text(
              'Нет данных за эту дату',
              style: TextStyle(color: Colors.white60, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      itemCount: records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildAttendanceCard(LessonAttendanceModel record) {
    // 1. Парсим статус через наш Enum

    final statusEnum = record.status;

    // 2. Получаем данные из Enum (или дефолтные, если null)
    final Color statusColor = statusEnum?.color ?? Colors.orange;
    final String statusText = statusEnum?.label ?? 'Не указано';

    // 3. Выбираем иконку (можно тоже вынести в Enum, но пока так)
    IconData statusIcon;
    switch (statusEnum) {
      case AttendanceStatus.present:
        statusIcon = Icons.check_circle_rounded;
        break;
      case AttendanceStatus.absent:
        statusIcon = Icons.event_busy_rounded;
        break;
      case AttendanceStatus.late:
        statusIcon =
            Icons.access_time_rounded; // Или другая иконка для опоздания
        break;
      default:
        statusIcon = Icons.help_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    // Переход на экран детализации только для предметов с пропусками
                    // Используем Enum для проверки, что это именно отсутствие
                    if (record.subjectName != null) {
                      context.push(
                        '/student/subject_absences?subject=${Uri.encodeComponent(record.subjectName!)}',
                      );
                    }
                  },
                  child: Text(
                    record.subjectName ?? 'Предмет не указан',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      decoration:
                          // Подчеркиваем только если это пропуск (absent)
                          (record.subjectName != null &&
                                  statusEnum == AttendanceStatus.absent)
                              ? TextDecoration.underline
                              : TextDecoration.none,
                      decorationColor: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${record.lessonStart ?? '??'} - ${record.lessonEnd ?? '??'}',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            'Преподаватель: ${record.teacherName ?? ''} ${record.teacherSurname ?? ''}',
            style: const TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    if (weekday >= 1 && weekday <= 7) return days[weekday - 1];
    return '';
  }

  String _getMonthName(int month) {
    const months = [
      'Янв',
      'Фев',
      'Мар',
      'Апр',
      'Май',
      'Июн',
      'Июл',
      'Авг',
      'Сен',
      'Окт',
      'Ноя',
      'Дек',
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}
