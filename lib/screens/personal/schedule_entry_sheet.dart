import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/services/personal_mode_service.dart';
import 'package:edu_att/providers/personal_mode_provider.dart';
import 'package:edu_att/providers/schedule_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Нижний лист для создания занятия в личном режиме.
Future<void> showScheduleEntrySheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _ScheduleEntrySheet(),
  );
}

class _ScheduleEntrySheet extends ConsumerStatefulWidget {
  const _ScheduleEntrySheet();

  @override
  ConsumerState<_ScheduleEntrySheet> createState() =>
      _ScheduleEntrySheetState();
}

class _ScheduleEntrySheetState extends ConsumerState<_ScheduleEntrySheet> {
  static const _uuid = Uuid();

  DateTime _date = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 30);
  Subject? _selectedSubject;
  Group? _selectedGroup;

  bool _repeat = false;
  int _repeatWeeks = 4;

  List<Subject> _subjects = [];
  List<Group> _groups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = ref.read(personalModeServiceProvider);
    final subjects = await service.getSubjects();
    final groups = await service.getGroups();
    if (mounted) {
      setState(() {
        _subjects = subjects;
        _groups = groups;
        if (subjects.isNotEmpty) _selectedSubject = subjects.first;
        if (groups.isNotEmpty) _selectedGroup = groups.first;
      });
    }
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
          // Сдвигаем конец, если он стал раньше начала
          if (_toMinutes(picked) >= _toMinutes(_endTime)) {
            _endTime = TimeOfDay(
              hour: (picked.hour + 1) % 24,
              minute: picked.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _save() async {
    final personalState = ref.read(personalModeProvider);
    final subject = _selectedSubject;
    final group = _selectedGroup ??
        (personalState.isStudentOrHeadman
            ? Group(
                id: PersonalModeService.kDefaultGroupId,
                institutionId: PersonalModeService.kInstitutionId,
                name: 'Моя группа',
                curatorId: null,
              )
            : null);

    if (subject == null || group == null) return;
    if (_toMinutes(_startTime) >= _toMinutes(_endTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Время окончания должно быть позже начала')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = ref.read(personalModeServiceProvider);
      final baseDate = DateTime(_date.year, _date.month, _date.day);
      final count = _repeat ? _repeatWeeks : 1;
      for (int i = 0; i < count; i++) {
        await service.insertScheduleWithLesson(
          scheduleId: _uuid.v4(),
          lessonId: _uuid.v4(),
          subjectId: subject.id,
          groupId: group.id,
          date: baseDate.add(Duration(days: 7 * i)),
          startTime: _fmt(_startTime),
          endTime: _fmt(_endTime),
        );
      }
      final scheduleNotifier = ref.read(scheduleProvider.notifier);
      await scheduleNotifier.syncSchedule();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final personalState = ref.watch(personalModeProvider);
    final isTeacher = personalState.isTeacher;

    if (_subjects.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Сначала добавь хотя бы один предмет',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const Text(
                'Новое занятие',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Дата
          _FieldRow(
            icon: Icons.calendar_today_outlined,
            label: 'Дата',
            value:
                '${_date.day.toString().padLeft(2, '0')}.${_date.month.toString().padLeft(2, '0')}.${_date.year}',
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),

          // Время начала / конца
          Row(
            children: [
              Expanded(
                child: _FieldRow(
                  icon: Icons.play_arrow_outlined,
                  label: 'Начало',
                  value: _startTime.format(context),
                  onTap: () => _pickTime(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FieldRow(
                  icon: Icons.stop_outlined,
                  label: 'Конец',
                  value: _endTime.format(context),
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const SizedBox(height: 12),

          // Повторение
          _RepeatRow(
            repeat: _repeat,
            weeks: _repeatWeeks,
            colorScheme: colorScheme,
            onToggle: (v) => setState(() => _repeat = v),
            onWeeksChanged: (v) => setState(() => _repeatWeeks = v),
          ),
          const SizedBox(height: 12),

          // Предмет
          _DropdownRow<Subject>(
            icon: Icons.menu_book_outlined,
            label: 'Предмет',
            value: _selectedSubject,
            items: _subjects,
            itemLabel: (s) => s.name,
            onChanged: (s) => setState(() => _selectedSubject = s),
            colorScheme: colorScheme,
          ),

          // Группа (только для преподавателя)
          if (isTeacher && _groups.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DropdownRow<Group>(
              icon: Icons.group_outlined,
              label: 'Группа',
              value: _selectedGroup,
              items: _groups,
              itemLabel: (g) => g.name,
              onChanged: (g) => setState(() => _selectedGroup = g),
              colorScheme: colorScheme,
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Добавить занятие',
                      style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _FieldRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10, color: colorScheme.onSurfaceVariant)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  final IconData icon;
  final String label;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final ColorScheme colorScheme;

  const _DropdownRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                hint: Text(label),
                isExpanded: true,
                items: items
                    .map((i) => DropdownMenuItem<T>(
                          value: i,
                          child: Text(itemLabel(i)),
                        ))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepeatRow extends StatelessWidget {
  final bool repeat;
  final int weeks;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onWeeksChanged;
  final ColorScheme colorScheme;

  const _RepeatRow({
    required this.repeat,
    required this.weeks,
    required this.onToggle,
    required this.onWeeksChanged,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Повторять еженедельно',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          if (repeat) ...[
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: weeks > 2 ? () => onWeeksChanged(weeks - 1) : null,
            ),
            SizedBox(
              width: 36,
              child: Text(
                '$weeks нед.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              onPressed: weeks < 52 ? () => onWeeksChanged(weeks + 1) : null,
            ),
          ],
          Switch(
            value: repeat,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
