import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/repositories/alarm_repository.dart';
import '../../domain/models/alarm.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static Timer? _alarmCheckTimer;

  static Future<void> initialize() async {
    // Initialize notifications
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);

    // Start periodic alarm checking (every minute when app is running)
    _startAlarmChecking();
  }

  static void _startAlarmChecking() {
    _alarmCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkAlarms();
    });
  }

  static Future<void> _checkAlarms() async {
    final repository = HiveAlarmRepository();
    final alarms = await repository.getAllAlarms();
    final now = DateTime.now();

    for (final alarm in alarms) {
      if (alarm.isActive && _shouldTriggerAlarm(alarm, now)) {
        await _showNotification(alarm);
        // For demo purposes, disable the alarm after triggering
        final updatedAlarm = alarm.copyWith(isActive: false);
        await repository.updateAlarm(updatedAlarm);
      }
    }
  }

  static bool _shouldTriggerAlarm(Alarm alarm, DateTime now) {
    return alarm.time.hour == now.hour && alarm.time.minute == now.minute;
  }

  static Future<void> _showNotification(Alarm alarm) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'alarm_channel',
      'Alarms',
      channelDescription: 'Channel for alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      alarm.id.hashCode,
      'Alarm',
      alarm.label,
      platformChannelSpecifics,
    );
  }

  static void dispose() {
    _alarmCheckTimer?.cancel();
  }
}