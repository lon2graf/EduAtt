import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/mascot/mascot_widget.dart';
import 'package:edu_att/mascot/mascot_manager.dart';
import 'package:edu_att/providers/frosya_provider.dart';

class EduSnackBar {
  /// Главный приватный метод для сборки SnackBar
  static void _show({
    required BuildContext context,
    required WidgetRef ref,
    required MascotState state,
    required String mascotMessage,
    required String neutralMessage,
    Color? accentColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMascotEnabled = ref.read(mascotProvider);

    // Убираем активный SnackBar перед показом нового
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colorScheme.surface,
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            // Фрося (виджет сам скроется, если !isMascotEnabled)
            EduMascot(state: state, height: 45),

            // Динамический отступ: если маскота нет, текст не будет "дырявым"
            if (isMascotEnabled) const SizedBox(width: 12),

            Expanded(
              child: Text(
                isMascotEnabled ? mascotMessage : neutralMessage,
                style: TextStyle(
                  color: accentColor ?? colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Приветствие (greeting)
  static void showGreeting(BuildContext context, WidgetRef ref, String name) {
    _show(
      context: context,
      ref: ref,
      state: MascotState.greeting,
      mascotMessage: 'Мяу! С возвращением, $name! Фрося готова к работе 🐾',
      neutralMessage: 'Добро пожаловать, $name. Вы успешно авторизованы.',
    );
  }

  // 2. Успех (success)
  static void showSuccess(BuildContext context, WidgetRef ref, String message) {
    _show(
      context: context,
      ref: ref,
      state: MascotState.success,
      mascotMessage: 'Мур-р! $message ✨',
      neutralMessage: 'Действие выполнено: $message',
    );
  }

  // 3. Ошибка (error)
  static void showError(BuildContext context, WidgetRef ref, String error) {
    _show(
      context: context,
      ref: ref,
      state: MascotState.error,
      mascotMessage: 'Фрося расстроена: $error 😿',
      neutralMessage: 'Произошла ошибка: $error',
    );
  }

  // 4. Ожидание/Загрузка (waiting)
  static void showWaiting(BuildContext context, WidgetRef ref, String message) {
    _show(
      context: context,
      ref: ref,
      state: MascotState.waiting,
      mascotMessage: 'Секундочку... Фрося наводит порядок ⏳',
      neutralMessage: 'Пожалуйста, подождите: $message',
    );
  }

  // 5. Поиск (searching)
  static void showSearching(BuildContext context, WidgetRef ref, String query) {
    _show(
      context: context,
      ref: ref,
      state: MascotState.searching,
      mascotMessage: 'Фрося пошла искать: $query 🔍',
      neutralMessage: 'Выполняется поиск: $query',
    );
  }

  // 6. Обновление (updating)
  static void showUpdating(BuildContext context, WidgetRef ref) {
    _show(
      context: context,
      ref: ref,
      state: MascotState.updating,
      mascotMessage: 'Фрося обновляет списки. Ждём свежих данных! 📡',
      neutralMessage: 'Обновление данных...',
    );
  }

  // 7. Пусто (empty)
  static void showEmpty(BuildContext context, WidgetRef ref, String entity) {
    _show(
      context: context,
      ref: ref,
      state: MascotState.empty,
      mascotMessage: 'Тут ничего нет! Фрося предлагает отдохнуть 💤',
      neutralMessage: 'Список ($entity) пуст.',
    );
  }

  // 8. Запрет (forbidden)
  static void showForbidden(BuildContext context, WidgetRef ref) {
    _show(
      context: context,
      ref: ref,
      state: MascotState.forbidden,
      mascotMessage: 'Ш-ш-ш! У Фроси нет ключей от этого экрана 🛑',
      neutralMessage: 'Доступ запрещен. Обратитесь к администратору.',
    );
  }

  // 9. Обычный/Инфо (idle)
  static void showInfo(BuildContext context, WidgetRef ref, String info) {
    _show(
      context: context,
      ref: ref,
      state: MascotState.idle,
      mascotMessage: 'Фрося сообщает: $info',
      neutralMessage: 'Информация: $info',
    );
  }
}
