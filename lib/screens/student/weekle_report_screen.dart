// lib/screens/student/weekly_report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/current_lesson_provider.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/services/student_service.dart';
import 'package:edu_att/utils/weekly_report_data_preparer.dart';
import 'package:edu_att/utils/pdf_generator.dart';
import 'package:printing/printing.dart';
import 'package:edu_att/models/student_model.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show Platform;

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final student = ref.watch(currentStudentProvider);

    if (student == null || !student.isHeadman) {
      return Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: double.infinity,
              height: constraints.maxHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4A148C),
                    Color(0xFF6A1B9A),
                    Color(0xFF7B1FA2),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                ),
                child: SafeArea(
                  child: Center(
                    child: Text(
                      'Доступно только старосте',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.06)),
            child: SafeArea(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: const Text(
                    'Создание ведомости',
                    style: TextStyle(color: Colors.white),
                  ),
                  centerTitle: true,
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Выберите любую дату недели,\nчтобы сформировать ведомость',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed:
                              () =>
                                  _selectWeekAndGenerate(context, ref, student),
                          icon: const Icon(
                            Icons.calendar_today,
                            color: Colors.white,
                          ),
                          label: const Text('Выбрать дату'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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
            content: Text('За неделю:\n$period'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Создать'),
              ),
            ],
          ),
    );
    if (confirm != true) return;

    try {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }
}
