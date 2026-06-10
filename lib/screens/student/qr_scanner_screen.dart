import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:edu_att/providers/student_provider.dart';
import 'package:edu_att/data/repositories/lesson_repository.dart';
import 'package:edu_att/data/remote/lessons_attendace_service.dart';
import 'package:edu_att/utils/edu_snack_bar.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  bool _processing = false;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final lessonId = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (lessonId == null || lessonId.isEmpty) return;

    setState(() => _processing = true);

    final student = ref.read(currentStudentProvider);
    if (student?.id == null) {
      _fail('Не удалось определить студента');
      return;
    }

    // Проверяем что урок прямо сейчас активен для группы студента
    final currentLesson = await ref
        .read(lessonRepositoryProvider)
        .getCurrentLesson(student!.groupId);

    if (currentLesson == null) {
      _fail('Нет активного урока прямо сейчас');
      return;
    }
    if (currentLesson.id != lessonId) {
      _fail('QR не соответствует текущему уроку');
      return;
    }

    try {
      await LessonsAttendanceService.markSelfPresent(
        lessonId: lessonId,
        studentId: student.id!,
      );
      if (mounted) {
        EduSnackBar.showSuccess(context, ref, 'Присутствие отмечено!');
        context.go('/student/home');
      }
    } catch (_) {
      _fail('Ошибка при отметке. Попробуйте ещё раз');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    EduSnackBar.showError(context, ref, message);
    setState(() => _processing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отметиться через QR'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/student/home'),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),

          // Рамка наводки
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.5),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),

          // Подсказка снизу
          Positioned(
            bottom: 56,
            left: 24,
            right: 24,
            child: Text(
              'Наведите камеру на QR-код преподавателя',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),

          // Оверлей во время обработки
          if (_processing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
