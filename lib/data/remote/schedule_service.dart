import 'package:edu_att/data/remote/base_service.dart';
import 'package:edu_att/models/schedule_model.dart';
import 'package:edu_att/utils/data_result.dart';

class ScheduleService extends BaseService {
  static const _select = '''
    id,
    start_time,
    end_time,
    date,
    weekday,
    subjects!inner(name),
    teachers!inner(name, surname),
    groups!inner(name),
    lessons(topic)
  ''';

  static Future<DataResult<List<ScheduleModel>>> getScheduleByGroup(
    String groupId,
  ) =>
      BaseService.executeSafely<List<ScheduleModel>>(
        operation: () async {
          final response = await BaseService.client
              .from('schedule')
              .select(_select)
              .eq('group_id', groupId)
              .order('date')
              .order('start_time');

          return (response as List)
              .map((json) => ScheduleModel.fromJson(json))
              .toList();
        },
        errorContext: 'getScheduleByGroup',
      );

  static Future<DataResult<List<ScheduleModel>>> getScheduleByTeacher(
    String teacherId,
  ) =>
      BaseService.executeSafely<List<ScheduleModel>>(
        operation: () async {
          final response = await BaseService.client
              .from('schedule')
              .select(_select)
              .eq('teacher_id', teacherId)
              .order('date')
              .order('start_time');

          return (response as List)
              .map((json) => ScheduleModel.fromJson(json))
              .toList();
        },
        errorContext: 'getScheduleByTeacher',
      );
}
