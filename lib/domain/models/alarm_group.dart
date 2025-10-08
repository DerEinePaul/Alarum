import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
import 'identifiable.dart';

part 'alarm_group.g.dart';

@HiveType(typeId: 1)
class AlarmGroup extends HiveObject implements Identifiable {
  @override
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  bool isActive;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final int color; // For Material 3 expressive colors

  AlarmGroup({
    required this.id,
    required this.name,
    this.isActive = true,
    this.description = '',
    DateTime? createdAt,
    this.color = 0xFF6750A4, // Material 3 primary
  }) : createdAt = createdAt ?? DateTime.now();

  AlarmGroup copyWith({
    String? id,
    String? name,
    bool? isActive,
    String? description,
    DateTime? createdAt,
    int? color,
  }) {
    return AlarmGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      color: color ?? this.color,
    );
  }

  // Helper for Material 3 colors
  Color get materialColor => Color(color);
}