import 'package:supabase_flutter/supabase_flutter.dart';

/// Базовый класс для всех сервисов, работающих с Supabase
/// Предоставляет общий доступ к клиенту и вспомогательные методы
abstract class BaseService {
  /// Общий клиент Supabase для всех сервисов
  static SupabaseClient get client => Supabase.instance.client;

  /// Вспомогательный метод для безопасного выполнения запросов
  /// Возвращает null в случае ошибки и выводит лог
  static Future<T?> executeSafely<T>({
    required Future<T> Function() operation,
    required String errorContext,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      print('❌ Ошибка в $errorContext: $e');
      print('StackTrace: $stackTrace');
      return null;
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
    } catch (e) {
      print('❌ Ошибка в $errorContext: $e');
      rethrow;
    }
  }
}
