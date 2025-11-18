class StudentModel {
  final String? id; // nullable, присваивается Supabase
  final String?
  institutionId; // nullable - может быть null, если не включен в select
  final String name;
  final String surname;
  final String? email; // nullable - может быть null, если не включен в select
  final String?
  password; // nullable - может быть null, если не включен в select
  final DateTime?
  createdAt; // nullable - может быть null, если не включен в select
  final String? login; // nullable - может быть null, если не включен в select
  final String groupId;
  final bool isHeadman;

  StudentModel({
    this.id,
    this.institutionId, // теперь может быть null
    required this.name,
    required this.surname,
    this.email, // теперь может быть null
    this.password, // теперь может быть null
    this.createdAt, // теперь может быть null
    this.login, // теперь может быть null
    required this.groupId,
    required this.isHeadman,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String?,
      institutionId:
          json['institution_id'] as String?, // Указываем как nullable
      name: json['name'] as String,
      surname: json['surname'] as String,
      email: json['email'] as String?, // Указываем как nullable
      password: json['password'] as String?, // Указываем как nullable
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : null, // Обрабатываем null
      login: json['login'] as String?, // Указываем как nullable
      groupId: json['group_id'] as String,
      isHeadman: json['isHeadman'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (institutionId != null)
        'institution_id': institutionId, // Проверяем на null при сериализации
      'name': name,
      'surname': surname,
      if (email != null) 'email': email, // Проверяем на null при сериализации
      if (password != null)
        'password': password, // Проверяем на null при сериализации
      if (createdAt != null)
        'created_at':
            createdAt!.toIso8601String(), // Проверяем на null при сериализации
      if (login != null) 'login': login, // Проверяем на null при сериализации
      'group_id': groupId,
      'isHeadman': isHeadman,
    };
  }
}
