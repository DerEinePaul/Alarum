import 'package:flutter/material.dart';
import '../../data/repositories/label_repository.dart';
import '../../domain/models/label.dart';

class LabelProvider extends ChangeNotifier {
  final LabelRepository repository;
  List<Label> items = [];

  LabelProvider(this.repository) {
    _load();
  }

  Future<void> _load() async {
    items = await repository.getAll();
    notifyListeners();
  }

  Future<void> add(Label label) async {
    await repository.add(label);
    items.add(label);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await repository.delete(id);
    items.removeWhere((l) => l.id == id);
    notifyListeners();
  }
}
