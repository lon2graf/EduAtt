import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Оборачивает дочерний виджет в синхронную shimmer-анимацию.
/// Все потомки должны использовать белый цвет — шиммер рисует поверх него.
class EduSkeleton extends StatelessWidget {
  final Widget child;

  const EduSkeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
      highlightColor: isDark ? const Color(0xFF404040) : const Color(0xFFF5F5F5),
      child: child,
    );
  }
}

/// Прямоугольный плейсхолдер со скруглёнными углами.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Круглый плейсхолдер.
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}
