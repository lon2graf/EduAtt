import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/services/student_service.dart';
import 'package:edu_att/utils/pdf_generator.dart';
import 'package:edu_att/utils/weekly_report_data_preparer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final student = ref.watch(currentStudentProvider);

    // 1. Проверка прав доступа (если не староста)
    if (student == null || !student.isHeadman) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_person_outlined,
                  size: 80,
                  color: colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'Доступ ограничен',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Формирование ведомостей доступно только старосте группы.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2. Основной интерфейс для старосты
    return Scaffold(
      appBar: AppBar(title: const Text('Создание ведомости')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Красивая иконка-иллюстрация
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Выберите любую дату недели,\nчтобы сформировать PDF-ведомость',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed:
                      () => _selectWeekAndGenerate(context, ref, student),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text(
                    'Выбрать неделю',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Вспомогательные методы (логика без изменений, только форматирование) ---

  DateTime _getMonday(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  DateTime _getSunday(DateTime date) {
    final monday = _getMonday(date);
    return DateTime(monday.year, monday.month, monday.day + 6);
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatFilenameDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectWeekAndGenerate(
    BuildContext context,
    WidgetRef ref,
    StudentModel student,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (selectedDate == null) return;

    final monday = _getMonday(selectedDate);
    final sunday = _getSunday(selectedDate);
    final period = '${_formatDate(monday)} – ${_formatDate(sunday)}';

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Создать ведомость?'),
            content: Text('Период: $period'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: const Text('Создать'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      // Показываем индикатор загрузки (Snackbar или Dialog)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Генерация PDF...'),
          duration: Duration(seconds: 1),
        ),
      );

      final allStudents = await StudentServices.GetStudentsByGroupId(
        student.groupId,
      );
      final rawRecords =
          await LessonsAttendanceService.getWeeklyGroupAttendance(
            groupId: student.groupId,
            startDate: monday,
            endDate: sunday,
          );

      final reportData = WeeklyReportDataPreparer.prepareReportData(
        groupName: student.groupName ?? 'Группа',
        monday: monday,
        sunday: sunday,
        allGroupStudents: allStudents,
        rawRecords: rawRecords,
      );

      final pdfBytes = await generateAttendanceReportPdf(reportData);
      await Printing.sharePdf(
        bytes: Uint8List.fromList(pdfBytes),
        filename: 'vedomost_${_formatFilenameDate(monday)}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}
