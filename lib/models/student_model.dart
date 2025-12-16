class StudentModel {
  final String? id;
  final String? institutionId;
  final String name;
  final String surname;
  final String? email;
  final String? password;
  final DateTime? createdAt;
  final String? login;
  final String groupId;
  final String? groupName;
  final bool isHeadman;

  StudentModel({
    this.id,
    this.institutionId,
    required this.name,
    required this.surname,
    this.email,
    this.password,
    this.createdAt,
    this.login,
    required this.groupId,
    this.groupName,
    required this.isHeadman,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final groups = json['groups'] as Map<String, dynamic>? ?? {};

    return StudentModel(
      id: json['id'] as String?,
      institutionId: json['institution_id'] as String?,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (institutionId != null) 'institution_id': institutionId,
      'name': name,
      'surname': surname,
      if (email != null) 'email': email,
      if (password != null) 'password': password,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (login != null) 'login': login,
      'group_id': groupId,
      'isHeadman': isHeadman,
    };
  }
}
