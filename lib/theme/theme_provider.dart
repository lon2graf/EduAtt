import 'package:edu_att/theme/app_theme_type.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:edu_att/services/shared_preferences_service.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeType>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeType> {
  ThemeNotifier() : super(AppThemeType.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    // Используем сервис для получения строки
    final savedValue = await SharedPreferencesService.getTheme();
    // Конвертируем строку в Enum (наша логика в AppThemeType это умеет)
    state = AppThemeType.fromString(savedValue);
  }

  Future<void> setTheme(AppThemeType type) async {
    state = type;
    // Используем сервис для сохранения
    await SharedPreferencesService.saveTheme(type.toStorageValue);
  }

  void toggleTheme() {
    if (state == AppThemeType.light) {
      setTheme(AppThemeType.dark);
    } else {
      setTheme(AppThemeType.light);
    }
  }
}
