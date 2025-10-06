import 'package:flutter/foundation.dart';
import '../../data/repositories/alarm_repository.dart';
import '../../domain/models/alarm.dart';

class AlarmProvider with ChangeNotifier {
  final AlarmRepository _repository;
  List<Alarm> _alarms = [];

  AlarmProvider(this._repository) {
    loadAlarms();
  }

  List<Alarm> get alarms => _alarms;

  Future<void> loadAlarms() async {
    _alarms = await _repository.getAllAlarms();
    notifyListeners();
  }

  Future<void> addAlarm(Alarm alarm) async {
    await _repository.addAlarm(alarm);
    await loadAlarms();
  }

  Future<void> updateAlarm(Alarm alarm) async {
    await _repository.updateAlarm(alarm);
    await loadAlarms();
  }

  Future<void> deleteAlarm(String id) async {
    await _repository.deleteAlarm(id);
    await loadAlarms();
  }

  Future<void> toggleAlarm(String id) async {
    await _repository.toggleAlarm(id);
    await loadAlarms();
  }
}