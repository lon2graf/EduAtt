import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/providers/frosya_provider.dart';

class EduMascot extends ConsumerStatefulWidget {
  final MascotState state;
  final double? height;
  final double? width;

  const EduMascot({
    super.key,
    required this.state,
    this.height = 150,
    this.width,
  });

  @override
  ConsumerState<EduMascot> createState() => _EduMascotState();
}

class _EduMascotState extends ConsumerState<EduMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _floatAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncController(bool isAnimated) {
    if (isAnimated && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!isAnimated && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(mascotProvider);
    final isAnimated = ref.watch(mascotAnimationProvider);

    if (!isEnabled) {
      if (_controller.isAnimating) _controller.stop();
      return const SizedBox.shrink();
    }

    _syncController(isAnimated);

    final svg = SvgPicture.asset(
      MascotManager.getSvgPath(widget.state),
      height: widget.height,
      width: widget.width,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => const SizedBox.shrink(),
    );

    if (!isAnimated) return svg;

    final isShake = widget.state == MascotState.error;

    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          isShake ? _floatAnim.value * 0.7 : 0,
          isShake ? 0 : _floatAnim.value,
        ),
        child: child,
      ),
      child: svg,
    );
  }
}
