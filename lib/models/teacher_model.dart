class TeacherModel {
  final String? id; // nullable, присваивается Supabase
  final String institutionId;
  final String name;
  final String surname;
  final String email;
  final String password;
  final String? department;
  final DateTime createdAt;
  final String login;

  TeacherModel({
    this.id,
    required this.institutionId,
    required this.name,
    required this.surname,
    required this.email,
    required this.password,
    this.department,
    required this.createdAt,
    required this.login,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] as String?,
      institutionId: json['institution_id'] as String,
      name: json['name'] as String,
      surname: json['surname'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      department: json['department'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      login: json['login'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // отправляем только если id уже есть
      'institution_id': institutionId,
      'name': name,
      'surname': surname,
      'email': email,
      'password': password,
      'department': department,
      'created_at': createdAt.toIso8601String(),
      'login': login,
    };
  }
}
