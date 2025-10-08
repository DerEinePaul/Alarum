import 'crud_provider.dart';
import '../../domain/models/alarm.dart';

class AlarmProvider extends CrudProvider<Alarm> {
  AlarmProvider(super.repository);
}