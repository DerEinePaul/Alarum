import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/alarm_group.dart';

abstract class AlarmGroupRepository {
  Future<List<AlarmGroup>> getAllGroups();
  Future<AlarmGroup?> getGroupById(String id);
  Future<void> addGroup(AlarmGroup group);
  Future<void> updateGroup(AlarmGroup group);
  Future<void> deleteGroup(String id);
  Future<void> toggleGroup(String id);
}

class HiveAlarmGroupRepository implements AlarmGroupRepository {
  static const String boxName = 'alarm_groups';

  @override
  Future<List<AlarmGroup>> getAllGroups() async {
    final box = await Hive.openBox<AlarmGroup>(boxName);
    return box.values.toList();
  }

  @override
  Future<AlarmGroup?> getGroupById(String id) async {
    final box = await Hive.openBox<AlarmGroup>(boxName);
    return box.get(id);
  }

  @override
  Future<void> addGroup(AlarmGroup group) async {
    final box = await Hive.openBox<AlarmGroup>(boxName);
    await box.put(group.id, group);
  }

  @override
  Future<void> updateGroup(AlarmGroup group) async {
    final box = await Hive.openBox<AlarmGroup>(boxName);
    await box.put(group.id, group);
  }

  @override
  Future<void> deleteGroup(String id) async {
    final box = await Hive.openBox<AlarmGroup>(boxName);
    await box.delete(id);
  }

  @override
  Future<void> toggleGroup(String id) async {
    final box = await Hive.openBox<AlarmGroup>(boxName);
    final group = box.get(id);
    if (group != null) {
      final updatedGroup = group.copyWith(isActive: !group.isActive);
      await box.put(id, updatedGroup);
    }
  }
}