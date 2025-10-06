import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/alarm.dart';

abstract class AlarmRepository {
  Future<List<Alarm>> getAllAlarms();
  Future<Alarm?> getAlarmById(String id);
  Future<void> addAlarm(Alarm alarm);
  Future<void> updateAlarm(Alarm alarm);
  Future<void> deleteAlarm(String id);
  Future<void> toggleAlarm(String id);
}

class HiveAlarmRepository implements AlarmRepository {
  static const String boxName = 'alarms';

  @override
  Future<List<Alarm>> getAllAlarms() async {
    final box = await Hive.openBox<Alarm>(boxName);
    return box.values.toList();
  }

  @override
  Future<Alarm?> getAlarmById(String id) async {
    final box = await Hive.openBox<Alarm>(boxName);
    return box.get(id);
  }

  @override
  Future<void> addAlarm(Alarm alarm) async {
    final box = await Hive.openBox<Alarm>(boxName);
    await box.put(alarm.id, alarm);
  }

  @override
  Future<void> updateAlarm(Alarm alarm) async {
    final box = await Hive.openBox<Alarm>(boxName);
    await box.put(alarm.id, alarm);
  }

  @override
  Future<void> deleteAlarm(String id) async {
    final box = await Hive.openBox<Alarm>(boxName);
    await box.delete(id);
  }

  @override
  Future<void> toggleAlarm(String id) async {
    final box = await Hive.openBox<Alarm>(boxName);
    final alarm = box.get(id);
    if (alarm != null) {
      final updatedAlarm = alarm.copyWith(isActive: !alarm.isActive);
      await box.put(id, updatedAlarm);
    }
  }
}