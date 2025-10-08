import 'package:flutter/foundation.dart';
import '../platform/platform_manager.dart';
import '../../domain/models/alarm.dart';
import 'alarm_service.dart';

/// Platform-aware Alarm Adapter
/// Wählt automatisch die beste Alarm-Implementierung basierend auf der Plattform
class PlatformAlarmAdapter {
  static PlatformAlarmAdapter? _instance;
  static PlatformAlarmAdapter get instance => _instance ??= PlatformAlarmAdapter._();

  final PlatformManager _platformManager = PlatformManager.instance;

  PlatformAlarmAdapter._() {
    debugPrint('🔧 PlatformAlarmAdapter initialisiert');
    debugPrint('   Strategie: ${_getStrategyName()}');
  }

  String _getStrategyName() {
    final strategy = _platformManager.getAlarmStrategy();
    switch (strategy) {
      case AlarmStrategy.androidAlarmManager:
        return 'Android Alarm Manager (System-Level)';
      case AlarmStrategy.localNotifications:
        return 'Local Notifications (iOS/Mobile)';
      case AlarmStrategy.periodicCheck:
        return 'Periodic Check (Desktop/Web)';
      case AlarmStrategy.workManager:
        return 'WorkManager (Legacy)';
    }
  }

  /// Schedule alarm basierend auf Plattform
  Future<void> scheduleAlarm(Alarm alarm) async {
    final strategy = _platformManager.getAlarmStrategy();
    
    debugPrint('📅 Scheduling alarm ${alarm.id} with strategy: ${strategy.name}');

    switch (strategy) {
      case AlarmStrategy.androidAlarmManager:
        await _scheduleAndroidSystemAlarm(alarm);
        break;
      
      case AlarmStrategy.localNotifications:
        await _scheduleLocalNotificationAlarm(alarm);
        break;
      
      case AlarmStrategy.periodicCheck:
        await _schedulePeriodicCheckAlarm(alarm);
        break;
      
      case AlarmStrategy.workManager:
        await _scheduleWorkManagerAlarm(alarm);
        break;
    }
  }

  /// Cancel alarm basierend auf Plattform
  Future<void> cancelAlarm(String alarmId) async {
    final strategy = _platformManager.getAlarmStrategy();
    
    debugPrint('🚫 Canceling alarm $alarmId with strategy: ${strategy.name}');

    switch (strategy) {
      case AlarmStrategy.androidAlarmManager:
        await _cancelAndroidSystemAlarm(alarmId);
        break;
      
      case AlarmStrategy.localNotifications:
        await _cancelLocalNotificationAlarm(alarmId);
        break;
      
      case AlarmStrategy.periodicCheck:
        await _cancelPeriodicCheckAlarm(alarmId);
        break;
      
      case AlarmStrategy.workManager:
        await _cancelWorkManagerAlarm(alarmId);
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Android System Alarm Manager (android_alarm_manager_plus)
  // ═══════════════════════════════════════════════════════════════
  
  Future<void> _scheduleAndroidSystemAlarm(Alarm alarm) async {
    // TODO: Implementiere android_alarm_manager_plus
    // final alarmTime = alarm.time;
    // final now = DateTime.now();
    // 
    // await AndroidAlarmManager.oneShotAt(
    //   alarmTime,
    //   alarm.id.hashCode,
    //   _androidAlarmCallback,
    //   exact: true,
    //   wakeup: true,
    //   rescheduleOnReboot: true,
    //   params: {
    //     'alarmId': alarm.id,
    //     'label': alarm.label,
    //     'sound': alarm.sound,
    //     'vibrate': alarm.vibrate,
    //   },
    // );
    
    debugPrint('🤖 Android System Alarm scheduled (TODO: implement android_alarm_manager_plus)');
    
    // Fallback auf AlarmService
    await AlarmService.scheduleAlarm(alarm);
  }

  Future<void> _cancelAndroidSystemAlarm(String alarmId) async {
    // TODO: Implementiere android_alarm_manager_plus
    // await AndroidAlarmManager.cancel(alarmId.hashCode);
    
    debugPrint('🤖 Android System Alarm cancelled');
    
    // Fallback auf AlarmService
    await AlarmService.cancelAlarm(alarmId);
  }

  // Android Alarm Callback (wird vom System aufgerufen)
  @pragma('vm:entry-point')
  static Future<void> _androidAlarmCallback(int id, Map<String, dynamic> params) async {
    final alarmId = params['alarmId'] as String;
    final label = params['label'] as String;
    final sound = params['sound'] as String;
    final vibrate = params['vibrate'] as bool;
    
    debugPrint('⏰ Android System Alarm triggered: $alarmId');
    
    await AlarmService.showCriticalNotification(alarmId, label, sound);
    if (vibrate) {
      await AlarmService.playAlarmSound();
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // iOS / Mobile Local Notifications
  // ═══════════════════════════════════════════════════════════════
  
  Future<void> _scheduleLocalNotificationAlarm(Alarm alarm) async {
    debugPrint('🍎 iOS Local Notification scheduled');
    await AlarmService.scheduleAlarm(alarm);
  }

  Future<void> _cancelLocalNotificationAlarm(String alarmId) async {
    debugPrint('🍎 iOS Local Notification cancelled');
    await AlarmService.cancelAlarm(alarmId);
  }

  // ═══════════════════════════════════════════════════════════════
  // Desktop / Web Periodic Check
  // ═══════════════════════════════════════════════════════════════
  
  Future<void> _schedulePeriodicCheckAlarm(Alarm alarm) async {
    debugPrint('💻 Periodic Check Alarm registered');
    // AlarmService läuft bereits mit periodic Timer
    await AlarmService.scheduleAlarm(alarm);
  }

  Future<void> _cancelPeriodicCheckAlarm(String alarmId) async {
    debugPrint('💻 Periodic Check Alarm cancelled');
    await AlarmService.cancelAlarm(alarmId);
  }

  // ═══════════════════════════════════════════════════════════════
  // WorkManager (Legacy Fallback)
  // ═══════════════════════════════════════════════════════════════
  
  Future<void> _scheduleWorkManagerAlarm(Alarm alarm) async {
    debugPrint('🔧 WorkManager Alarm scheduled (legacy)');
    // TODO: Implementiere workmanager fallback wenn benötigt
    await AlarmService.scheduleAlarm(alarm);
  }

  Future<void> _cancelWorkManagerAlarm(String alarmId) async {
    debugPrint('🔧 WorkManager Alarm cancelled');
    await AlarmService.cancelAlarm(alarmId);
  }

  // ═══════════════════════════════════════════════════════════════
  // Platform-specific Notification Settings
  // ═══════════════════════════════════════════════════════════════
  
  /// Get notification channel ID basierend auf Plattform
  String getNotificationChannelId() {
    return _platformManager.getNotificationChannelId();
  }

  /// Get vibration pattern basierend auf Plattform
  List<int>? getVibrationPattern() {
    return _platformManager.getVibrationPattern();
  }

  /// Get alarm sound path basierend auf Plattform
  String getAlarmSoundPath(String soundName) {
    return _platformManager.getAlarmSoundPath(soundName);
  }

  /// Check if platform supports full-screen intents
  bool get supportsFullScreenIntent => _platformManager.supportsFullScreenIntent;

  /// Check if platform supports exact alarms
  bool get supportsExactAlarms => _platformManager.supportsExactAlarms;

  /// Check if platform supports background tasks
  bool get supportsBackgroundTasks => _platformManager.supportsBackgroundTasks;
}
