enum MascotState {
  greeting, // приветствие
  idle, // обычный
  empty, // пусто
  waiting, // ожидание
  searching, // поиск
  updating, // обновление
  success, // успех
  error, // ошибка
  forbidden, // запрет
}

class MascotManager {
  // Статический метод для получения пути к SVG
  static String getSvgPath(MascotState state) {
    const String base = 'assets/frosya_mascot';

    switch (state) {
      case MascotState.greeting:
        return '$base/greeting/greeting.svg';
      case MascotState.idle:
        return '$base/idle/idle.svg';
      case MascotState.empty:
        return '$base/empty/empty.svg';
      case MascotState.waiting:
        return '$base/waiting/waiting.svg';
      case MascotState.searching:
        return '$base/searching/searching.svg';
      case MascotState.updating:
        return '$base/updating/updating.svg';
      case MascotState.success:
        return '$base/success/success.svg';
      case MascotState.error:
        return '$base/error/error.svg';
      case MascotState.forbidden:
        return '$base/forbidden/forbidden.svg';
    }
  }
}
