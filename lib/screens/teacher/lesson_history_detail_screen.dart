import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/models/lesson_attendance_model.dart';
import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/models/attendance_status.dart';
import 'package:edu_att/models/excuse_request_model.dart';
import 'package:edu_att/providers/lesson_attendance_mark_provider.dart';
import 'package:edu_att/providers/app_database_provider.dart';
import 'package:edu_att/data/repositories/excuse_repository.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';
import 'package:edu_att/utils/app_logger.dart';

class LessonHistoryDetailScreen extends ConsumerStatefulWidget {
  final LessonModel lesson;

  const LessonHistoryDetailScreen({required this.lesson, super.key});

  @override
  ConsumerState<LessonHistoryDetailScreen> createState() => _LessonHistoryDetailScreenState();
}

class _LessonHistoryDetailScreenState extends ConsumerState<LessonHistoryDetailScreen> {
  bool _loading = true;
  bool _saving = false;

  List<StudentModel> _students = [];
  Map<String, AttendanceStatus?> _statuses = {};
  Map<String, String?> _attendanceIds = {};
  // studentId → объяснительная (pending/approved/rejected)
  Map<String, ExcuseRequestModel?> _excuses = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(appDatabaseProvider);
    final lesson = widget.lesson;

    final studentRows = await (db.select(db.students)
          ..where((s) => s.groupId.equals(lesson.groupId)))
        .get();

    studentRows.sort((a, b) => a.surname.compareTo(b.surname));

    final students = studentRows
        .map(
          (r) => StudentModel(
            id: r.id,
            name: r.name,
            surname: r.surname,
            groupId: r.groupId,
            isHeadman: r.isHeadman,
          ),
        )
        .toList();

    final attendanceList = lesson.id != null
        ? await ref.read(attendanceRepositoryProvider).getForLesson(lesson.id!)
        : <LessonAttendanceModel>[];

    final statusMap = <String, AttendanceStatus?>{};
    final idMap = <String, String?>{};
    for (final s in students) {
      statusMap[s.id!] = null;
      idMap[s.id!] = null;
    }
    for (final a in attendanceList) {
      statusMap[a.studentId] = a.status;
      idMap[a.studentId] = a.id;
    }

    // Загружаем объяснительные для этого урока
    final excuseList = lesson.id != null
        ? await ref.read(excuseRepositoryProvider).getForLesson(lesson.id!)
        : <ExcuseRequestModel>[];
    final excuseMap = <String, ExcuseRequestModel?>{};
    for (final e in excuseList) {
      excuseMap[e.studentId] = e;
    }

