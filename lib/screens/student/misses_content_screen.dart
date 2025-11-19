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
    // ... (всё то же самое)
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
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (record.status?.toLowerCase()) {
      case 'присутствует':
        statusColor = Colors.green;
        statusText = 'Присутствует';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'отсутствует':
        statusColor = Colors.red;
        statusText = 'Отсутствует';
        statusIcon = Icons.event_busy_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Не указано';
        statusIcon = Icons.help_outline_rounded;
        break;
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
                child: Text(
                  record.subjectName ?? 'Предмет не указан',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
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
    switch (weekday) {
      case 1:
        return 'Пн';
      case 2:
        return 'Вт';
      case 3:
        return 'Ср';
      case 4:
        return 'Чт';
      case 5:
        return 'Пт';
      case 6:
        return 'Сб';
      case 7:
        return 'Вс';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Янв';
      case 2:
        return 'Фев';
      case 3:
        return 'Мар';
      case 4:
        return 'Апр';
      case 5:
        return 'Май';
      case 6:
        return 'Июн';
      case 7:
        return 'Июл';
      case 8:
        return 'Авг';
      case 9:
        return 'Сен';
      case 10:
        return 'Окт';
      case 11:
        return 'Ноя';
      case 12:
        return 'Дек';
      default:
        return '';
    }
  }
}
