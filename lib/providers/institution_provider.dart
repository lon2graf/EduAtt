import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edu_att/models/insituiton_model.dart';
import 'package:edu_att/services/institution_service.dart';

/// Провайдер, который загружает список всех образовательных организаций
final institutionsProvider = FutureProvider<List<InstitutionModel>>((
  ref,
) async {
  return InstitutionService.getAllInstitutions();
});