    if (mounted) {
      setState(() {
        _students = students;
        _statuses = statusMap;
        _attendanceIds = idMap;
        _excuses = excuseMap;
        _loading = false;
      });
    }
  }

  Future<_StudentStats> _loadStudentStats(String studentId) async {
    final db = ref.read(appDatabaseProvider);
    final lesson = widget.lesson;

    // 1. ID предметов с нужным названием
    final subjectRows = await (db.select(db.subjects)
          ..where((s) => s.name.equals(lesson.subjectName)))
        .get();
    final subjectIds = subjectRows.map((s) => s.id).toSet();
    if (subjectIds.isEmpty) return _StudentStats.empty(lesson.subjectName);

    // 2. ID слотов расписания для этой группы + этих предметов
    final scheduleRows = await (db.select(db.schedules)
          ..where((s) => s.groupId.equals(lesson.groupId)))
        .get();
    final scheduleIds = scheduleRows
        .where((s) => subjectIds.contains(s.subjectId))
        .map((s) => s.id)
        .toSet();
    if (scheduleIds.isEmpty) return _StudentStats.empty(lesson.subjectName);

    // 3. ID уроков по этим слотам расписания
    final lessonRows = await db.select(db.lessons).get();
    final lessonIds = lessonRows
        .where((l) => scheduleIds.contains(l.scheduleId))
        .map((l) => l.id)
        .toSet();
    if (lessonIds.isEmpty) return _StudentStats.empty(lesson.subjectName);

    // 4. Отметки студента, фильтруем по нужным урокам
    final attendanceRows = await (db.select(db.lessonAttendances)
          ..where((a) => a.studentId.equals(studentId)))
        .get();
    final relevant = attendanceRows.where((a) => lessonIds.contains(a.lessonId)).toList();

    int present = 0, absent = 0, late = 0;
    for (final r in relevant) {
      if (r.status == 'present') {
        present++;
      } else if (r.status == 'absent') {
        absent++;
      } else if (r.status == 'late') {
        late++;
      }
    }

    return _StudentStats(
      subjectName: lesson.subjectName,
      total: lessonIds.length,
      present: present,
      absent: absent,
      late: late,
      unmarked: lessonIds.length - relevant.length,
    );
  }

  void _showExcuseReviewSheet(StudentModel student) {
    final excuse = _excuses[student.id!];
    if (excuse == null) return;
    final attendanceId = _attendanceIds[student.id!];
    final teacherId = ref.read(teacherProvider)?.id ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ExcuseReviewSheet(
        student: student,
        excuse: excuse,
        onReview: (approved) async {
          if (attendanceId == null) return;
          try {
            final synced = await ref.read(excuseRepositoryProvider).reviewExcuse(
              excuseId: excuse.id,
              approved: approved,
              teacherId: teacherId,
              attendanceId: attendanceId,
            );
            // Обновляем локальный стейт
            setState(() {
              _excuses[student.id!] = excuse.copyWith(
                status: approved
                    ? ExcuseStatusType.approved
                    : ExcuseStatusType.rejected,
              );
            });
            if (mounted) {
              final label = approved ? 'Причина принята' : 'Причина отклонена';
              if (synced) {
                EduSnackBar.showSuccess(context, ref, label);
              } else {
                EduSnackBar.showInfo(
                  context,
                  ref,
                  '$label (синхронизируем при подключении)',
                );
              }
            }
          } catch (e) {
            AppLogger.error('reviewExcuse', e, null, 'LessonHistoryDetailScreen');
            if (mounted) EduSnackBar.showError(context, ref, 'Ошибка');
          }
        },
      ),
    );
  }

  void _showStudentSheet(StudentModel student) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _StudentStatsSheet(
        student: student,
        loadStats: () => _loadStudentStats(student.id!),
      ),
    );
  }

  Future<void> _save() async {
    final lessonId = widget.lesson.id;
    if (lessonId == null) return;
    setState(() => _saving = true);
    try {
      final toSave = _students
          .where((s) => _statuses[s.id!] != null)
          .map(
            (s) => LessonAttendanceModel(
              id: _attendanceIds[s.id!],
              lessonId: lessonId,
              studentId: s.id!,
              studentName: '${s.surname} ${s.name}',
              status: _statuses[s.id!],
            ),
          )
          .toList();

      final repo = ref.read(attendanceRepositoryProvider);
      await repo.saveLocally(toSave);
      try {
        await repo.syncToRemote();
        if (mounted) EduSnackBar.showSuccess(context, ref, 'Ведомость обновлена!');
      } catch (_) {
        if (mounted) {
          EduSnackBar.showInfo(context, ref, 'Сохранено локально, отправим при подключении');
        }
      }
    } catch (e) {
      AppLogger.error('Ошибка сохранения ведомости', e, null, 'LessonHistoryDetailScreen');
      if (mounted) EduSnackBar.showError(context, ref, 'Ошибка сохранения');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lesson = widget.lesson;

    final filtered = _searchQuery.isEmpty
        ? _students
        : _students
            .where(
              (s) => '${s.surname} ${s.name}'
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()),
            )
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.subjectName),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(colorScheme, lesson),
                _buildSearchField(colorScheme),
                Expanded(child: _buildStudentList(filtered, colorScheme)),
                _buildBottomBar(colorScheme),
              ],
            ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, LessonModel lesson) {
    String formatTime(String t) {
      final parts = t.split(':');
      return parts.length >= 2 ? '${parts[0]}:${parts[1]}' : t;
    }

    String formatDate(String d) {
      try {
        final dt = DateTime.parse(d);
        const months = [
          '', 'янв', 'фев', 'мар', 'апр', 'май', 'июн',
          'июл', 'авг', 'сен', 'окт', 'ноя', 'дек',
        ];
        return '${dt.day} ${months[dt.month]} ${dt.year}';
      } catch (_) {
        return d;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_outlined, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                lesson.groupName,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
              ),
              const Spacer(),
              Text(
                formatDate(lesson.date),
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.access_time_outlined, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                '${formatTime(lesson.startTime)} – ${formatTime(lesson.endTime)}',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
              ),
              if (lesson.topic != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    lesson.topic!,
                    style: TextStyle(color: colorScheme.primary, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Поиск по фамилии...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildStudentList(List<StudentModel> students, ColorScheme colorScheme) {
    if (students.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Text('Не найдено', style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }

    final present = _statuses.values.where((s) => s == AttendanceStatus.present).length;
    final absent = _statuses.values.where((s) => s == AttendanceStatus.absent).length;
    final late = _statuses.values.where((s) => s == AttendanceStatus.late).length;
    final unmarked = _statuses.values.where((s) => s == null).length;

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              _statChip('Присутствует: $present', Colors.green),
              const SizedBox(width: 8),
              _statChip('Отсутствует: $absent', Colors.red),
              if (late > 0) ...[
                const SizedBox(width: 8),
                _statChip('Опоздал: $late', Colors.orange),
              ],
              if (unmarked > 0) ...[
                const SizedBox(width: 8),
                _statChip('Не отмечен: $unmarked', Colors.grey),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: students.length,
            itemBuilder: (context, i) {
              final s = students[i];
              return _StudentRow(
                student: s,
                status: _statuses[s.id!],
                excuse: _excuses[s.id!],
                onStatus: (newStatus) {
                  HapticFeedback.lightImpact();
                  setState(() => _statuses[s.id!] = newStatus);
                },
                onTap: () => _showStudentSheet(s),
                onExcuseTap: _excuses[s.id!] != null
                    ? () => _showExcuseReviewSheet(s)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _statChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Сохранить ведомость'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Строка студента ────────────────────────────────────────────────────────────

class _StudentRow extends StatelessWidget {
  final StudentModel student;
  final AttendanceStatus? status;
  final ExcuseRequestModel? excuse;
  final void Function(AttendanceStatus?) onStatus;
  final VoidCallback onTap;
  final VoidCallback? onExcuseTap;

  const _StudentRow({
    required this.student,
    required this.status,
    this.excuse,
    required this.onStatus,
    required this.onTap,
    this.onExcuseTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${student.surname} ${student.name}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      Icon(
                        Icons.bar_chart_rounded,
                        size: 18,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (excuse != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onExcuseTap,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: excuse!.status.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.mark_email_unread_outlined,
                    size: 17,
                    color: excuse!.status.color,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 10),
            _statusBtn(AttendanceStatus.present, Icons.check, Colors.green),
            const SizedBox(width: 4),
            _statusBtn(AttendanceStatus.absent, Icons.close, Colors.red),
            const SizedBox(width: 4),
            _statusBtn(AttendanceStatus.late, Icons.access_time, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _statusBtn(AttendanceStatus s, IconData icon, Color color) {
    final isSelected = status == s;
    return GestureDetector(
      onTap: () => onStatus(isSelected ? null : s),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: isSelected ? Colors.white : color),
      ),
    );
  }
}

// ── Статистика студента ────────────────────────────────────────────────────────

class _StudentStats {
  final String subjectName;
  final int total;
  final int present;
  final int absent;
  final int late;
  final int unmarked;

  const _StudentStats({
    required this.subjectName,
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.unmarked,
  });

  double get attendancePercent => total == 0 ? 0.0 : present / total;

  factory _StudentStats.empty(String subjectName) => _StudentStats(
    subjectName: subjectName,
    total: 0,
    present: 0,
    absent: 0,
    late: 0,
    unmarked: 0,
  );
}

class _StudentStatsSheet extends StatefulWidget {
  final StudentModel student;
  final Future<_StudentStats> Function() loadStats;

  const _StudentStatsSheet({required this.student, required this.loadStats});

  @override
  State<_StudentStatsSheet> createState() => _StudentStatsSheetState();
}

class _StudentStatsSheetState extends State<_StudentStatsSheet> {
  _StudentStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.loadStats().then((s) {
      if (mounted) setState(() { _stats = s; _loading = false; });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final student = widget.student;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ручка
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Имя студента
          Text(
            '${student.surname} ${student.name}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (student.isHeadman) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Староста',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),

          if (_loading) ...[
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
            const SizedBox(height: 32),
          ] else if (_stats != null) ...[
            Text(
              _stats!.subjectName,
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Полоса посещаемости
            if (_stats!.total > 0) ...[
              _buildProgressBar(_stats!, colorScheme),
              const SizedBox(height: 16),
            ],

            // Процент
            Text(
              _stats!.total == 0
                  ? '—'
                  : '${(_stats!.attendancePercent * 100).round()}%',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: _percentColor(_stats!.attendancePercent),
              ),
            ),
            Text(
              'посещаемость',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 24),

            // Детальные счётчики
            _buildCountsRow(_stats!, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(_StudentStats stats, ColorScheme colorScheme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            if (stats.present > 0)
              Expanded(flex: stats.present, child: Container(color: Colors.green)),
            if (stats.late > 0)
              Expanded(flex: stats.late, child: Container(color: Colors.orange)),
            if (stats.absent > 0)
              Expanded(flex: stats.absent, child: Container(color: Colors.red)),
            if (stats.unmarked > 0)
              Expanded(
                flex: stats.unmarked,
                child: Container(color: colorScheme.surfaceContainerHighest),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountsRow(_StudentStats stats, ColorScheme colorScheme) {
    return Row(
      children: [
        _countTile('Присутствовал', stats.present, Colors.green, colorScheme),
        _countTile('Отсутствовал', stats.absent, Colors.red, colorScheme),
        _countTile('Опоздал', stats.late, Colors.orange, colorScheme),
        _countTile('Не отмечен', stats.unmarked, Colors.grey, colorScheme),
      ],
    );
  }

  Widget _countTile(String label, int count, Color color, ColorScheme colorScheme) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Color _percentColor(double percent) {
    if (percent >= 0.8) return Colors.green;
    if (percent >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

// ── Шит проверки объяснительной (преподаватель) ───────────────────────────────

class _ExcuseReviewSheet extends StatelessWidget {
  final StudentModel student;
  final ExcuseRequestModel excuse;
  final Future<void> Function(bool approved) onReview;

  const _ExcuseReviewSheet({
    required this.student,
    required this.excuse,
    required this.onReview,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alreadyReviewed = excuse.status != ExcuseStatusType.pending;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Объяснительная',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${student.surname} ${student.name}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Статус если уже рассмотрено
              if (alreadyReviewed)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: excuse.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    excuse.status.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: excuse.status.color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Причина
          _InfoRow(
            icon: excuse.reasonType.icon,
            label: 'Причина',
            value: excuse.reasonType.label,
            colorScheme: colorScheme,
          ),
          if (excuse.description != null && excuse.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                excuse.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          if (!alreadyReviewed) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await onReview(false);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Отклонить'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await onReview(true);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Принять'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Закрыть'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
