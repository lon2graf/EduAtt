import 'dart:math' as math;
import 'dart:typed_data';

import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class AttendancePdfGenerator {
  AttendancePdfGenerator._();

  static Future<Uint8List> generate({
    required String groupName,
    required String teacherFullName,
    required String periodLabel,
    String? selectedSubject,
    required List<LessonAttendanceModel> records,
  }) async {
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final fontBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

    final lessons = _buildLessons(records);
    final students = _buildStudents(records);
    final matrix = _buildMatrix(records);

    // ── Ширины столбцов ──────────────────────────────────────────────────
    // A4 landscape: 841.89pt, поля 12pt × 2 = 24pt → доступно ~817pt
    const availW = 841.89 - 24.0;
    const numW = 18.0;
    const nameW = 120.0;
    const totalW = 22.0;
    const totalsCount = 3;
    final lessonW =
        ((availW - numW - nameW - totalW * totalsCount) / math.max(lessons.length, 1))
            .clamp(12.0, 35.0);

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        orientation: pw.PageOrientation.landscape,
        margin: const pw.EdgeInsets.all(12),
        build: (ctx) => [
          _header(font, fontBold, groupName, periodLabel, selectedSubject),
          pw.SizedBox(height: 8),
          _table(
            font: font,
            fontBold: fontBold,
            lessons: lessons,
            students: students,
            matrix: matrix,
            numW: numW,
            nameW: nameW,
            lessonW: lessonW,
            totalW: totalW,
          ),
          pw.SizedBox(height: 14),
          _footer(font, fontBold, teacherFullName),
        ],
      ),
    );

    return doc.save();
  }

  // ── Шапка страницы ──────────────────────────────────────────────────────────

  static pw.Widget _header(
    pw.Font font,
    pw.Font fontBold,
    String groupName,
    String periodLabel,
    String? selectedSubject,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'РАПОРТИЧКА группы $groupName',
              style: pw.TextStyle(font: fontBold, fontSize: 13),
            ),
            if (selectedSubject != null)
              pw.Text(
                'Предмет: $selectedSubject',
                style: pw.TextStyle(font: font, fontSize: 9),
              ),
            pw.Text(
              periodLabel,
              style: pw.TextStyle(font: font, fontSize: 9),
            ),
          ],
        ),
        pw.Text(
          'Число: __________',
          style: pw.TextStyle(font: font, fontSize: 8),
        ),
      ],
    );
  }

  // ── Таблица ─────────────────────────────────────────────────────────────────

  static pw.Widget _table({
    required pw.Font font,
    required pw.Font fontBold,
    required List<_Lesson> lessons,
    required List<_Student> students,
    required Map<String, Map<String, AttendanceStatus?>> matrix,
    required double numW,
    required double nameW,
    required double lessonW,
    required double totalW,
  }) {
    final ts = pw.TextStyle(font: font, fontSize: 7);
    final tsb = pw.TextStyle(font: fontBold, fontSize: 7);
    final tsRotated = pw.TextStyle(font: font, fontSize: 5.5);

    final colWidths = <int, pw.TableColumnWidth>{
      0: pw.FixedColumnWidth(numW),
      1: pw.FixedColumnWidth(nameW),
      for (int i = 0; i < lessons.length; i++)
        i + 2: pw.FixedColumnWidth(lessonW),
      lessons.length + 2: pw.FixedColumnWidth(totalW),
      lessons.length + 3: pw.FixedColumnWidth(totalW),
      lessons.length + 4: pw.FixedColumnWidth(totalW),
    };

    final headerRow = pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      children: [
        _hCell(pw.Text('№\nп/п', style: tsb, textAlign: pw.TextAlign.center)),
        _hCell(
          pw.Text('Ф.И.О. студента', style: tsb),
          leftPad: 4,
        ),
        ...lessons.map((l) => _rotatedCell(l, tsRotated)),
        _hCell(pw.Text('Пропустил\nвсего', style: tsb, textAlign: pw.TextAlign.center)),
        _hCell(pw.Text('По\nуважит.', style: tsb, textAlign: pw.TextAlign.center)),
        _hCell(pw.Text('По\nнеуваж.', style: tsb, textAlign: pw.TextAlign.center)),
      ],
    );

    final dataRows = students.asMap().entries.map((entry) {
      final idx = entry.key;
      final student = entry.value;
      final statusMap = matrix[student.id] ?? {};

      int totalAbsent = 0;
      for (final lesson in lessons) {
        if (statusMap[lesson.id] == AttendanceStatus.absent) totalAbsent++;
      }

      return pw.TableRow(
        children: [
          _dCell(pw.Text('${idx + 1}', style: ts, textAlign: pw.TextAlign.center)),
          _dCell(pw.Text(student.name, style: ts), leftPad: 4),
          ...lessons.map((lesson) => _dCell(
                pw.Text(
                  _statusLabel(statusMap[lesson.id]),
                  style: ts,
                  textAlign: pw.TextAlign.center,
                ),
              )),
          _dCell(pw.Text(
            totalAbsent > 0 ? '$totalAbsent' : '',
            style: ts,
            textAlign: pw.TextAlign.center,
          )),
          _dCell(pw.Text('', style: ts)),
          _dCell(pw.Text('', style: ts)),
        ],
      );
    }).toList();

    return pw.Table(
      border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey600),
      columnWidths: colWidths,
      children: [headerRow, ...dataRows],
    );
  }

  static pw.Widget _rotatedCell(_Lesson lesson, pw.TextStyle style) {
    final d = lesson.date;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final time = lesson.startTime.length >= 5
        ? lesson.startTime.substring(0, 5)
        : lesson.startTime;
    final label = '$day.$month\n$time';

    return pw.Container(
      height: 50,
      alignment: pw.Alignment.center,
      child: pw.Transform.rotate(
        angle: -math.pi / 2,
        child: pw.Text(label, style: style, textAlign: pw.TextAlign.center),
      ),
    );
  }

  static pw.Widget _hCell(pw.Widget child, {double leftPad = 2}) =>
      pw.Container(
        alignment: pw.Alignment.center,
        padding: pw.EdgeInsets.fromLTRB(leftPad, 3, 2, 3),
        child: child,
      );

  static pw.Widget _dCell(pw.Widget child, {double leftPad = 2}) =>
      pw.Padding(
        padding: pw.EdgeInsets.fromLTRB(leftPad, 2, 2, 2),
        child: child,
      );

  // ── Подвал ──────────────────────────────────────────────────────────────────

  static pw.Widget _footer(pw.Font font, pw.Font fontBold, String teacherFullName) {
    final ts = pw.TextStyle(font: font, fontSize: 8);
    final tsb = pw.TextStyle(font: fontBold, fontSize: 8);
    final blank = pw.TextStyle(font: font, fontSize: 8);

    pw.Widget signRow(String label, String prefilled) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Row(
            children: [
              pw.Text(label, style: tsb),
              pw.SizedBox(width: 4),
              pw.Text('__________________', style: blank),
              pw.SizedBox(width: 16),
              pw.Text('Ф.И.О.: ', style: tsb),
              pw.Text(
                prefilled.isNotEmpty ? prefilled : '__________________',
                style: ts,
              ),
            ],
          ),
        );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        signRow('Подпись преподавателя:', teacherFullName),
        signRow('Классный руководитель:', ''),
        signRow('Староста:', ''),
      ],
    );
  }

  // ── Вспомогательные методы ──────────────────────────────────────────────────

  static List<_Lesson> _buildLessons(List<LessonAttendanceModel> records) {
    final seen = <String>{};
    final list = <_Lesson>[];
    for (final r in records) {
      if (seen.add(r.lessonId) && r.lessonDate != null) {
        list.add(_Lesson(
          id: r.lessonId,
          date: r.lessonDate!,
          startTime: r.lessonStart ?? '',
        ));
      }
    }
    return list
      ..sort((a, b) {
        final dc = a.date.compareTo(b.date);
        return dc != 0 ? dc : a.startTime.compareTo(b.startTime);
      });
  }

  static List<_Student> _buildStudents(List<LessonAttendanceModel> records) {
    final seen = <String>{};
    final list = <_Student>[];
    for (final r in records) {
      if (seen.add(r.studentId)) {
        list.add(_Student(id: r.studentId, name: r.studentName ?? r.studentId));
      }
    }
    return list..sort((a, b) => a.name.compareTo(b.name));
  }

  static Map<String, Map<String, AttendanceStatus?>> _buildMatrix(
    List<LessonAttendanceModel> records,
  ) {
    final matrix = <String, Map<String, AttendanceStatus?>>{};
    for (final r in records) {
      (matrix[r.studentId] ??= {})[r.lessonId] = r.status;
    }
    return matrix;
  }

  static String _statusLabel(AttendanceStatus? status) => switch (status) {
        AttendanceStatus.present => '•',
        AttendanceStatus.absent => 'Н',
        AttendanceStatus.late => 'О',
        _ => '',
      };
}

class _Lesson {
  final String id;
  final DateTime date;
  final String startTime;
  _Lesson({required this.id, required this.date, required this.startTime});
}

class _Student {
  final String id;
  final String name;
  _Student({required this.id, required this.name});
}
