import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';

class SubjectAnalysis {
  final int total;
  final int present;
  final int absent;
  final int late;
  final double percentage;
  final List<LessonAttendanceModel> sortedHistory;

  const SubjectAnalysis({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.percentage,
    required this.sortedHistory,
  });

  bool get isEmpty => total == 0;
}

class SubjectStat {
  final String name;
  final double percentage;
  final int total;
  final int present;

  const SubjectStat({
    required this.name,
    required this.percentage,
    required this.total,
    required this.present,
  });
}

class AttendanceAnalyticsHelper {
  static Map<AttendanceStatus, int> calculateStatusCounts(
    List<LessonAttendanceModel> data,
  ) {
    final counts = {
      AttendanceStatus.present: 0,
      AttendanceStatus.absent: 0,
      AttendanceStatus.late: 0,
    };
    for (final item in data) {
      final status = item.status;
      if (status != null && counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      }
    }
    return counts;
  }

  static List<SubjectStat> calculateSubjectStats(
    List<LessonAttendanceModel> data,
  ) {
    final Map<String, List<LessonAttendanceModel>> grouped = {};
    for (final item in data) {
      if (item.status == null) continue;
      final key = item.subjectName ?? 'Предмет';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final stats = grouped.entries.map((entry) {
      final total = entry.value.length;
      final present = entry.value
          .where((a) =>
              a.status == AttendanceStatus.present ||
              a.status == AttendanceStatus.late)
          .length;
      return SubjectStat(
        name: entry.key,
        percentage: total > 0 ? present / total * 100.0 : 0.0,
        total: total,
        present: present,
      );
    }).toList();

    stats.sort((a, b) => b.percentage.compareTo(a.percentage));
    return stats;
  }

  static double calculateOverallPercentage(
    List<LessonAttendanceModel> data,
  ) {
    final withStatus = data.where((a) => a.status != null).toList();
    if (withStatus.isEmpty) return 0.0;
    final present = withStatus
        .where((a) =>
            a.status == AttendanceStatus.present ||
            a.status == AttendanceStatus.late)
        .length;
    return present / withStatus.length * 100.0;
  }

  static SubjectAnalysis getSubjectAnalysis(
    List<LessonAttendanceModel> data,
  ) {
    final history = data.where((a) => a.status != null).toList()
      ..sort((a, b) => (a.lessonDate ?? DateTime(2000))
          .compareTo(b.lessonDate ?? DateTime(2000)));

    final total = history.length;
    final present =
        history.where((a) => a.status == AttendanceStatus.present).length;
    final absent =
        history.where((a) => a.status == AttendanceStatus.absent).length;
    final late =
        history.where((a) => a.status == AttendanceStatus.late).length;

    return SubjectAnalysis(
      total: total,
      present: present,
      absent: absent,
      late: late,
      percentage: total > 0 ? (present + late) / total * 100.0 : 0.0,
      sortedHistory: history,
    );
  }

  static List<LessonAttendanceModel> filterByDate(
    List<LessonAttendanceModel> data,
    DateTime date,
  ) {
    return data.where((a) {
      final d = a.lessonDate;
      return d != null &&
          d.year == date.year &&
          d.month == date.month &&
          d.day == date.day;
    }).toList();
  }
}
