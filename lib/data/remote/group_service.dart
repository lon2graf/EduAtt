// lib/services/group_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:edu_att/models/group_model.dart';

class GroupService {
  static Future<List<GroupModel>> getGroupsByInstitution(
    String institutionId,
  ) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('groups')
        .select('id, name')
        .eq('institution_id', institutionId)
        .order('name', ascending: true);

    return (response as List).map((json) => GroupModel.fromJson(json)).toList();
  }
}
