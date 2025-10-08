import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/services/alarm_scheduler.dart';

/// Android Implementation des AlarmScheduler
/// 
/// Verwendet flutter_local_notifications Plugin um Android's AlarmManager
/// und NotificationManager APIs zu nutzen.
/// 
/// FEATURES:
/// - AlarmManager.setAlarmClock() für höchste Priorität
/// - ExactAndAllowWhileIdle für Timer
/// - Full-Screen Intent für Lock Screen
/// - Boot Persistence
/// - Doze Mode Wakeup
class AndroidAlarmScheduler implements AlarmScheduler {
  static const MethodChannel _channel = MethodChannel('com.alarum.alarm/scheduler');
  
  // Singleton Pattern
  static AndroidAlarmScheduler? _instance;
  
  factory AndroidAlarmScheduler() {
    _instance ??= AndroidAlarmScheduler._internal();
    return _instance!;
  }
  
  AndroidAlarmScheduler._internal();
  
  /// Initialisiert den Alarm Scheduler
  Future<void> initialize() async {
    if (!Platform.isAndroid) {
      debugPrint('⚠️ AndroidAlarmScheduler: Nicht auf Android-Plattform');
      return;
    }
    
    debugPrint('🔧 AndroidAlarmScheduler: Initialisiere...');
    
    try {
      // Prüfe ob AlarmManager verfügbar ist
      final hasPermission = await hasExactAlarmPermission();
      debugPrint('📋 Exact Alarm Permission: $hasPermission');
      
      // Prüfe Battery Optimization
      final batteryOptimized = await isBatteryOptimizationDisabled();
      debugPrint('🔋 Battery Optimization Disabled: $batteryOptimized');
      
      debugPrint('✅ AndroidAlarmScheduler: Initialisierung abgeschlossen');
    } catch (e) {
      debugPrint('❌ AndroidAlarmScheduler: Initialisierung fehlgeschlagen: $e');
    }
  }
  
  @override
  Future<bool> scheduleExactAlarm({
    required String alarmId,
    required DateTime scheduledTime,
    required String title,
    required String body,
    String? soundAsset,
  }) async {
    if (!Platform.isAndroid) return false;
    
    try {
      debugPrint('⏰ Scheduling Exact Alarm: $alarmId at $scheduledTime');
      
      // Prüfe Permission
      if (!await hasExactAlarmPermission()) {
        debugPrint('⚠️ Missing SCHEDULE_EXACT_ALARM permission');
        return false;
      }
      
      // Berechne Delay in Millisekunden
      final now = DateTime.now();
      final delay = scheduledTime.difference(now).inMilliseconds;
      
      if (delay < 0) {
        debugPrint('⚠️ Scheduled time is in the past');
        return false;
      }
      
      // Rufe native Android Code auf
      final result = await _channel.invokeMethod<bool>('scheduleExactAlarm', {
        'alarmId': alarmId,
        'triggerAtMillis': scheduledTime.millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'soundAsset': soundAsset,
        'useAlarmClock': true, // Höchste Priorität
      });
      
      debugPrint('✅ Alarm scheduled: $alarmId, result: $result');
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to schedule alarm: $e');
      return false;
    }
  }
  
  @override
  Future<bool> scheduleTimer({
    required String timerId,
    required Duration duration,
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid) return false;
    
    try {
      debugPrint('⏲️ Scheduling Timer: $timerId, duration: ${duration.inMinutes}min');
      
      // Prüfe Permission
      if (!await hasExactAlarmPermission()) {
        debugPrint('⚠️ Missing SCHEDULE_EXACT_ALARM permission');
        return false;
      }
      
      final triggerTime = DateTime.now().add(duration);
      
      // Rufe native Android Code auf
      final result = await _channel.invokeMethod<bool>('scheduleExactAlarm', {
        'alarmId': timerId,
        'triggerAtMillis': triggerTime.millisecondsSinceEpoch,
        'title': title,
        'body': body,
        'useAlarmClock': false, // ExactAndAllowWhileIdle statt AlarmClock
      });
      
      debugPrint('✅ Timer scheduled: $timerId, result: $result');
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to schedule timer: $e');
      return false;
    }
  }
  
  @override
  Future<bool> cancelScheduledAlarm(String id) async {
    if (!Platform.isAndroid) return false;
    
    try {
      debugPrint('🚫 Canceling alarm: $id');
      
      final result = await _channel.invokeMethod<bool>('cancelAlarm', {
        'alarmId': id,
      });
      
      debugPrint('✅ Alarm cancelled: $id, result: $result');
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to cancel alarm: $e');
      return false;
    }
  }
  
  @override
  Future<bool> cancelAllAlarms() async {
    if (!Platform.isAndroid) return false;
    
    try {
      debugPrint('🚫 Canceling all alarms');
      
      final result = await _channel.invokeMethod<bool>('cancelAllAlarms');
      
      debugPrint('✅ All alarms cancelled, result: $result');
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to cancel all alarms: $e');
      return false;
    }
  }
  
  @override
  Future<bool> rescheduleAllAlarms() async {
    if (!Platform.isAndroid) return false;
    
    try {
      debugPrint('🔄 Rescheduling all alarms...');
      
      // Wird nach Boot oder App-Update aufgerufen
      // Alarme werden aus Hive geladen und neu geplant
      final result = await _channel.invokeMethod<bool>('rescheduleAllAlarms');
      
      debugPrint('✅ All alarms rescheduled, result: $result');
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to reschedule alarms: $e');
      return false;
    }
  }
  
  @override
  Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // Android 12 (API 31) und höher benötigt SCHEDULE_EXACT_ALARM
      final sdkInt = await _getAndroidSdkInt();
      
      if (sdkInt < 31) {
        // Vor Android 12 keine Permission erforderlich
        return true;
      }
      
      final result = await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to check exact alarm permission: $e');
      return false;
    }
  }
  
  @override
  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return false;
    
    try {
      debugPrint('📋 Requesting SCHEDULE_EXACT_ALARM permission...');
      
      final sdkInt = await _getAndroidSdkInt();
      
      if (sdkInt < 31) {
        // Vor Android 12 keine Permission erforderlich
        return true;
      }
      
      // Öffne System-Einstellungen für Exact Alarm Permission
      final result = await _channel.invokeMethod<bool>('requestExactAlarmPermission');
      
      debugPrint('📋 Permission request result: $result');
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to request exact alarm permission: $e');
      return false;
    }
  }
  
  @override
  Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to check battery optimization: $e');
      return false;
    }
  }
  
  @override
  Future<bool> requestDisableBatteryOptimization() async {
    if (!Platform.isAndroid) return false;
    
    try {
      debugPrint('🔋 Requesting to disable battery optimization...');
      
      // Öffne System-Einstellungen für Battery Optimization
      final result = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      
      debugPrint('🔋 Request result: $result');
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to request battery optimization: $e');
      return false;
    }
  }
  
  /// Hilfsmethode: Hole Android SDK Version
  Future<int> _getAndroidSdkInt() async {
    try {
      final sdkInt = await _channel.invokeMethod<int>('getSdkInt');
      return sdkInt ?? 0;
    } catch (e) {
      debugPrint('❌ Failed to get SDK int: $e');
      return 0;
    }
  }
}
