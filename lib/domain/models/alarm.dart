import 'package:hive/hive.dart';

part 'alarm.g.dart';

@HiveType(typeId: 0)
class Alarm extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime time;

  @HiveField(2)
  final String label;

  @HiveField(3)
  bool isActive;

  @HiveField(4)
  final String? groupId;

  @HiveField(5)
  final String sound;

  @HiveField(6)
  final bool repeat;

  @HiveField(7)
  final List<int> repeatDays; // 0-6 for Mon-Sun

  Alarm({
    required this.id,
    required this.time,
    required this.label,
    this.isActive = true,
    this.groupId,
    this.sound = 'default',
    this.repeat = false,
    this.repeatDays = const [],
  });

  Alarm copyWith({
    String? id,
    DateTime? time,
    String? label,
    bool? isActive,
    String? groupId,
    String? sound,
    bool? repeat,
    List<int>? repeatDays,
  }) {
    return Alarm(
      id: id ?? this.id,
      time: time ?? this.time,
      label: label ?? this.label,
      isActive: isActive ?? this.isActive,
      groupId: groupId ?? this.groupId,
      sound: sound ?? this.sound,
      repeat: repeat ?? this.repeat,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }
}