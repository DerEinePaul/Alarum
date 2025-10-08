import 'hive_repository.dart';
import '../../domain/models/alarm_group.dart';
import '../../presentation/providers/crud_provider.dart';

abstract class AlarmGroupRepository implements CrudRepository<AlarmGroup> {
  @override
  Future<List<AlarmGroup>> getAll();

  @override
  Future<AlarmGroup?> getById(String id);

  @override
  Future<void> add(AlarmGroup item);

  @override
  Future<void> update(AlarmGroup item);

  @override
  Future<void> delete(String id);

  @override
  Future<void> toggle(String id);
}

class HiveAlarmGroupRepository extends HiveRepository<AlarmGroup> implements AlarmGroupRepository {
  @override
  String get boxName => 'alarm_groups';

  @override
  Future<void> toggle(String id) async {
    final group = await getById(id);
    if (group != null) {
      final updatedGroup = group.copyWith(isActive: !group.isActive);
      await update(updatedGroup);
    }
  }
}