import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:edu_att/models/lesson_model.dart';
import 'package:edu_att/models/lesson_attendance_status.dart';
import 'package:edu_att/data/remote/lesson_service.dart';
import 'package:flutter_riverpod/legacy.dart';

class CurrentLessonNotifier extends StateNotifier<LessonModel?> {
  CurrentLessonNotifier() : super(null);

  // Переменная для хранения подписки
  StreamSubscription? _statusSubscription;

  /// Твой основной метод загрузки, теперь с Realtime-фундаментом
  Future<void> loadCurrentLesson(String groupId) async {
    // 1. Сначала делаем обычный запрос, как и раньше
    final lesson = await LessonService.getCurrentLesson(groupId);
    state = lesson;

    // 2. Если урок найден, сразу запускаем прослушку его статуса
    if (lesson != null && lesson.id != null) {
      _startStatusStream(lesson.id!);
    }
  }

  Future<void> loadCurrentLessonForTeacher(String teacherId) async {
    final lesson = await LessonService.getCurrentLessonForTeacher(teacherId);
    state = lesson;

    if (lesson != null && lesson.id != null) {
      _startStatusStream(lesson.id!);
    }
  }

  /// Внутренний метод для запуска Stream
  void _startStatusStream(String lessonId) {
    // Отменяем предыдущую подписку, чтобы не плодить утечки памяти
    _statusSubscription?.cancel();

    _statusSubscription = Supabase.instance.client
        .from('lessons')
        .stream(primaryKey: ['id'])
        .eq('id', lessonId)
        .listen(
          (List<Map<String, dynamic>> data) {
            if (data.isNotEmpty && state != null) {
              // Парсим статус из базы
              final newStatusStr = data.first['attendance_status'] as String?;
              final updatedStatus = LessonAttendanceStatus.fromString(
                newStatusStr,
              );

              // Если статус в базе изменился — обновляем стейт через copyWith
              if (state!.status != updatedStatus) {
                print(
                  '📡 [Realtime] Статус урока в БД изменился на: $updatedStatus',
                );
                state = state!.copyWith(status: updatedStatus);
              }
            }
          },
          onError: (error) {
            print('❌ [Realtime Error] Ошибка в стриме урока: $error');
          },
        );
  }

  // Обновление статуса (локальное)
  void updateStatus(LessonAttendanceStatus newStatus) {
    if (state == null) return;
    state = state!.copyWith(status: newStatus);
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}

// Провайдер остается таким же
final currentLessonProvider =
    StateNotifierProvider<CurrentLessonNotifier, LessonModel?>((ref) {
      return CurrentLessonNotifier();
    });
