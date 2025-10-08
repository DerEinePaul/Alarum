import 'package:hive/hive.dart';
import '../../domain/models/label.dart';

abstract class LabelRepository {
  Future<List<Label>> getAll();
  Future<void> add(Label label);
  Future<void> delete(String id);
}

class HiveLabelRepository implements LabelRepository {
  late final Box _box;

  HiveLabelRepository() {
    _box = Hive.box('labels');
  }

  @override
  Future<void> add(Label label) async {
    await _box.put(label.id, {'id': label.id, 'name': label.name, 'color': label.color});
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  @override
  Future<List<Label>> getAll() async {
    return _box.values.map<Label>((v) {
      if (v is Map) {
        return Label(id: v['id']?.toString() ?? '', name: v['name']?.toString() ?? '', color: v['color'] ?? 0);
      }
      return Label(id: v.toString(), name: v.toString(), color: 0);
    }).toList();
  }
}
