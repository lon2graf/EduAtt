// lib/screens/teacher/teacher_weekly_report_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/services/lessons_attendace_service.dart';
import 'package:edu_att/services/student_service.dart';
import 'package:edu_att/services/group_service.dart';
import 'package:edu_att/utils/weekly_report_data_preparer.dart';
import 'package:edu_att/utils/pdf_generator.dart';
import 'package:printing/printing.dart';
import 'package:edu_att/models/teacher_model.dart';
import 'package:edu_att/models/group_model.dart';
import 'dart:typed_data';

class TeacherWeeklyReportScreen extends ConsumerStatefulWidget {
  const TeacherWeeklyReportScreen({super.key});

  @override
  ConsumerState<TeacherWeeklyReportScreen> createState() =>
      _TeacherWeeklyReportScreenState();
}

class _TeacherWeeklyReportScreenState
    extends ConsumerState<TeacherWeeklyReportScreen> {
  String? _selectedGroupId;
  List<GroupModel> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final teacher = ref.read(teacherProvider);
    if (teacher == null) return;

    try {
      final groups = await GroupService.getGroupsByInstitution(
        teacher.institutionId,
      );
      if (mounted) {
        setState(() {
          _groups = groups;
          _selectedGroupId = groups.isNotEmpty ? groups.first.id : null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки групп: $e')));
      }
    }
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
    TeacherModel teacher,
  ) async {
    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите группу')));
      return;
    }

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
      // Получаем название группы для PDF
      final groupName =
          _groups.firstWhere((g) => g.id == _selectedGroupId).name;

      // Загружаем студентов выбранной группы
      final allStudents = await StudentServices.GetStudentsByGroupId(
        _selectedGroupId!,
      );

      // Загружаем посещаемость
      final rawRecords =
          await LessonsAttendanceService.getWeeklyGroupAttendance(
            groupId: _selectedGroupId!,
            startDate: monday,
            endDate: sunday,
          );

      // Генерируем PDF
      final reportData = WeeklyReportDataPreparer.prepareReportData(
        groupName: groupName,
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teacher = ref.watch(teacherProvider);

    if (teacher == null) {
      return _buildAccessDenied();
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
                    'Ведомость по группе',
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
                          'Выберите группу и дату недели',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 24),

                        // Выбор группы
                        if (_groups.isNotEmpty)
                          DropdownButtonFormField<String>(
                            value: _selectedGroupId,
                            items:
                                _groups.map((group) {
                                  return DropdownMenuItem(
                                    value: group.id,
                                    child: Text(
                                      group.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGroupId = value;
                              });
                            },
                            dropdownColor: const Color(0xFF4A148C),
                            decoration: InputDecoration(
                              hintText: 'Выберите группу',
                              hintStyle: const TextStyle(color: Colors.white60),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Colors.white,
                            ),
                          )
                        else
                          const CircularProgressIndicator(color: Colors.white),

                        const SizedBox(height: 24),

                        // Кнопка генерации
                        ElevatedButton.icon(
                          onPressed:
                              () => _selectWeekAndGenerate(context, teacher),
                          icon: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.white,
                          ),
                          label: const Text('Создать ведомость'),
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

  Widget _buildAccessDenied() {
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
              child: Center(
                child: Text(
                  'Доступ запрещён',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
