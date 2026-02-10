import 'package:flutter/material.dart';

enum AppThemeType {
  system, // Системная (как в настройках телефона)
  light, // Светлая
  dark; // Темная

  /// Получение типа темы из строки (используется при загрузке настроек)
  static AppThemeType fromString(String? value) {
    if (value == null) return AppThemeType.system;
    switch (value.toLowerCase()) {
      case 'light':
        return AppThemeType.light;
      case 'dark':
        return AppThemeType.dark;
      case 'system':
      default:
        return AppThemeType.system;
    }
  }

  /// Строка для сохранения в SharedPreferences
  String get toStorageValue {
    switch (this) {
      case AppThemeType.light:
        return 'light';
      case AppThemeType.dark:
        return 'dark';
      case AppThemeType.system:
        return 'system';
    }
  }

  /// Название для отображения в UI (на русском)
  String get label {
    switch (this) {
      case AppThemeType.light:
        return 'Светлая';
      case AppThemeType.dark:
        return 'Темная';
      case AppThemeType.system:
        return 'Системная';
    }
  }

  /// Иконка для меню выбора темы
  IconData get icon {
    switch (this) {
      case AppThemeType.light:
        return Icons.wb_sunny_rounded;
      case AppThemeType.dark:
        return Icons.dark_mode_rounded;
      case AppThemeType.system:
        return Icons.brightness_auto_rounded;
    }
  }

  /// Преобразование в стандартный Flutter ThemeMode
  /// Это понадобится в main.dart для MaterialApp
  ThemeMode get themeMode {
    switch (this) {
      case AppThemeType.light:
        return ThemeMode.light;
      case AppThemeType.dark:
        return ThemeMode.dark;
      case AppThemeType.system:
        return ThemeMode.system;
    }
  }
}
