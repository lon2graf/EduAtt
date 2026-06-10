import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Определяет офлайн-статус с дебаунсом 2 сек и корректным начальным состоянием.
/// connectivity_plus на Android может кратко эмитить [none] при старте/переключении —
/// дебаунс исключает ложные срабатывания.
final isOfflineProvider =
    StateNotifierProvider<_ConnectivityNotifier, bool>(_ConnectivityNotifier.new);

class _ConnectivityNotifier extends StateNotifier<bool> {
  StreamSubscription? _sub;
  Timer? _debounce;

  _ConnectivityNotifier(Ref ref) : super(false) {
    // Начальное состояние — без ожидания первого события стрима
    Connectivity().checkConnectivity().then(_apply);
    _sub = Connectivity().onConnectivityChanged.listen(_onChanged);
  }

  void _onChanged(List<ConnectivityResult> results) {
    // Дебаунс 2 сек: игнорируем кратковременные [none] при переключении сетей
    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), () => _apply(results));
  }

  void _apply(List<ConnectivityResult> results) {
    if (!mounted) return;
    state = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}

/// Флаг офлайн-входа: true если последний auth-check не прошёл.
/// Устанавливается только после реальной неудачи, не до попытки.
final offlineModeProvider = StateProvider<bool>((ref) => false);
