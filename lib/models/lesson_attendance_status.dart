import 'package:flutter/material.dart';

enum LessonAttendanceStatus {
  free,
  onHeadmanEditing,
  waitConfirmation,
  onTeacherEditing,
  confirmed;

  /// Получение статуса из строки, пришедшей из Базы Данных (английской)
  static LessonAttendanceStatus fromString(String? value) {
    if (value == null) return LessonAttendanceStatus.free;

    switch (value.trim()) {
      case 'free':
        return LessonAttendanceStatus.free;
      case 'headman_editing':
        return LessonAttendanceStatus.onHeadmanEditing;
      case 'wait_confirmation':
        return LessonAttendanceStatus.waitConfirmation;
      case 'teacher_editing':
        return LessonAttendanceStatus.onTeacherEditing;
      case 'confirmed':
        return LessonAttendanceStatus.confirmed;
      default:
        // Если в базе записано что-то странное, считаем урок свободным
        return LessonAttendanceStatus.free;
    }
  }

  /// Преобразование в строку для сохранения в БД (на английском)
  String get toDbValue {
    switch (this) {
      case LessonAttendanceStatus.free:
        return 'free';
      case LessonAttendanceStatus.onHeadmanEditing:
        return 'headman_editing';
      case LessonAttendanceStatus.waitConfirmation:
        return 'wait_confirmation';
      case LessonAttendanceStatus.onTeacherEditing:
        return 'teacher_editing';
      case LessonAttendanceStatus.confirmed:
        return 'confirmed';
    }
  }

  /// Текст для отображения в Интерфейсе (на русском)
  String get label {
    switch (this) {
      case LessonAttendanceStatus.free:
        return 'Ждет заполнения';
      case LessonAttendanceStatus.onHeadmanEditing:
        return 'На редактировании старостой';
      case LessonAttendanceStatus.waitConfirmation:
        return 'Ждет подтверждения';
      case LessonAttendanceStatus.onTeacherEditing:
        return 'Редактирует преподаватель';
      case LessonAttendanceStatus.confirmed:
        return 'Подтвержден';
    }
  }

  /// Цвет для отображения статуса в UI (Бонус)
  Color get color {
    switch (this) {
      case LessonAttendanceStatus.free:
        return Colors.green; // Свободно
      case LessonAttendanceStatus.onHeadmanEditing:
        return Colors.orange; // В работе
      case LessonAttendanceStatus.waitConfirmation:
        return Colors.blue; // Внимание
      case LessonAttendanceStatus.onTeacherEditing:
        return Colors.redAccent; // Блокировка
      case LessonAttendanceStatus.confirmed:
        return Colors.grey; // Архив
    }
  }
}
