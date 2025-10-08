import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../data/repositories/alarm_repository.dart';
import '../../domain/models/alarm.dart';

// Conditional import for isolate functionality (mobile only)
import 'dart:isolate' if (dart.library.html) '../../web_stubs/isolate_stub.dart';

/// Enhanced Alarm Service für echte Betriebssystem-Level Alarme
/// TODO: Erweitere um android_alarm_manager_plus für Background-Execution
class AlarmService {
  static const String _portName = 'alarm_service_port';
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static Timer? _alarmCheckTimer;
  static ReceivePort? _port;

  /// Initialisiert den Alarm Service mit erweiterten Benachrichtigungen
  static Future<void> initialize() async {
    // Initialize notifications mit erweiterten Einstellungen
    await _initializeNotifications();
    
    // TODO: Initialize Android Alarm Manager für Background-Execution
    // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    //   await AndroidAlarmManager.initialize();
    // }
    
    // Setup IsolateNameServer für Background-Communication
    _setupBackgroundCommunication();
    
    // Start periodic alarm checking (every minute when app is running)
    _startAlarmChecking();
    
    debugPrint('✅ AlarmService initialisiert mit erweiterten Benachrichtigungen');
  }

  /// Konfiguriert erweiterte Benachrichtigungen mit Sound und Vibration
  static Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@drawable/alarm_icon');
    
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );
    
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
    
    // Request permissions für kritische Alarme
    await _requestCriticalPermissions();
  }

  /// Fordert kritische Permissions für Alarm-Benachrichtigungen an
  static Future<void> _requestCriticalPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      
      await _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestExactAlarmsPermission();
    }
  }

  /// Background Communication Setup (nur für Mobile Plattformen)
  static void _setupBackgroundCommunication() {
    // Isolates werden nur auf Mobile Plattformen unterstützt
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      _port = ReceivePort();
      IsolateNameServer.registerPortWithName(_port!.sendPort, _portName);
      
      _port!.listen((dynamic data) {
        if (data is String && data.startsWith('alarm_triggered:')) {
          final alarmId = data.split(':')[1];
          _handleBackgroundAlarmTrigger(alarmId);
        }
      });
    }
  }

  /// Schedules einen Background-Alarm für ein spezifisches Datum/Zeit
  /// TODO: Erweitere um AndroidAlarmManager für echte Background-Execution
  static Future<void> scheduleAlarm(Alarm alarm) async {
    debugPrint('⏰ Scheduling alarm: ${alarm.id} for ${alarm.time}');
    
    // TODO: Implementiere echte Background-Alarme mit AndroidAlarmManager
    // final alarmTime = alarm.time;
    // final now = DateTime.now();
    // final timeToAlarm = alarmTime.millisecondsSinceEpoch - now.millisecondsSinceEpoch;
    // 
    // if (timeToAlarm > 0 && !kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    //   await AndroidAlarmManager.oneShotAt(
    //     alarmTime,
    //     alarm.id.hashCode,
    //     _backgroundAlarmCallback,
    //     params: {
    //       'alarmId': alarm.id,
    //       'label': alarm.label,
    //       'sound': alarm.sound,
    //     },
    //     exact: true,
    //     wakeup: true,
    //     rescheduleOnReboot: true,
    //   );
    // }
    
    // Fallback: Schedule lokale Benachrichtigung für sofortige Demonstration
    await _scheduleLocalNotification(alarm);
  }

  /// Schedule lokale Benachrichtigung (Fallback für Web/Demo)
  static Future<void> _scheduleLocalNotification(Alarm alarm) async {
    final now = DateTime.now();
    final scheduledDate = alarm.time;
    
    if (scheduledDate.isAfter(now)) {
      // Für Web: Vereinfachte Benachrichtigung ohne timezone
      if (kIsWeb) {
        await _notificationsPlugin.show(
          alarm.id.hashCode,
          '⏰ Alarm: ${alarm.label}',
          'Alarm für ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')} Uhr',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'alarm_channel',
              'Alarme',
              channelDescription: 'Alarm Benachrichtigungen',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
            ),
          ),
          payload: alarm.id,
        );
      } else {
        // Für Mobile: Scheduled notification mit timezone
        await _notificationsPlugin.zonedSchedule(
          alarm.id.hashCode,
          '⏰ Alarm: ${alarm.label}',
          'Es ist Zeit aufzustehen!',
          tz.TZDateTime.from(scheduledDate, tz.getLocation('Europe/Berlin')),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'alarm_channel',
              'Alarme',
              channelDescription: 'Alarm Benachrichtigungen',
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: alarm.id,
        );
      }
      
      debugPrint('📅 Lokale Benachrichtigung gescheduled für: $scheduledDate');
    }
  }

  /// Cancelt einen geschedulten Alarm
  static Future<void> cancelAlarm(String alarmId) async {
    // TODO: Cancel AndroidAlarmManager alarm
    // if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    //   await AndroidAlarmManager.cancel(alarmId.hashCode);
    // }
    
    // Cancel lokale Benachrichtigung
    await _notificationsPlugin.cancel(alarmId.hashCode);
    
    debugPrint('❌ Alarm cancelled: $alarmId');
  }

  /// Zeigt eine kritische Benachrichtigung mit Full-Screen Intent (PUBLIC für Timer)
  static Future<void> showCriticalNotification(String alarmId, String label, String sound) async {
    await _showCriticalNotification(alarmId, label, sound);
  }

  /// Spielt Alarm-Sound ab (PUBLIC für Timer)
  static Future<void> playAlarmSound() async {
    await _playAlarmSound();
  }

  /// Zeigt eine kritische Benachrichtigung mit Full-Screen Intent (PRIVATE)
  static Future<void> _showCriticalNotification(String alarmId, String label, String sound) async {
    final vibrationPattern = Int64List.fromList([0, 1000, 500, 1000, 500, 1000]);
    
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'critical_alarm_channel',
      'Critical Alarms',
      channelDescription: 'High priority alarms that require immediate attention',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      enableVibration: true,
      playSound: true,
      vibrationPattern: vibrationPattern,
      actions: const [
        AndroidNotificationAction('dismiss', 'Ausschalten', cancelNotification: true),
        AndroidNotificationAction('snooze', 'Schlummern (5 Min)'),
      ],
    );
    
    final NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    
    await _notificationsPlugin.show(
      alarmId.hashCode,
      '⏰ ALARM!',
      label.isNotEmpty ? label : 'Es ist Zeit aufzustehen!',
      platformDetails,
      payload: alarmId,
    );
  }

  /// Handle Background Alarm Trigger
  static Future<void> _handleBackgroundAlarmTrigger(String alarmId) async {
    debugPrint('🎵 Handling background alarm trigger: $alarmId');
    
    // Spiele Alarm-Sound ab
    await _playAlarmSound();
  }

  /// Spielt Alarm-Sound ab (TODO: Implementiere mit just_audio)
  static Future<void> _playAlarmSound() async {
    try {
      // TODO: Implementiere echten Alarm-Sound mit just_audio
      // if (_audioPlayer != null) {
      //   await _audioPlayer!.setAsset('assets/sounds/alarm_sound.mp3');
      //   await _audioPlayer!.setVolume(1.0);
      //   await _audioPlayer!.play();
      // }
      
      debugPrint('🎵 Alarm-Sound would play here (TODO: implement with just_audio)');
    } catch (e) {
      debugPrint('⚠️ Fehler beim Abspielen des Alarm-Sounds: $e');
    }
  }

  /// Handle Notification Response (Action Buttons)
  static void _onNotificationResponse(NotificationResponse response) {
    final alarmId = response.payload;
    final actionId = response.actionId;
    
    debugPrint('🔔 Notification response: $actionId für Alarm: $alarmId');
    
    switch (actionId) {
      case 'dismiss':
        _dismissAlarm(alarmId);
        break;
      case 'snooze':
        _snoozeAlarm(alarmId);
        break;
    }
  }

  /// Schaltet Alarm aus
  static Future<void> _dismissAlarm(String? alarmId) async {
    if (alarmId != null) {
      await _notificationsPlugin.cancel(alarmId.hashCode);
      debugPrint('✅ Alarm dismissed: $alarmId');
    }
  }

  /// Setzt Alarm auf Snooze (5 Minuten)
  static Future<void> _snoozeAlarm(String? alarmId) async {
    if (alarmId != null) {
      await _notificationsPlugin.cancel(alarmId.hashCode);
      
      // TODO: Schedule Snooze-Alarm in 5 Minuten mit AndroidAlarmManager
      debugPrint('😴 Alarm snoozed: $alarmId für 5 Minuten (TODO: implement)');
    }
  }

  /// Periodic checking für App-running Alarme (Web-Fallback)
  static void _startAlarmChecking() {
    _alarmCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      // Für Web und andere Plattformen ohne Background-Support
      await _checkAlarms();
    });
  }

  /// Check Alarme (Web-Fallback)
  static Future<void> _checkAlarms() async {
    final repository = HiveAlarmRepository();
    final alarms = await repository.getAll();
    final now = DateTime.now();

    for (final alarm in alarms) {
      if (alarm.isActive && _shouldTriggerAlarm(alarm, now)) {
        await _showCriticalNotification(alarm.id, alarm.label, alarm.sound);
        
        // Für Demo: Alarm nach Trigger deaktivieren
        final updatedAlarm = alarm.copyWith(isActive: false);
        await repository.update(updatedAlarm);
      }
    }
  }

  /// Check ob Alarm ausgelöst werden soll
  static bool _shouldTriggerAlarm(Alarm alarm, DateTime now) {
    return alarm.time.hour == now.hour && alarm.time.minute == now.minute;
  }

  /// Räumt Ressourcen auf
  static void dispose() {
    _alarmCheckTimer?.cancel();
    
    // Isolate cleanup nur für Mobile Plattformen
    if (!kIsWeb && _port != null) {
      _port?.close();
      IsolateNameServer.removePortNameMapping(_portName);
    }
  }
}