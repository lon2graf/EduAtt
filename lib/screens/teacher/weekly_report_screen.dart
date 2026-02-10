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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final teacher = ref.watch(teacherProvider);

    if (teacher == null) {
      return _buildAccessDenied(context);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ведомость по группе')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Иконка-иллюстрация
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.analytics_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Выберите группу и неделю',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Для формирования PDF-отчета',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),

              const SizedBox(height: 32),

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
                            style: TextStyle(color: colorScheme.onSurface),
                          ),
                        );
                      }).toList(),
                  onChanged:
                      (value) => setState(() => _selectedGroupId = value),
                  dropdownColor: colorScheme.surface,
                  decoration: InputDecoration(
                    labelText: 'Группа',
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                )
              else
                const CircularProgressIndicator(),

              const SizedBox(height: 24),

              // Кнопка генерации
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _selectWeekAndGenerate(context, teacher),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text(
                    'Создать ведомость',
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

  // --- Логика генерации (без изменений в алгоритме, только UI-фикс) ---

  Future<void> _selectWeekAndGenerate(
    BuildContext context,
    TeacherModel teacher,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;

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
            content: Text(
              'Группа: ${_groups.firstWhere((g) => g.id == _selectedGroupId).name}\nПериод: $period',
            ),
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
      final groupName =
          _groups.firstWhere((g) => g.id == _selectedGroupId).name;
      final allStudents = await StudentServices.GetStudentsByGroupId(
        _selectedGroupId!,
      );
      final rawRecords =
          await LessonsAttendanceService.getWeeklyGroupAttendance(
            groupId: _selectedGroupId!,
            startDate: monday,
            endDate: sunday,
          );

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

  // Методы форматирования
  DateTime _getMonday(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));
  DateTime _getSunday(DateTime date) =>
      _getMonday(date).add(const Duration(days: 6));
  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
  String _formatFilenameDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Widget _buildAccessDenied(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Доступ запрещён',
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }
}
