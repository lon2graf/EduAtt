import 'package:edu_att/models/group_model.dart';
import 'package:edu_att/data/remote/base_service.dart';

class GroupService extends BaseService {
  static Future<List<GroupModel>> getGroupsByInstitution(
    String institutionId,
  ) async {
    final result = await BaseService.executeSafely<List<GroupModel>>(
      operation: () async {
        final response = await BaseService.client
            .from('groups')
            .select('id, name')
            .eq('institution_id', institutionId)
            .order('name', ascending: true);

        return (response as List)
            .map((json) => GroupModel.fromJson(json))
            .toList();
      },
      errorContext: 'getGroupsByInstitution',
    );

    return result ?? [];
  }
}
