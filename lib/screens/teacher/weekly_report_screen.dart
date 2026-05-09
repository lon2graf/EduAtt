import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/data/remote/lessons_attendace_service.dart';
import 'package:edu_att/data/remote/student_service.dart';
import 'package:edu_att/data/repositories/group_repository.dart';
import 'package:edu_att/utils/weekly_report_data_preparer.dart';
import 'package:edu_att/utils/pdf_generator.dart';
import 'package:printing/printing.dart';
import 'package:edu_att/models/teacher_model.dart';
import 'package:edu_att/models/group_model.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';

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
  StreamSubscription<List<GroupModel>>? _groupSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initGroups());
  }

  @override
  void dispose() {
    _groupSub?.cancel();
    super.dispose();
  }

  void _initGroups() {
    final teacher = ref.read(teacherProvider);
    if (teacher == null) return;

    final repo = ref.read(groupRepositoryProvider);

    // 1. Подписываемся на Drift-стрим (SSoT)
    _groupSub = repo.watchForInstitution(teacher.institutionId).listen(
      (groups) {
        if (mounted) {
          setState(() {
            _groups = groups;
            if (_selectedGroupId == null && groups.isNotEmpty) {
              _selectedGroupId = groups.first.id;
            }
          });
        }
      },
    );

    // 2. Фоновая синхронизация с Supabase
    repo.syncForInstitution(teacher.institutionId).catchError((_) {});
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
      EduSnackBar.showInfo(context, ref, 'Выберите группу');
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
      final allStudents = await StudentServices.getStudentsByGroupId(
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
        EduSnackBar.showError(context, ref, 'Ошибка генерации отчета: $e');
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
