import 'package:flutter/foundation.dart';
import '../../domain/models/alarm.dart';
import '../../domain/services/alarm_scheduler.dart';
import '../../data/repositories/alarm_repository.dart';

/// Controller für Alarm Business Logic
/// 
/// RESPONSIBILITIES:
/// - Orchestriert Alarm CRUD mit Scheduling
/// - Verbindet Repository mit Platform Services
/// - Verwaltet Alarm Lifecycle
/// - Reschedule nach Boot
class AlarmController extends ChangeNotifier {
  final AlarmRepository _repository;
  final AlarmScheduler _scheduler;
  
  List<Alarm> _alarms = [];
  bool _isLoading = false;
  String? _error;
  
  AlarmController(
    this._repository,
    this._scheduler,
  );
  
  // ═══════════════════════════════════════════════════════════
  // STATE
  // ═══════════════════════════════════════════════════════════
  
  List<Alarm> get alarms => _alarms;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Aktive Alarme
  List<Alarm> get activeAlarms => _alarms.where((a) => a.isActive).toList();
  
  /// Anzahl aktiver Alarme
  int get activeAlarmCount => activeAlarms.length;
  
  // ═══════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════
  
  /// Initialisiere Controller
  Future<void> initialize() async {
    debugPrint('🚀 Initializing AlarmController...');
    
    _setLoading(true);
    
    try {
      // Lade alle Alarme
      await loadAlarms();
      
      // Reschedule alle aktiven Alarme (z.B. nach App-Neustart)
      await rescheduleAllAlarms();
      
      debugPrint('✅ AlarmController initialized with ${_alarms.length} alarms');
      
    } catch (e) {
      _setError('Failed to initialize: $e');
      debugPrint('❌ Failed to initialize AlarmController: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // LOAD
  // ═══════════════════════════════════════════════════════════
  
  /// Lade alle Alarme
  Future<void> loadAlarms() async {
    try {
      debugPrint('📥 Loading alarms...');
      
      _alarms = await _repository.getAll();
      _error = null;
      notifyListeners();
      
      debugPrint('✅ Loaded ${_alarms.length} alarms');
      
    } catch (e) {
      _setError('Failed to load alarms: $e');
      debugPrint('❌ Failed to load alarms: $e');
    }
  }
  
  /// Lade einzelnen Alarm
  Future<Alarm?> getAlarm(String id) async {
    try {
      return await _repository.getById(id);
    } catch (e) {
      debugPrint('❌ Failed to get alarm $id: $e');
      return null;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // CREATE
  // ═══════════════════════════════════════════════════════════
  
  /// Erstelle neuen Alarm
  Future<Alarm?> createAlarm({
    required String label,
    required DateTime time,
    required String groupId,
    bool isActive = true,
    bool repeat = false,
    List<int> repeatDays = const [],
    bool vibrate = true,
    String sound = 'default',
  }) async {
    _setLoading(true);
    
    try {
      debugPrint('📝 Creating alarm: $label at ${time.hour}:${time.minute}');
      
      // Erstelle Alarm Model
      final alarm = Alarm(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: label,
        time: time,
        groupId: groupId,
        isActive: isActive,
        repeat: repeat,
        repeatDays: repeatDays,
        vibrate: vibrate,
        sound: sound,
      );
      
      // Speichere in Repository
      await _repository.add(alarm);
      
      // Schedule Alarm wenn aktiv
      if (isActive) {
        await _scheduleAlarm(alarm);
      }
      
      // Reload Liste
      await loadAlarms();
      
      debugPrint('✅ Alarm created and scheduled');
      return alarm;
      
    } catch (e) {
      _setError('Failed to create alarm: $e');
      debugPrint('❌ Failed to create alarm: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // UPDATE
  // ═══════════════════════════════════════════════════════════
  
  /// Update Alarm
  Future<bool> updateAlarm(Alarm alarm) async {
    _setLoading(true);
    
    try {
      debugPrint('📝 Updating alarm: ${alarm.id}');
      
      // Update Repository
      await _repository.update(alarm);
      
      // Reschedule
      if (alarm.isActive) {
        await _scheduleAlarm(alarm);
      } else {
        await _cancelAlarm(alarm);
      }
      
      // Reload Liste
      await loadAlarms();
      
      debugPrint('✅ Alarm updated');
      return true;
      
    } catch (e) {
      _setError('Failed to update alarm: $e');
      debugPrint('❌ Failed to update alarm: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Toggle Alarm Active State
  Future<bool> toggleAlarm(String id) async {
    try {
      debugPrint('🔄 Toggling alarm: $id');
      
      final alarm = await _repository.getById(id);
      if (alarm == null) {
        debugPrint('❌ Alarm not found: $id');
        return false;
      }
      
      final updated = alarm.copyWith(isActive: !alarm.isActive);
      
      return await updateAlarm(updated);
      
    } catch (e) {
      _setError('Failed to toggle alarm: $e');
      debugPrint('❌ Failed to toggle alarm: $e');
      return false;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // DELETE
  // ═══════════════════════════════════════════════════════════
  
  /// Lösche Alarm
  Future<bool> deleteAlarm(String id) async {
    _setLoading(true);
    
    try {
      debugPrint('🗑️ Deleting alarm: $id');
      
      final alarm = await _repository.getById(id);
      if (alarm == null) {
        debugPrint('❌ Alarm not found: $id');
        return false;
      }
      
      // Cancel Scheduled Alarm
      await _cancelAlarm(alarm);
      
      // Delete from Repository
      await _repository.delete(id);
      
      // Reload Liste
      await loadAlarms();
      
      debugPrint('✅ Alarm deleted');
      return true;
      
    } catch (e) {
      _setError('Failed to delete alarm: $e');
      debugPrint('❌ Failed to delete alarm: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // SCHEDULING
  // ═══════════════════════════════════════════════════════════
  
  /// Schedule einzelnen Alarm
  Future<void> _scheduleAlarm(Alarm alarm) async {
    try {
      debugPrint('⏰ Scheduling alarm: ${alarm.id}');
      
      await _scheduler.scheduleExactAlarm(
        alarmId: alarm.id,
        scheduledTime: alarm.time,
        title: alarm.label,
        body: alarm.formattedTime,
        soundAsset: alarm.sound != 'default' ? alarm.sound : null,
      );
      
      debugPrint('✅ Alarm scheduled for ${alarm.formattedTime}');
      
    } catch (e) {
      debugPrint('❌ Failed to schedule alarm: $e');
      rethrow;
    }
  }
  
  /// Cancel einzelnen Alarm
  Future<void> _cancelAlarm(Alarm alarm) async {
    try {
      debugPrint('❌ Cancelling alarm: ${alarm.id}');
      
      await _scheduler.cancelScheduledAlarm(alarm.id);
      
      debugPrint('✅ Alarm cancelled');
      
    } catch (e) {
      debugPrint('❌ Failed to cancel alarm: $e');
    }
  }
  
  /// Reschedule alle aktiven Alarme (nach Boot)
  Future<void> rescheduleAllAlarms() async {
    try {
      debugPrint('🔄 Rescheduling all active alarms...');
      
      final activeAlarms = _alarms.where((a) => a.isActive).toList();
      
      for (final alarm in activeAlarms) {
        await _scheduleAlarm(alarm);
      }
      
      debugPrint('✅ Rescheduled ${activeAlarms.length} alarms');
      
    } catch (e) {
      debugPrint('❌ Failed to reschedule alarms: $e');
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // SNOOZE
  // ═══════════════════════════════════════════════════════════
  
  /// Snooze Alarm (5 Minuten)
  Future<bool> snoozeAlarm(String id, {int snoozeMinutes = 5}) async {
    try {
      debugPrint('😴 Snoozing alarm: $id for $snoozeMinutes minutes');
      
      final alarm = await _repository.getById(id);
      if (alarm == null) return false;
      
      // Berechne neue Snooze Zeit
      final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
      
      // Update Alarm mit neuer Zeit
      final snoozedAlarm = alarm.copyWith(time: snoozeTime);
      
      await updateAlarm(snoozedAlarm);
      
      debugPrint('✅ Alarm snoozed until ${snoozeTime.hour}:${snoozeTime.minute}');
      return true;
      
    } catch (e) {
      debugPrint('❌ Failed to snooze alarm: $e');
      return false;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // HELPER
  // ═══════════════════════════════════════════════════════════
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  @override
  void dispose() {
    debugPrint('🗑️ AlarmController disposed');
    super.dispose();
  }
}
