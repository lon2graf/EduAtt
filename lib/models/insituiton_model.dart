class InstitutionModel {
  final String id;
  final String name;
  final String? address;
  final DateTime createdAt;

  InstitutionModel({
    required this.id,
    required this.name,
    this.address,
    required this.createdAt,
  });

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    return InstitutionModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
