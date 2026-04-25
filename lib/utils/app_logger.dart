import 'package:flutter/foundation.dart';

/// Уровни логирования
enum LogLevel {
  debug, // Детальная отладочная информация
  info, // Общая информация о работе приложения
  warning, // Потенциальные проблемы
  error, // Критические ошибки
}

/// Система логирования для приложения
/// Автоматически отключается в production (release mode)
class AppLogger {
  /// Логи включены только в debug режиме
  static const bool _enableLogs = kDebugMode;

  /// Детальная отладочная информация
  /// Используется для вывода значений переменных, состояний
  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }

  /// Общая информация о работе приложения
  /// Используется для важных событий (авторизация, загрузка данных)
  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  /// Предупреждения о нештатных ситуациях
  /// Не являются ошибками, но требуют внимания
  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  /// Критические ошибки с полным контекстом
  /// Включает сообщение, объект ошибки и stack trace
  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    String? tag,
  ]) {
    if (!_enableLogs) return;

    final tagStr = tag != null ? '[$tag] ' : '';
    debugPrint('❌ ERROR $tagStr$message');

    if (error != null) {
      debugPrint('   ↳ Error: $error');
    }

    if (stackTrace != null) {
      debugPrint('   ↳ StackTrace:\n$stackTrace');
    }
  }

  /// Внутренний метод для форматированного вывода логов
  static void _log(LogLevel level, String message, String? tag) {
    if (!_enableLogs) return;

    final emoji = _getEmoji(level);
    final levelName = level.name.toUpperCase();
    final tagStr = tag != null ? '[$tag] ' : '';

    debugPrint('$emoji $levelName $tagStr$message');
  }

  /// Получение эмодзи для уровня логирования
  static String _getEmoji(LogLevel level) {
    return switch (level) {
      LogLevel.debug => '🔍',
      LogLevel.info => '📘',
      LogLevel.warning => '⚠️',
      LogLevel.error => '❌',
    };
  }
}
