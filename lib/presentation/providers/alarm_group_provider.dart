import 'package:flutter/foundation.dart';
import '../../data/repositories/alarm_group_repository.dart';
import '../../domain/models/alarm_group.dart';

class AlarmGroupProvider with ChangeNotifier {
  final AlarmGroupRepository _repository;
  List<AlarmGroup> _groups = [];

  AlarmGroupProvider(this._repository) {
    loadGroups();
  }

  List<AlarmGroup> get groups => _groups;

  Future<void> loadGroups() async {
    _groups = await _repository.getAllGroups();
    notifyListeners();
  }

  Future<void> addGroup(AlarmGroup group) async {
    await _repository.addGroup(group);
    await loadGroups();
  }

  Future<void> updateGroup(AlarmGroup group) async {
    await _repository.updateGroup(group);
    await loadGroups();
  }

  Future<void> deleteGroup(String id) async {
    await _repository.deleteGroup(id);
    await loadGroups();
  }

  Future<void> toggleGroup(String id) async {
    await _repository.toggleGroup(id);
    await loadGroups();
  }
}