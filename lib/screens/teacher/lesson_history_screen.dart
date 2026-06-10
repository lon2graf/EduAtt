import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/data/repositories/lesson_repository.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/providers/teacher_provider.dart';

final _teacherPastLessonsProvider = StreamProvider<List<LessonModel>>((ref) {
  final teacher = ref.watch(teacherProvider);
  if (teacher?.id == null) return const Stream.empty();
  return ref.watch(lessonRepositoryProvider).watchPastLessonsForTeacher(teacher!.id!);
});

class LessonHistoryScreen extends ConsumerWidget {
  const LessonHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(_teacherPastLessonsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('История занятий'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/teacher/home'),
        ),
      ),
      body: lessonsAsync.when(
        data: (lessons) {
          if (lessons.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Прошедших занятий пока нет',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: lessons.length,
            itemBuilder: (context, i) {
              final lesson = lessons[i];
              final showDateHeader = i == 0 || lessons[i - 1].date != lesson.date;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDateHeader) ...[
                    if (i > 0) const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        _formatDisplayDate(lesson.date),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                  _LessonHistoryCard(lesson: lesson),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Ошибка загрузки')),
      ),
    );
  }

  String _formatDisplayDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
        'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
      ];
      const weekdays = ['', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return '${weekdays[dt.weekday]}, ${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

class _LessonHistoryCard extends StatelessWidget {
  final LessonModel lesson;
  const _LessonHistoryCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isConfirmed = lesson.status == LessonAttendanceStatus.confirmed;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        onTap: () => context.push('/teacher/history/detail', extra: lesson),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isConfirmed
                ? Colors.green.withValues(alpha: 0.12)
                : colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isConfirmed ? Icons.check_circle_outline : Icons.pending_outlined,
            color: isConfirmed ? Colors.green : colorScheme.primary,
            size: 22,
          ),
        ),
        title: Text(
          lesson.subjectName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${lesson.groupName}  •  ${_time(lesson.startTime)}–${_time(lesson.endTime)}',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isConfirmed
                    ? Colors.green.withValues(alpha: 0.12)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isConfirmed ? 'Отмечено' : 'Не отмечено',
                style: TextStyle(
                  fontSize: 11,
                  color: isConfirmed
                      ? Colors.green.shade700
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.chevron_right, size: 18, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _time(String t) {
    final parts = t.split(':');
    return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : t;
  }
}
