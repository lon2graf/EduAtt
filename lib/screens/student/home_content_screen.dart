import 'package:edu_att/services/lesson_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/providers/lesson_attendance_provider.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/providers/group_provider.dart';

class HomeContentScreen extends ConsumerWidget {
  const HomeContentScreen({super.key}); // Добавим ключ

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProvider);
    // Получаем все данные посещаемости из провайдера
    final List<LessonAttendanceModel> allAttendances = ref.watch(
      attendanceProvider,
    );

    // Рассчитываем статистику для текущего месяца
    final DateTime now = DateTime.now();
    final double attendancePercentage =
        LessonsAttendanceService.calculateAttendancePercentageForMonth(
          allAttendances,
          now,
        );
    final int absencesCount = LessonsAttendanceService.countAbsencesForMonth(
      allAttendances,
      now,
    );

    // Форматируем процент для отображения (например, "85.7%")
    String formattedPercentage = attendancePercentage.toStringAsFixed(1);

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
          child: RefreshIndicator(
            onRefresh: () async {
              if (student != null && student.id != null) {
                await ref
                    .read(attendanceProvider.notifier)
                    .loadStudentAttendances(student.id!);
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Приветствие
                  Text(
                    'Привет, ${student?.name ?? 'Студент'}! 😊',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔹 Краткая статистика (с реальными данными)
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Статистика за месяц',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _StatItem(
                          label: 'Пропущено:',
                          value: absencesCount.toString(),
                        ),
                        const SizedBox(height: 6),
                        _StatItem(
                          label: 'Посещаемость:',
                          value: '$formattedPercentage%',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 🔹 Текущее занятие
                  _buildSectionTitle('Текущее занятие'),
                  const SizedBox(height: 12),
                  _buildCurrentLessonCard(student, ref), // Передаем student
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Новый виджет для карточки текущего занятия (теперь с логикой для старосты)
  Widget _buildCurrentLessonCard(StudentModel? student, WidgetRef ref) {
    // Принимает StudentModel?
    // Здесь можно добавить логику для определения текущего занятия
    // Пока что заглушка
    const String subject = 'Математика';
    const String time = '09:00 - 10:30';
    const String teacher = 'Иванов И.И.';
    const String status = 'Присутствует'; // или 'Отсутствует', 'Опаздывает'

    Color statusColor = status == 'Присутствует' ? Colors.green : Colors.red;

    // Определяем, нужно ли показывать кнопку "Отметить"
    bool showMarkButton =
        student?.isHeadman ==
        true; // Проверяем, является ли пользователь старостой

    return _buildCard(
      height:
          showMarkButton
              ? 200
              : 160, // Увеличиваем высоту, если кнопка отображается
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // Центрируем вертикально
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            time,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Преподаватель: $teacher',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          // --- Условная кнопка "Отметить посещаемость" ---
          if (showMarkButton) ...[
            const SizedBox(height: 8), // Отступ перед кнопкой
            Align(
              // Выравнивание кнопки
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (student != null) {
                    ref
                        .read(groupStudentsProvider.notifier)
                        .loadGroupStudents(
                          student.groupId,
                        ); // Теперь student не null, можно использовать !.
                    await LessonService.getCurrentLesson(student.groupId);
                    print('Нажата кнопка "Отметить посещаемость"');
                  } else {
                    print(
                      'Ошибка: студент не определен при нажатии кнопки "Отметить"',
                    );
                  }
                },
                icon: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                ), // Иконка
                label: const Text('Отметить посещаемость группы'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.withOpacity(0.8), // Цвет кнопки
                  foregroundColor: Colors.white, // Цвет текста/иконки
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Скругления
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Вспомогательный виджет для строки статистики
  Widget _buildCard({required Widget child, double? height}) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// Вспомогательный виджет для строки статистики
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
