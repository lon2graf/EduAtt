import 'package:edu_att/data/remote/shared_preferences_service.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Провайдер видимости маскота
final mascotProvider = StateNotifierProvider<MascotNotifier, bool>((ref) {
  return MascotNotifier();
});

class MascotNotifier extends StateNotifier<bool> {
  MascotNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    state = await SharedPreferencesService.getMascotEnabled();
  }

  Future<void> toggleMascot() async {
    state = !state;
    await SharedPreferencesService.setMascotEnabled(state);
  }

  Future<void> setMascotVisibility(bool isVisible) async {
    state = isVisible;
    await SharedPreferencesService.setMascotEnabled(isVisible);
  }
}

/// Провайдер анимации маскота
final mascotAnimationProvider =
    StateNotifierProvider<MascotAnimationNotifier, bool>((ref) {
  return MascotAnimationNotifier();
});

class MascotAnimationNotifier extends StateNotifier<bool> {
  MascotAnimationNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    state = await SharedPreferencesService.getMascotAnimation();
  }

  Future<void> toggle() async {
    state = !state;
    await SharedPreferencesService.setMascotAnimation(state);
  }
}
