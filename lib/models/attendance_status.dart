import 'package:flutter/material.dart';

enum AttendanceStatus {
  present,
  absent,
  late;

  static AttendanceStatus? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase().trim()) {
      case 'присутствует':
      case 'present':
      case '+':
        return AttendanceStatus.present;
      case 'отсутствует':
      case 'absent':
      case '–': // тире
      case '-': // дефис
        return AttendanceStatus.absent;
      case 'опоздал':
      case 'late':
      case 'оп':
        return AttendanceStatus.late;
      default:
        return null;
    }
  }

  String toDbValue() {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.absent:
        return 'absent';
      case AttendanceStatus.late:
        return 'late';
    }
  }

  /// Текст для отображения в UI
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
