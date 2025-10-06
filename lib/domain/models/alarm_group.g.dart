// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmGroupAdapter extends TypeAdapter<AlarmGroup> {
  @override
  final int typeId = 1;

  @override
  AlarmGroup read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmGroup(
      id: fields[0] as String,
      name: fields[1] as String,
      isActive: fields[2] as bool,
      alarmIds: (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, AlarmGroup obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isActive)
      ..writeByte(3)
      ..write(obj.alarmIds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
