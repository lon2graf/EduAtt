import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// true — нет ни одного активного подключения
final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).when(
    data: (results) =>
        results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none),
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Флаг офлайн-входа: true если пользователь вошёл без сети (из локального кэша).
/// Сбрасывается в false после успешной фоновой проверки авторизации.
final offlineModeProvider = StateProvider<bool>((ref) => false);
