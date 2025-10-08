import 'package:flutter/foundation.dart';
import '../../domain/models/identifiable.dart';

abstract class CrudRepository<T extends Identifiable> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> add(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
  Future<void> toggle(String id);
}

class CrudProvider<T extends Identifiable> with ChangeNotifier {
  final CrudRepository<T> _repository;
  List<T> _items = [];

  CrudProvider(this._repository) {
    loadItems();
  }

  List<T> get items => _items;
  CrudRepository<T> get repository => _repository;

  Future<void> loadItems() async {
    _items = await _repository.getAll();
    notifyListeners();
  }

  Future<void> addItem(T item) async {
    await _repository.add(item);
    await loadItems();
  }

  Future<void> updateItem(T item) async {
    await _repository.update(item);
    await loadItems();
  }

  Future<void> deleteItem(String id) async {
    await _repository.delete(id);
    await loadItems();
  }

  Future<void> toggleItem(String id) async {
    await _repository.toggle(id);
    await loadItems();
  }
}