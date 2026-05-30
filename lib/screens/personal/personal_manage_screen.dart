import 'package:edu_att/data/local_db/app_database.dart';
import 'package:edu_att/data/services/backup_service.dart';
import 'package:edu_att/data/services/personal_mode_service.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/providers/teacher_provider.dart';
import 'package:edu_att/providers/personal_mode_provider.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// Экран управления данными личного режима:
/// вкладки Предметы / Группы и студенты (если canManageGroup) / Данные.
class PersonalManageScreen extends ConsumerStatefulWidget {
  const PersonalManageScreen({super.key});

  @override
  ConsumerState<PersonalManageScreen> createState() =>
      _PersonalManageScreenState();
}

class _PersonalManageScreenState extends ConsumerState<PersonalManageScreen>
    with SingleTickerProviderStateMixin {
  static const _uuid = Uuid();
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    final canManage = ref.read(personalModeProvider).canManageGroup;
    _tabs = TabController(length: canManage ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final personalState = ref.watch(personalModeProvider);
    final canManage = personalState.canManageGroup;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление данными'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            const Tab(icon: Icon(Icons.menu_book_outlined), text: 'Предметы'),
            if (canManage)
              const Tab(icon: Icon(Icons.group_outlined), text: 'Группы'),
            const Tab(icon: Icon(Icons.backup_outlined), text: 'Данные'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SubjectsTab(uuid: _uuid),
          if (canManage) _GroupsTab(uuid: _uuid),
          _BackupTab(),
        ],
      ),
    );
  }
}

// ─── Вкладка: Предметы ────────────────────────────────────────────────────────

class _SubjectsTab extends ConsumerStatefulWidget {
  final Uuid uuid;
  const _SubjectsTab({required this.uuid});

  @override
  ConsumerState<_SubjectsTab> createState() => _SubjectsTabState();
}

class _SubjectsTabState extends ConsumerState<_SubjectsTab> {
  List<Subject> _subjects = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ref.read(personalModeServiceProvider).getSubjects();
    if (mounted) setState(() => _subjects = s);
  }

  Future<void> _add() async {
    final name = await _inputDialog(context, 'Новый предмет', 'Название');
    if (name == null || name.trim().isEmpty) return;
    await ref.read(personalModeServiceProvider).insertSubject(widget.uuid.v4(), name.trim());
    _load();
  }

  Future<void> _delete(Subject s) async {
    await ref.read(personalModeServiceProvider).deleteSubject(s.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: _add,
        tooltip: 'Добавить предмет',
        child: const Icon(Icons.add),
      ),
      body: _subjects.isEmpty
          ? const _EmptyHint(text: 'Нажми «+» чтобы добавить предмет')
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _subjects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = _subjects[i];
                return _ItemCard(
                  title: s.name,
                  icon: Icons.menu_book_outlined,
                  onDelete: () => _delete(s),
                );
              },
            ),
    );
  }
}

// ─── Вкладка: Группы и студенты ───────────────────────────────────────────────

class _GroupsTab extends ConsumerStatefulWidget {
  final Uuid uuid;
  const _GroupsTab({required this.uuid});

  @override
  ConsumerState<_GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends ConsumerState<_GroupsTab> {
  List<Group> _groups = [];
  String? _expandedGroupId;
  Map<String, List<Student>> _studentsByGroup = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(personalModeServiceProvider);
    final groups = await service.getGroups();
    final studentMap = <String, List<Student>>{};
    for (final g in groups) {
      studentMap[g.id] = await service.getStudentsForGroup(g.id);
    }
    if (mounted) {
      setState(() {
        _groups = groups;
        _studentsByGroup = studentMap;
      });
    }
  }

  Future<void> _addGroup() async {
    final name = await _inputDialog(context, 'Новая группа', 'Название группы');
    if (name == null || name.trim().isEmpty) return;
    await ref
        .read(personalModeServiceProvider)
        .insertGroup(widget.uuid.v4(), name.trim());
    _load();
  }

  Future<void> _deleteGroup(Group g) async {
    await ref.read(personalModeServiceProvider).deleteGroup(g.id);
    _load();
  }

  Future<void> _addStudent(Group group) async {
    final input = await showDialog<(String, String)?>(
      context: context,
      builder: (ctx) => _AddStudentDialog(ctx: ctx),
    );
    if (input == null) return;
    final service = ref.read(personalModeServiceProvider);
    await service.insertStudent(
      id: widget.uuid.v4(),
      name: input.$2,
      surname: input.$1,
      groupId: group.id,
    );
    _load();
  }

