import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/providers/frosya_provider.dart';

class EduMascot extends ConsumerWidget {
  final MascotState state; // Какое состояние показать
  final double? height; // Настраиваемая высота
  final double? width; // Настраиваемая ширина

  const EduMascot({
    super.key,
    required this.state,
    this.height = 150, // Значение по умолчанию
    this.width,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Смотрим в глобальные настройки
    final isEnabled = ref.watch(mascotProvider);

    // 2. Если маскот выключен — исчезает
    if (!isEnabled) {
      return const SizedBox.shrink();
    }

    // 3. Если включен — центрируем и рисуем
    return SvgPicture.asset(
      MascotManager.getSvgPath(state),
      height: height,
      width: width,
      fit: BoxFit.contain,
      placeholderBuilder: (context) => const SizedBox.shrink(),
    );
  }
}
