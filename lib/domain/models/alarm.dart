import 'package:hive/hive.dart';
import 'identifiable.dart';

part 'alarm.g.dart';

@HiveType(typeId: 0)
class Alarm extends HiveObject implements Identifiable {
  @override
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime time;

  @HiveField(2)
  final String label;

  @HiveField(3)
  bool isActive;

  @HiveField(4)
  final String? groupId; // Optional - can be null for ungrouped alarms

  @HiveField(5)
  final String sound;

  @HiveField(6)
  final bool repeat;

  @HiveField(7)
  final List<int> repeatDays; // 0-6 for Mon-Sun

  @HiveField(8)
  final bool vibrate;

  @HiveField(9)
  final String ringtone;

  Alarm({
    required this.id,
    required this.time,
    required this.label,
    this.groupId, // Optional parameter - defaults to null
    this.isActive = true,
    this.sound = 'default',
    this.repeat = false,
    this.repeatDays = const [],
    this.vibrate = true,
    this.ringtone = 'default',
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
    bool? vibrate,
    String? ringtone,
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
      vibrate: vibrate ?? this.vibrate,
      ringtone: ringtone ?? this.ringtone,
    );
  }

  String get formattedTime => '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String get repeatDaysText {
    if (!repeat || repeatDays.isEmpty) return 'Einmalig';
    if (repeatDays.length == 7) return 'Täglich';
    if (repeatDays.length == 5 && !repeatDays.contains(5) && !repeatDays.contains(6)) {
      return 'Werktags';
    }
    
    const dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return repeatDays.map((day) => dayNames[day]).join(', ');
  }
}