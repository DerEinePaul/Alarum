import 'package:flutter/foundation.dart';
import '../../domain/models/alarm.dart';
import '../../domain/models/alarm_group.dart';
import '../../data/repositories/alarm_repository.dart';
import '../../data/repositories/alarm_group_repository.dart';
import 'alarm_service.dart';

class AlarmGroupService with ChangeNotifier {
  final AlarmRepository _alarmRepository;
  final AlarmGroupRepository _groupRepository;

  AlarmGroupService(this._alarmRepository, this._groupRepository);

  /// Implements cascading logic: when group is deactivated, all alarms in group are deactivated
  Future<void> toggleGroup(String groupId) async {
    final group = await _groupRepository.getById(groupId);
    if (group == null) return;

    final newActiveState = !group.isActive;
    
    // Update group state
    await _groupRepository.update(group.copyWith(isActive: newActiveState));
    
    // Cascading logic: update all alarms in this group
    final allAlarms = await _alarmRepository.getAll();
    final groupAlarms = allAlarms.where((alarm) => alarm.groupId == groupId).toList();
    
    for (final alarm in groupAlarms) {
      final updatedAlarm = alarm.copyWith(isActive: newActiveState);
      await _alarmRepository.update(updatedAlarm);
      
      // ✅ CRITICAL: Schedule/Cancel echte Background-Alarme
      if (newActiveState) {
        await AlarmService.scheduleAlarm(updatedAlarm);
      } else {
        await AlarmService.cancelAlarm(updatedAlarm.id);
      }
    }
    
    debugPrint('🔄 Group ${group.name} toggled to ${newActiveState ? "active" : "inactive"} - ${groupAlarms.length} alarms affected');
    notifyListeners();
  }

  /// Gets all alarms for a specific group
  Future<List<Alarm>> getAlarmsForGroup(String groupId) async {
    final allAlarms = await _alarmRepository.getAll();
    return allAlarms.where((alarm) => alarm.groupId == groupId).toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  /// Creates a new alarm with mandatory group assignment and Background-Scheduling
  Future<void> createAlarm({
    required String groupId,
    required DateTime time,
    required String label,
    bool repeat = false,
    List<int> repeatDays = const [],
    String sound = 'default',
    bool vibrate = true,
    String ringtone = 'default',
  }) async {
    // Verify group exists
    final group = await _groupRepository.getById(groupId);
    if (group == null) {
      throw ArgumentError('Group with ID $groupId does not exist');
    }

    final alarm = Alarm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      time: time,
      label: label,
      groupId: groupId,
      repeat: repeat,
      repeatDays: repeatDays,
      sound: sound,
      isActive: group.isActive, // Inherit group's active state
    );

    await _alarmRepository.add(alarm);
    
    // ✅ CRITICAL: Schedule echten Background-Alarm wenn Alarm aktiv ist
    if (alarm.isActive) {
      await AlarmService.scheduleAlarm(alarm);
    }
    
    debugPrint('⏰ New alarm created and scheduled: ${alarm.id} at ${time.toString()}');
    notifyListeners();
  }

  /// Updates an alarm and reschedules background alarm
  Future<void> updateAlarm(Alarm alarm) async {
    await _alarmRepository.update(alarm);
    
    // ✅ CRITICAL: Reschedule Background-Alarm
    await AlarmService.cancelAlarm(alarm.id);
    if (alarm.isActive) {
      await AlarmService.scheduleAlarm(alarm);
    }
    
    debugPrint('🔄 Alarm updated and rescheduled: ${alarm.id}');
    notifyListeners();
  }

  /// Deletes an alarm and cancels background alarm
  Future<void> deleteAlarm(String alarmId) async {
    await _alarmRepository.delete(alarmId);
    
    // ✅ CRITICAL: Cancel Background-Alarm
    await AlarmService.cancelAlarm(alarmId);
    
    debugPrint('❌ Alarm deleted and cancelled: $alarmId');
    notifyListeners();
  }

  /// Creates a default group for new users
  Future<void> createDefaultGroups() async {
    final existingGroups = await _groupRepository.getAll();
    if (existingGroups.isEmpty) {
      await _groupRepository.add(AlarmGroup(
        id: 'default_group',
        name: 'Meine Wecker',
        description: 'Standardgruppe für Wecker',
      ));
    }
  }

  /// Validates that alarms can only be created with existing groups
  Future<bool> isValidGroupId(String groupId) async {
    final group = await _groupRepository.getById(groupId);
    return group != null;
  }
}