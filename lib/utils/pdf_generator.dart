// lib/utils/pdf_generator.dart
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:edu_att/models/attendance_report_data_model.dart';

pw.Font? _regularFont;
pw.Font? _boldFont;

Future<pw.Font> _getRegularFont() async {
  if (_regularFont != null) return _regularFont!;
  final data = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
  _regularFont = pw.Font.ttf(data);
  return _regularFont!;
}

Future<pw.Font> _getBoldFont() async {
  if (_boldFont != null) return _boldFont!;
  final data = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
  _boldFont = pw.Font.ttf(data);
  return _boldFont!;
}

Uint8List? _cachedLogoBytes;
Future<Uint8List> _loadLogo() async {
  if (_cachedLogoBytes != null) return _cachedLogoBytes!;
  final data = await rootBundle.load('assets/icons/applogo.png');
  _cachedLogoBytes = data.buffer.asUint8List();
  return _cachedLogoBytes!;
}

Future<List<int>> generateAttendanceReportPdf(AttendanceReportData data) async {
  final regular = await _getRegularFont();
  final bold = await _getBoldFont();
  final logoBytes = await _loadLogo();

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.DefaultTextStyle(
          style: pw.TextStyle(
            font: regular,
            fontSize: 10,
            color: PdfColors.black,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 12),
                alignment: pw.Alignment.center,
                child: pw.Column(
                  children: [
                    pw.Text(
                      'ВЕДОМОСТЬ ПОСЕЩАЕМОСТИ',
                      style: pw.TextStyle(font: bold, fontSize: 16),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Группа: ${data.groupName}'),
                    pw.Text(
                      'Период: ${data.startDateStr} – ${data.endDateStr}',
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              _buildAttendanceTable(
                data.dayHeaders,
                data.subjectHeaders,
                data.studentNames,
                data.attendance,
                bold,
                regular,
              ),
              pw.SizedBox(height: 20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Подпись преподавателя: _________________________'),
                  pw.SizedBox(height: 8),
                  pw.Text('Подпись старосты: _________________________'),
                ],
              ),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 20),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Container(
                      width: 18,
                      height: 18,
                      margin: const pw.EdgeInsets.only(right: 5),
                      child: pw.Image(pw.MemoryImage(logoBytes)),
                    ),
                    pw.Text(
                      'made in EduAtt with love',
                      style: pw.TextStyle(fontSize: 7, color: PdfColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  return pdf.save();
}

pw.Table _buildAttendanceTable(
  List<String> dayHeaders,
  List<String> subjectHeaders,
  List<String> studentNames,
  List<List<String>> attendance,
  pw.Font boldFont,
  pw.Font regularFont,
) {
  final rows = <pw.TableRow>[];

  // Верхний заголовок: дни недели
  final topHeaderCells = <pw.Widget>[
    pw.Text('№', style: pw.TextStyle(font: boldFont)),
    pw.Text('ФИО студента', style: pw.TextStyle(font: boldFont)),
    for (final day in dayHeaders)
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Text(day, style: pw.TextStyle(font: boldFont)),
      ),
  ];
  rows.add(pw.TableRow(children: topHeaderCells)); // ← children, не cells!

  // Нижний заголовок: предметы
  final bottomHeaderCells = <pw.Widget>[
    pw.Text(''),
    pw.Text(''),
    for (final subject in subjectHeaders)
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Align(
          // ← Используем pw.Align вместо alignment
          alignment: pw.Alignment.center,
          child: pw.Text(
            subject,
            style: pw.TextStyle(font: regularFont, fontSize: 8),
          ),
        ),
      ),
  ];
  rows.add(pw.TableRow(children: bottomHeaderCells)); // ← children

  // Строки студентов
  for (int i = 0; i < studentNames.length; i++) {
    final cells = <pw.Widget>[
      pw.Text('${i + 1}', style: pw.TextStyle(font: regularFont)),
      pw.Text(studentNames[i], style: pw.TextStyle(font: regularFont)),
      for (final status in attendance[i])
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            status,
            style: pw.TextStyle(font: regularFont, fontSize: 11),
          ),
        ),
    ];
    rows.add(pw.TableRow(children: cells)); // ← children
  }

  return pw.Table(
    border: pw.TableBorder.all(width: 0.5),
    children: rows,
    tableWidth: pw.TableWidth.max,
  );
}
