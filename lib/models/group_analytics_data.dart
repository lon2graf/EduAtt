import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';

class StudentAttendanceStat {
  final String studentId;
  final String studentName;
  final int total;
  final int present;
  final int late;
  final int absent;
  final double percentage;

  const StudentAttendanceStat({
    required this.studentId,
    required this.studentName,
    required this.total,
    required this.present,
    required this.late,
    required this.absent,
    required this.percentage,
  });

  bool get isAtRisk => total >= 2 && percentage < 60;
}

class LessonTimelineStat {
  final String lessonId;
  final DateTime date;
  final int totalStudents;
  final int presentCount;
  final double percentage;

  const LessonTimelineStat({
    required this.lessonId,
    required this.date,
    required this.totalStudents,
    required this.presentCount,
    required this.percentage,
  });
}

class GroupAnalyticsData {
  final int totalRecords;
  final int totalPresent;
  final int totalLate;
  final int totalAbsent;
  final double overallPercentage;
  final List<StudentAttendanceStat> byStudent;
  final List<LessonTimelineStat> timeline;

  const GroupAnalyticsData({
    required this.totalRecords,
    required this.totalPresent,
    required this.totalLate,
    required this.totalAbsent,
    required this.overallPercentage,
    required this.byStudent,
    required this.timeline,
  });

  static const GroupAnalyticsData empty = GroupAnalyticsData(
    totalRecords: 0,
    totalPresent: 0,
    totalLate: 0,
    totalAbsent: 0,
    overallPercentage: 0,
    byStudent: [],
    timeline: [],
  );

  bool get isEmpty => totalRecords == 0;
  List<StudentAttendanceStat> get atRisk =>
      byStudent.where((s) => s.isAtRisk).toList();
}

class GroupAnalyticsHelper {
  GroupAnalyticsHelper._();

  static GroupAnalyticsData compute(List<LessonAttendanceModel> records) {
    if (records.isEmpty) return GroupAnalyticsData.empty;

    final byStudent = <String, List<LessonAttendanceModel>>{};
    final byLesson = <String, List<LessonAttendanceModel>>{};

    for (final r in records) {
      byStudent.putIfAbsent(r.studentId, () => []).add(r);
      byLesson.putIfAbsent(r.lessonId, () => []).add(r);
    }

    final studentStats = byStudent.entries.map((e) {
      final recs = e.value;
      final present =
          recs.where((r) => r.status == AttendanceStatus.present).length;
      final late =
          recs.where((r) => r.status == AttendanceStatus.late).length;
      final absent =
          recs.where((r) => r.status == AttendanceStatus.absent).length;
      final total = recs.length;
      return StudentAttendanceStat(
        studentId: e.key,
        studentName: recs.first.studentName ?? e.key,
        total: total,
        present: present,
        late: late,
        absent: absent,
        percentage: total > 0 ? (present + late) / total * 100.0 : 0.0,
      );
    }).toList()
      ..sort((a, b) => a.percentage.compareTo(b.percentage));

    final timeline = byLesson.entries.map((e) {
      final recs = e.value;
      final presentCount = recs
          .where((r) =>
              r.status == AttendanceStatus.present ||
              r.status == AttendanceStatus.late)
          .length;
      return LessonTimelineStat(
        lessonId: e.key,
        date: recs.first.lessonDate ?? DateTime(2000),
        totalStudents: recs.length,
        presentCount: presentCount,
        percentage:
            recs.isNotEmpty ? presentCount / recs.length * 100.0 : 0.0,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalPresent =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final totalLate =
        records.where((r) => r.status == AttendanceStatus.late).length;
    final totalAbsent =
        records.where((r) => r.status == AttendanceStatus.absent).length;
    final total = records.length;

    return GroupAnalyticsData(
      totalRecords: total,
      totalPresent: totalPresent,
      totalLate: totalLate,
      totalAbsent: totalAbsent,
      overallPercentage:
          total > 0 ? (totalPresent + totalLate) / total * 100.0 : 0.0,
      byStudent: studentStats,
      timeline: timeline,
    );
  }
}
