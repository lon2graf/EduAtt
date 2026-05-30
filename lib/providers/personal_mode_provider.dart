import 'package:flutter_riverpod/legacy.dart';

enum PersonalRole { student, headman, teacher }

extension PersonalRoleExt on PersonalRole {
  String get label => switch (this) {
        PersonalRole.student => 'Студент',
        PersonalRole.headman => 'Староста',
        PersonalRole.teacher => 'Преподаватель',
      };

  String get storedValue => name;

  static PersonalRole? fromString(String? value) => switch (value) {
        'student' => PersonalRole.student,
        'headman' => PersonalRole.headman,
        'teacher' => PersonalRole.teacher,
        _ => null,
      };
}

class PersonalModeState {
  final bool isActive;
  final PersonalRole? role;

  const PersonalModeState({this.isActive = false, this.role});

  bool get isTeacher => isActive && role == PersonalRole.teacher;
  bool get isStudentOrHeadman =>
      isActive && (role == PersonalRole.student || role == PersonalRole.headman);
  bool get canManageGroup =>
      isActive && (role == PersonalRole.headman || role == PersonalRole.teacher);
}

class PersonalModeNotifier extends StateNotifier<PersonalModeState> {
  PersonalModeNotifier() : super(const PersonalModeState());

  void activate(PersonalRole role) =>
      state = PersonalModeState(isActive: true, role: role);

  void deactivate() => state = const PersonalModeState();
}

final personalModeProvider =
    StateNotifierProvider<PersonalModeNotifier, PersonalModeState>(
  (ref) => PersonalModeNotifier(),
);
