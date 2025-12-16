// lib/models/attendance_report_data_model.dart
class AttendanceReportData {
  final String groupName;
  final String startDateStr;
  final String endDateStr;
  final List<String> studentNames;
  final List<List<String>> attendance;
  final List<String> dayHeaders; // ← новые
  final List<String> subjectHeaders; // ← новые

  AttendanceReportData({
    required this.groupName,
    required this.startDateStr,
    required this.endDateStr,
    required this.studentNames,
    required this.attendance,
    required this.dayHeaders,
    required this.subjectHeaders,
  });
}
