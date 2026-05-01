import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:edu_att/utils/app_logger.dart';
import 'package:edu_att/utils/data_result.dart';

/// Базовый класс для всех сервисов, работающих с Supabase
/// Предоставляет общий доступ к клиенту и вспомогательные методы
abstract class BaseService {
  /// Общий клиент Supabase для всех сервисов
  static SupabaseClient get client => Supabase.instance.client;

  /// Вспомогательный метод для безопасного выполнения запросов
  /// Возвращает Success(result) при успехе или Failure(message) при ошибке
  static Future<DataResult<T>> executeSafely<T>({
    required Future<T> Function() operation,
    required String errorContext,
  }) async {
    try {
      final result = await operation();
      return Success(result);
    } catch (e, stackTrace) {
      AppLogger.error('Ошибка в $errorContext', e, stackTrace, 'BaseService');
      return Failure(e.toString(), e);
    }
  }

  /// Вспомогательный метод для запросов, которые должны выбросить ошибку
  /// В случае ошибки пробрасывает исключение выше
  static Future<T> executeOrThrow<T>({
    required Future<T> Function() operation,
    required String errorContext,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      AppLogger.error('Ошибка в $errorContext', e, stackTrace, 'BaseService');
      rethrow;
    }
  }
}
