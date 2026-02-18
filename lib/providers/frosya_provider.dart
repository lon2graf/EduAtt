import 'package:edu_att/services/shared_preferences_service.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Провайдер, который следит за тем, нужно ли показывать маскота
final mascotProvider = StateNotifierProvider<MascotNotifier, bool>((ref) {
  return MascotNotifier();
});

class MascotNotifier extends StateNotifier<bool> {
  // При создании сразу ставим true, но тут же запускаем загрузку из памяти
  MascotNotifier() : super(true) {
    _loadMascotSettings();
  }

  /// Загружаем настройки из локального хранилища
  Future<void> _loadMascotSettings() async {
    final isEnabled = await SharedPreferencesService.getMascotEnabled();
    state = isEnabled;
  }

  /// Метод для включения/выключения маскота
  Future<void> toggleMascot() async {
    // Инвертируем текущее состояние
    state = !state;
    // Сохраняем новое значение в память телефона
    await SharedPreferencesService.setMascotEnabled(state);
  }

  /// Метод для явной установки состояния (если понадобится)
  Future<void> setMascotVisibility(bool isVisible) async {
    state = isVisible;
    await SharedPreferencesService.setMascotEnabled(isVisible);
  }
}
