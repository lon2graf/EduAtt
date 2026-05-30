import 'package:edu_att/data/services/backup_service.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Показывает диалог подтверждения выхода в личном режиме.
/// Возвращает true, если пользователь подтвердил выход.
Future<bool> showPersonalLogoutDialog(BuildContext context, WidgetRef ref) async {
  final result = await showDialog<_LogoutAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _LogoutConfirmDialog(ref: ref),
  );
  return result == _LogoutAction.logout;
}

enum _LogoutAction { cancel, logout }

class _LogoutConfirmDialog extends StatefulWidget {
  final WidgetRef ref;
  const _LogoutConfirmDialog({required this.ref});

  @override
  State<_LogoutConfirmDialog> createState() => _LogoutConfirmDialogState();
}

class _LogoutConfirmDialogState extends State<_LogoutConfirmDialog> {
  bool _isExporting = false;

  Future<void> _doExport() async {
    setState(() => _isExporting = true);
    try {
      await widget.ref.read(backupServiceProvider).exportToFile();
      if (mounted) {
        EduSnackBar.showSuccess(
          context,
          widget.ref,
          'Файл сохранён. Теперь можно выйти.',
        );
      }
    } catch (e) {
      if (mounted) {
        EduSnackBar.showError(context, widget.ref, 'Ошибка экспорта: $e');
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Выход из личного режима'),
        ],
      ),
      content: const Text(
        'Все данные личного режима (расписание, отметки, предметы) '
        'будут безвозвратно удалены.\n\n'
        'Рекомендуем сделать экспорт в JSON перед выходом.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _LogoutAction.cancel),
          child: const Text('Отмена'),
        ),
        OutlinedButton.icon(
          onPressed: _isExporting ? null : _doExport,
          icon: _isExporting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_outlined, size: 16),
          label: const Text('Сначала экспорт'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _LogoutAction.logout),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Всё равно выйти'),
        ),
      ],
    );
  }
}
