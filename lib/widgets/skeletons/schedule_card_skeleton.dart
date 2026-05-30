import 'package:edu_att/widgets/skeletons/skeleton_base.dart';
import 'package:flutter/material.dart';

/// Форма-заглушка для карточки занятия в расписании.
/// Повторяет структуру _ScheduleCard до пикселя, shimmer применяется снаружи.
class ScheduleCardSkeleton extends StatelessWidget {
  const ScheduleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Левый блок: время ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SkeletonBox(width: 36, height: 16),
                const SizedBox(height: 6),
                Container(
                  width: 1.5,
                  height: 20,
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                const SkeletonBox(width: 36, height: 12),
              ],
            ),
            const SizedBox(width: 14),
            // ── Правый блок: предмет / преподаватель / группа ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(height: 15),   // название предмета
                  const SizedBox(height: 10),
                  const SkeletonBox(width: 150, height: 11), // тема (факультативно)
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      SkeletonBox(width: 100, height: 10), // преподаватель
                      SizedBox(width: 16),
                      SkeletonBox(width: 60, height: 10),  // группа
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
