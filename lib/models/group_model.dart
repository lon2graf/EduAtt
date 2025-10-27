class InstitutionModel {
  final String? id; // nullable, присваивается Supabase
  final String name;
  final String? address;
  final DateTime createdAt;

  InstitutionModel({
    this.id,
    required this.name,
    this.address,
    required this.createdAt,
  });

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // отправляем только если id уже есть
      'name': name,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
