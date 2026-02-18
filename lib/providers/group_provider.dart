import 'package:edu_att/models/student_model.dart';
import 'package:edu_att/services/student_service.dart';
import 'package:flutter_riverpod/legacy.dart';

// Провайдер для списка студентов группы
final groupStudentsProvider =
    StateNotifierProvider<GroupStudentsNotifier, List<StudentModel>>(
      (ref) => GroupStudentsNotifier(),
    );

class GroupStudentsNotifier extends StateNotifier<List<StudentModel>> {
  GroupStudentsNotifier() : super([]);

  /// Загружает список студентов по ID группы
  Future<void> loadGroupStudents(String groupId) async {
    state = []; // Очищаем предыдущий список (или можно показать загрузку)
    try {
      final students = await StudentServices.GetStudentsByGroupId(groupId);
      state = students;
    } catch (e) {
      print('Ошибка в GroupStudentsNotifier.loadGroupStudents: $e');
      state = []; // В случае ошибки устанавливаем пустой список
    }
  }

  /// Очищает список
  void clear() {
    state = [];
  }

  /// Позволяет получить список студентов, отфильтрованный по isHeadman
  List<StudentModel> getStudentsExcludingHeadman() {
    return state.where((student) => !student.isHeadman).toList();
  }
}
