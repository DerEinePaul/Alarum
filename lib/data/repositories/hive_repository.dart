import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/identifiable.dart';

abstract class HiveRepository<T extends Identifiable> {
  String get boxName;

  Future<Box<T>> _getBox() async => await Hive.openBox<T>(boxName);

  Future<List<T>> getAll() async {
    final box = await _getBox();
    return box.values.toList();
  }

  Future<T?> getById(String id) async {
    final box = await _getBox();
    return box.get(id);
  }

  Future<void> add(T item) async {
    final box = await _getBox();
    await box.put(item.id, item);
  }

  Future<void> update(T item) async {
    final box = await _getBox();
    await box.put(item.id, item);
  }

  Future<void> delete(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}