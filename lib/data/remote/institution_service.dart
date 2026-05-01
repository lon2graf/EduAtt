import 'package:edu_att/models/insituiton_model.dart';
import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/utils/data_result.dart';

class InstitutionService extends BaseService {
  static Future<List<InstitutionModel>> getAllInstitutions() async {
    final result = await BaseService.executeSafely<List<InstitutionModel>>(
      operation: () async {
        final response = await BaseService.client.from('institutions').select();

        return (response as List)
            .map((json) => InstitutionModel.fromJson(json))
            .toList();
      },
      errorContext: 'getAllInstitutions',
    );

    return switch (result) {
      Success(:final data) => data,
      Failure() => [],
    };
  }
}
