import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/models/lesson_attendance_model.dart'; // Импортируем модель

// Вкладка "Посещаемость"
class MissesContentScreen extends ConsumerStatefulWidget {
  const MissesContentScreen({super.key}); // Добавим ключ

  @override
  ConsumerState<MissesContentScreen> createState() =>
      _MissesContentScreenState();
}

class _MissesContentScreenState extends ConsumerState<MissesContentScreen> {
  // Хранит выбранную дату
  DateTime _selectedDate = DateTime.now(); // По умолчанию - сегодня

  // Функция для переключения на предыдущий день
  void _goToPreviousDay() {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day - 1,
      );
    });
  }

  // Функция для переключения на следующий день
  void _goToNextDay() {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + 1,
      );
    });
  }

  // Функция для открытия календаря и выбора даты
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), // Минимальная дата для выбора
      lastDate: DateTime(2030), // Максимальная дата для выбора
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Получаем все данные посещаемости из провайдера (просто List)
    final List<LessonAttendanceModel> allAttendances = ref.watch(
      attendanceProvider,
    );
    final student = ref.watch(currentStudentProvider);

    // Фильтруем все записи для выбранной даты (все статусы)
    List<LessonAttendanceModel> filteredRecords =
        LessonsAttendanceService.filterAttendancesByDate(
          allAttendances,
          _selectedDate,
        ); // Без параметра status

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5A00FF), Color(0xFF0078FF), Color(0xFF00C6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.15)),
        child: SafeArea(
          child: Column(
            children: [
              // --- Верхняя панель навигации по датам ---
              _buildDateNavigationHeader(),
              const SizedBox(height: 16), // Отступ между панелью и списком
              // --- Список записей о посещаемости ---
              Expanded(
                child: RefreshIndicator(
                  // Добавим возможность обновления
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
  }

  // Вспомогательный метод для построения верхней панели
  Widget _buildDateNavigationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousDay,
            icon: const Icon(Icons.chevron_left, size: 40, color: Colors.white),
            // Увеличиваем область нажатия
            padding: const EdgeInsets.all(8.0),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          // Центральная дата - тапабельный элемент
          Expanded(
            child: GestureDetector(
              onTap: _selectDate, // Открывает календарь
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25), // Светлее фон
                  borderRadius: BorderRadius.circular(14), // Скругления
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ), // Тонкая обводка
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_getWeekdayName(_selectedDate.weekday).toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_selectedDate.day} ${_getMonthName(_selectedDate.month).toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
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
              size: 40,
              color: Colors.white,
            ),
            // Увеличиваем область нажатия
            padding: const EdgeInsets.all(8.0),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
    );
  }

  // Вспомогательный метод для построения списка посещаемости
  Widget _buildAttendanceList(List<LessonAttendanceModel> records) {
    if (records.isEmpty) {
      // Показываем сообщение, если нет данных за выбранный день
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Нет данных за эту дату',
              style: TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Возвращаем ListView с карточками посещаемости
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  // Вспомогательный метод для построения карточки посещаемости
  Widget _buildAttendanceCard(LessonAttendanceModel record) {
    // Определяем цвет и текст статуса
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (record.status?.toLowerCase()) {
      case 'present':
        statusColor = Colors.green;
        statusText = 'Присутствовал';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'absent':
        statusColor = Colors.red;
        statusText = 'Отсутствовал';
        statusIcon = Icons.event_busy_rounded;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Не указано';
        statusIcon = Icons.help_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.15), // Фон на основе статуса
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ), // Обводка на основе статуса
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
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
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  record.subjectName ?? 'Предмет не указан',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${record.lessonStart ?? '??'} - ${record.lessonEnd ?? '??'}',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Преподаватель: ${record.teacherName ?? ''} ${record.teacherSurname ?? ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          // Статус занятия
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Вспомогательные методы для форматирования даты
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Понедельник';
      case 2:
        return 'Вторник';
      case 3:
        return 'Среда';
      case 4:
        return 'Четверг';
      case 5:
        return 'Пятница';
      case 6:
        return 'Суббота';
      case 7:
        return 'Воскресенье';
      default:
        return '';
    }
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Января';
      case 2:
        return 'Февраля';
      case 3:
        return 'Марта';
      case 4:
        return 'Апреля';
      case 5:
        return 'Мая';
      case 6:
        return 'Июня';
      case 7:
        return 'Июля';
      case 8:
        return 'Августа';
      case 9:
        return 'Сентября';
      case 10:
        return 'Октября';
      case 11:
        return 'Ноября';
      case 12:
        return 'Декабря';
      default:
        return '';
    }
  }
}
