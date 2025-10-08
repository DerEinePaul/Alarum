import 'hive_repository.dart';
import '../../domain/models/alarm.dart';
import '../../presentation/providers/crud_provider.dart';

abstract class AlarmRepository implements CrudRepository<Alarm> {
  @override
  Future<List<Alarm>> getAll();

  @override
  Future<Alarm?> getById(String id);

  @override
  Future<void> add(Alarm item);

  @override
  Future<void> update(Alarm item);

  @override
  Future<void> delete(String id);

  @override
  Future<void> toggle(String id);
}

class HiveAlarmRepository extends HiveRepository<Alarm> implements AlarmRepository {
  @override
  String get boxName => 'alarms';

  @override
  Future<void> toggle(String id) async {
    final alarm = await getById(id);
    if (alarm != null) {
      final updatedAlarm = alarm.copyWith(isActive: !alarm.isActive);
      await update(updatedAlarm);
    }
  }
}