  Future<void> _deleteStudent(Student s) async {
    await ref.read(personalModeServiceProvider).deleteStudent(s.id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.small(
        onPressed: _addGroup,
        tooltip: 'Добавить группу',
        child: const Icon(Icons.add),
      ),
      body: _groups.isEmpty
          ? const _EmptyHint(text: 'Нажми «+» чтобы создать группу')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _groups.length,
              itemBuilder: (context, i) {
                final g = _groups[i];
                final students = _studentsByGroup[g.id] ?? [];
                final expanded = _expandedGroupId == g.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.group_outlined),
                        title: Text(g.name,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${students.length} студ.'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.person_add_outlined, size: 20),
                              tooltip: 'Добавить студента',
                              onPressed: () => _addStudent(g),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.red),
                              tooltip: 'Удалить группу',
                              onPressed: () => _deleteGroup(g),
                            ),
                            IconButton(
                              icon: Icon(expanded
                                  ? Icons.expand_less
                                  : Icons.expand_more),
                              onPressed: () => setState(() =>
                                  _expandedGroupId = expanded ? null : g.id),
                            ),
                          ],
                        ),
                      ),
                      if (expanded)
                        ...students.map(
                          (s) => ListTile(
                            contentPadding:
                                const EdgeInsets.only(left: 32, right: 8),
                            leading: const Icon(Icons.person_outline, size: 20),
                            title: Text('${s.surname} ${s.name}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  size: 18, color: Colors.red),
                              onPressed: () => _deleteStudent(s),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ─── Вкладка: Резервное копирование ──────────────────────────────────────────

class _BackupTab extends ConsumerWidget {
  const _BackupTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(backupServiceProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _BackupCard(
          icon: Icons.upload_outlined,
          title: 'Экспорт данных',
          subtitle: 'Сохранить все данные в JSON-файл',
          color: Colors.green,
          onTap: () async {
            try {
              final path = await service.exportToFile();
              if (!context.mounted) return;
              if (path != null) {
                EduSnackBar.showSuccess(context, ref, 'Файл сохранён:\n$path');
              }
            } catch (e) {
              if (context.mounted) {
                EduSnackBar.showError(context, ref, 'Ошибка экспорта: $e');
              }
            }
          },
        ),
        const SizedBox(height: 16),
        _BackupCard(
          icon: Icons.download_outlined,
          title: 'Импорт данных',
          subtitle: 'Загрузить данные из JSON-файла (текущие данные будут удалены)',
          color: Colors.blue,
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Импорт данных'),
                content: const Text(
                  'Все текущие данные будут заменены данными из файла. Продолжить?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Отмена'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Импортировать'),
                  ),
                ],
              ),
            );
            if (confirm != true) return;
            try {
              final role = await service.importFromFile();
              if (role != null && context.mounted) {
                // Активируем провайдеры с восстановленными данными
                ref.read(personalModeProvider.notifier).activate(role);
                final pmService = ref.read(personalModeServiceProvider);
                if (role == PersonalRole.teacher) {
                  ref
                      .read(teacherProvider.notifier)
                      .loginPersonal(pmService.buildTeacherModel());
                } else {
                  ref
                      .read(currentStudentProvider.notifier)
                      .loginPersonal(pmService.buildStudentModel(role));
                }
              }
              if (context.mounted) {
                EduSnackBar.showSuccess(context, ref, 'Данные успешно импортированы');
              }
            } catch (e) {
              if (context.mounted) {
                EduSnackBar.showError(context, ref, 'Ошибка импорта: $e');
              }
            }
          },
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Это твой локальный журнал. Не забудь сделать бэкап перед удалением приложения!',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackupCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _BackupCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

// ─── Вспомогательные виджеты ──────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onDelete;

  const _ItemCard({
    required this.title,
    required this.icon,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  final BuildContext ctx;
  const _AddStudentDialog({required this.ctx});

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _surnameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _surnameCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить студента'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _surnameCtrl,
            decoration: const InputDecoration(labelText: 'Фамилия'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Имя'),
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final surname = _surnameCtrl.text.trim();
            final name = _nameCtrl.text.trim();
            if (surname.isNotEmpty && name.isNotEmpty) {
              Navigator.pop(context, (surname, name));
            }
          },
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}

// ─── Диалог ввода строки ──────────────────────────────────────────────────────

Future<String?> _inputDialog(
  BuildContext context,
  String title,
  String hint,
) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        decoration: InputDecoration(hintText: hint),
        textCapitalization: TextCapitalization.sentences,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, ctrl.text),
          child: const Text('Создать'),
        ),
      ],
    ),
  );
}
