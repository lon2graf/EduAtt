import 'package:flutter/material.dart';

enum AttendanceStatus {
  present,
  absent,
  late;

  /// Парсинг из строки (из БД или UI)
  static AttendanceStatus? fromString(String? value) {
    if (value == null) return null;

    // Приводим к нижнему регистру и убираем пробелы
    switch (value.toLowerCase().trim()) {
      // Английские ключи (как мы хотим хранить в БД)
      case 'present':
      // Русские варианты и символы (для совместимости)
      case 'присутствует':
      case '+':
      case 'attendanceStatus.present': // На случай если в БД уже записалось неправильно
        return AttendanceStatus.present;

      case 'absent':
      case 'отсутствует':
      case '-':
      case '–':
      case 'attendanceStatus.absent':
        return AttendanceStatus.absent;

      case 'late':
      case 'опоздал':
      case 'оп':
      case 'attendanceStatus.late':
        return AttendanceStatus.late;

      default:
        return null;
    }
  }

  /// То, что записываем в БД (Геттер)
  String get toDbValue {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
    }
  }

  /// Текст для UI
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Присутствует';
      case AttendanceStatus.absent:
        return 'Отсутствует';
      case AttendanceStatus.late:
        return 'Опоздал';
    }
  }

  /// Цвет для UI
  Color get color {
    switch (this) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.late:
        return Colors.orange;
    }
  }
}
