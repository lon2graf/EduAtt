import 'package:edu_att/widgets/skeletons/skeleton_base.dart';
import 'package:flutter/material.dart';

/// Форма-заглушка для карточки посещаемости в MissesContentScreen.
/// Повторяет структуру _buildAttendanceCard, shimmer применяется снаружи.
class AttendanceCardSkeleton extends StatelessWidget {
  const AttendanceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Верхняя строка: иконка + дата ──
          Row(
            children: [
              const SkeletonCircle(size: 40),
              const SizedBox(width: 12),
              const Expanded(child: SkeletonBox(height: 18)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white),
          const SizedBox(height: 12),
          // ── Нижние строки: время + преподаватель ──
          const SkeletonBox(width: 130, height: 13),
          const SizedBox(height: 8),
          const SkeletonBox(width: 170, height: 13),
        ],
      ),
    );
  }
}
