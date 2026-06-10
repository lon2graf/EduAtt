import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/models/excuse_request_model.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/data/repositories/excuse_repository.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';

/// Боттом-шит для подачи объяснительной студентом.
/// Вызывается из MissesContentScreen по тапу на карточку пропуска/опоздания.
class ExcuseRequestSheet extends ConsumerStatefulWidget {
  final LessonAttendanceModel attendance;
  final VoidCallback? onSubmitted;

  const ExcuseRequestSheet({
    required this.attendance,
    this.onSubmitted,
    super.key,
  });

  @override
  ConsumerState<ExcuseRequestSheet> createState() => _ExcuseRequestSheetState();
}

class _ExcuseRequestSheetState extends ConsumerState<ExcuseRequestSheet> {
  ExcuseReasonType? _selectedReason;
  final _descController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    final student = ref.read(currentStudentProvider);
    if (student?.id == null) return;

    setState(() => _submitting = true);
    try {
      await ref.read(excuseRepositoryProvider).submitExcuse(
        lessonId: widget.attendance.lessonId,
        studentId: student!.id!,
        reasonType: _selectedReason!,
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSubmitted?.call();
        EduSnackBar.showSuccess(
          context,
          ref,
          'Объяснительная отправлена',
        );
      }
    } catch (e) {
      if (mounted) {
        EduSnackBar.showError(context, ref, 'Не удалось отправить');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final attendance = widget.attendance;

    final statusLabel = attendance.status?.label ?? '';
    final dateStr = attendance.lessonDate != null
        ? _formatDate(attendance.lessonDate!)
        : '';

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ручка
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Заголовок
          Text(
            'Объяснительная',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${attendance.subjectName ?? 'Предмет'} · $statusLabel · $dateStr',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Причина
          Text(
            'Причина',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ExcuseReasonType.values.map((r) {
              final selected = _selectedReason == r;
              return GestureDetector(
                onTap: () => setState(() => _selectedReason = r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        r.icon,
                        size: 16,
                        color: selected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        r.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Дополнительно
          Text(
            'Дополнительно (необязательно)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 3,
            maxLength: 300,
            decoration: InputDecoration(
              hintText: 'Опишите подробнее...',
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 8),

          // Кнопка
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_selectedReason == null || _submitting) ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Отправить объяснительную',
                      style: TextStyle(fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
    ];
    return '${dt.day} ${months[dt.month]}';
  }
}
