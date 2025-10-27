class StudentModel {
  final String? id; // nullable, присваивается Supabase
  final String institutionId;
  final String name;
  final String surname;
  final String email;
  final String password;
  final DateTime createdAt;
  final String login;
  final String groupId;
  final bool isHeadman;

  StudentModel({
    this.id,
    required this.institutionId,
    required this.name,
    required this.surname,
    required this.email,
    required this.password,
    required this.createdAt,
    required this.login,
    required this.groupId,
    required this.isHeadman,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String?,
      institutionId: json['institution_id'] as String,
      name: json['name'] as String,
      surname: json['surname'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      login: json['login'] as String,
      groupId: json['group_id'] as String,
      isHeadman: json['isHeadman'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'institution_id': institutionId,
      'name': name,
      'surname': surname,
      'email': email,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'login': login,
      'group_id': groupId,
      'isHeadman': isHeadman,
    };
  }
}
