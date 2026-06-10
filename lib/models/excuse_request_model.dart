import 'package:flutter/material.dart';

enum ExcuseReasonType {
  illness,
  family,
  transport,
  event,
  other;

  String get label {
    switch (this) {
      case ExcuseReasonType.illness:   return 'Болезнь';
      case ExcuseReasonType.family:    return 'Семья';
      case ExcuseReasonType.transport: return 'Транспорт';
      case ExcuseReasonType.event:     return 'Мероприятие';
      case ExcuseReasonType.other:     return 'Другое';
    }
  }

  IconData get icon {
    switch (this) {
      case ExcuseReasonType.illness:   return Icons.health_and_safety_outlined;
      case ExcuseReasonType.family:    return Icons.people_outline;
      case ExcuseReasonType.transport: return Icons.directions_bus_outlined;
      case ExcuseReasonType.event:     return Icons.emoji_events_outlined;
      case ExcuseReasonType.other:     return Icons.edit_note_outlined;
    }
  }

  String get toDbValue => name;

  static ExcuseReasonType fromString(String? value) {
    switch (value) {
      case 'illness':   return ExcuseReasonType.illness;
      case 'family':    return ExcuseReasonType.family;
      case 'transport': return ExcuseReasonType.transport;
      case 'event':     return ExcuseReasonType.event;
      default:          return ExcuseReasonType.other;
    }
  }
}

enum ExcuseStatusType {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case ExcuseStatusType.pending:  return 'Ожидает проверки';
      case ExcuseStatusType.approved: return 'Уважительная';
      case ExcuseStatusType.rejected: return 'Неуважительная';
    }
  }

  Color get color {
    switch (this) {
      case ExcuseStatusType.pending:  return Colors.orange;
      case ExcuseStatusType.approved: return Colors.green;
      case ExcuseStatusType.rejected: return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case ExcuseStatusType.pending:  return Icons.hourglass_top_rounded;
      case ExcuseStatusType.approved: return Icons.check_circle_outline_rounded;
      case ExcuseStatusType.rejected: return Icons.cancel_outlined;
    }
  }

  String get toDbValue => name;

  static ExcuseStatusType fromString(String? value) {
    switch (value) {
      case 'approved': return ExcuseStatusType.approved;
      case 'rejected': return ExcuseStatusType.rejected;
      default:         return ExcuseStatusType.pending;
    }
  }
}

class ExcuseRequestModel {
  final String id;
  final String lessonId;
  final String studentId;
  final ExcuseReasonType reasonType;
  final String? description;
  final ExcuseStatusType status;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final bool isSynced;

  // Вспомогательные поля, заполняемые при загрузке
  final String? studentName;
  final String? subjectName;
  final DateTime? lessonDate;

  const ExcuseRequestModel({
    required this.id,
    required this.lessonId,
    required this.studentId,
    required this.reasonType,
    this.description,
    this.status = ExcuseStatusType.pending,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
    this.isSynced = false,
    this.studentName,
    this.subjectName,
    this.lessonDate,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'lesson_id': lessonId,
    'student_id': studentId,
    'reason_type': reasonType.toDbValue,
    'description': description,
    'status': status.toDbValue,
    'created_at': createdAt.toIso8601String(),
    if (reviewedBy != null) 'reviewed_by': reviewedBy,
    if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
  };

  static ExcuseRequestModel fromJson(Map<String, dynamic> json) =>
      ExcuseRequestModel(
        id: json['id'] as String,
        lessonId: json['lesson_id'] as String,
        studentId: json['student_id'] as String,
        reasonType: ExcuseReasonType.fromString(json['reason_type'] as String?),
        description: json['description'] as String?,
        status: ExcuseStatusType.fromString(json['status'] as String?),
        createdAt: DateTime.parse(json['created_at'] as String),
        reviewedBy: json['reviewed_by'] as String?,
        reviewedAt: json['reviewed_at'] != null
            ? DateTime.tryParse(json['reviewed_at'] as String)
            : null,
        isSynced: true,
      );

  ExcuseRequestModel copyWith({ExcuseStatusType? status, String? reviewedBy, DateTime? reviewedAt}) =>
      ExcuseRequestModel(
        id: id,
        lessonId: lessonId,
        studentId: studentId,
        reasonType: reasonType,
        description: description,
        status: status ?? this.status,
        createdAt: createdAt,
        reviewedBy: reviewedBy ?? this.reviewedBy,
        reviewedAt: reviewedAt ?? this.reviewedAt,
        isSynced: isSynced,
        studentName: studentName,
        subjectName: subjectName,
        lessonDate: lessonDate,
      );
}
