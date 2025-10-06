import 'package:hive/hive.dart';

part 'alarm_group.g.dart';

@HiveType(typeId: 1)
class AlarmGroup extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  bool isActive;

  @HiveField(3)
  final List<String> alarmIds;

  AlarmGroup({
    required this.id,
    required this.name,
    this.isActive = true,
    this.alarmIds = const [],
  });

  AlarmGroup copyWith({
    String? id,
    String? name,
    bool? isActive,
    List<String>? alarmIds,
  }) {
    return AlarmGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      alarmIds: alarmIds ?? this.alarmIds,
    );
  }
}