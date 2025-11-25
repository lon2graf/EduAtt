import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:edu_att/models/insituiton_model.dart';

class InstitutionService {
  static Future<List<InstitutionModel>> getAllInstitutions() async {
    final supClient = Supabase.instance.client;
    try {
      final response = await supClient.from('institutions').select();

      return (response as List)
          .map((json) => InstitutionModel.fromJson(json))
          .toList();
    } catch (e) {
      print("Ошибка при загрузке образовательных организаций: $e");
      return [];
    }
  }
}
