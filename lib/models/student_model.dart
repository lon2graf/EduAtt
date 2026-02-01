class StudentModel {
  final String? id;
  final String name;
  final String surname;
  final String? email;
  final String? password;
  final DateTime? createdAt;
  final String? login;
  final String groupId;
  final String? groupName;
  final bool isHeadman;
  final String? institution_id;

  StudentModel({
    this.id,
    required this.name,
    required this.surname,
    this.email,
    this.password,
    this.createdAt,
    this.login,
    required this.groupId,
    this.groupName,
    required this.isHeadman,
    this.institution_id,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final groups = json['groups'] as Map<String, dynamic>? ?? {};

    return StudentModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      surname: json['surname'] as String,
      email: json['email'] as String?,
      password: json['password'] as String?,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null,
      login: json['login'] as String?,
      groupId: json['group_id'] as String,
      groupName: groups['name'] as String?,
      isHeadman: json['isHeadman'] as bool,
      institution_id: groups['institution_id'] as String?,
    );
  }
}
