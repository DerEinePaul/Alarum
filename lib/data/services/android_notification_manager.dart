import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../domain/services/notification_manager.dart';

/// Android Implementation des NotificationManager
/// 
/// Verwaltet Notification Channels, Full-Screen Intents, Sound und Vibration.
/// 
/// CHANNELS:
/// - alarm_channel: HIGH importance, Sound, Vibration, Full-Screen
/// - timer_channel: HIGH importance, Sound
/// - stopwatch_channel: LOW importance, Persistent
/// - foreground_service: LOW importance, Persistent
class AndroidNotificationManager implements NotificationManager {
  static const MethodChannel _channel = MethodChannel('com.alarum.alarm/notifications');
  
  final FlutterLocalNotificationsPlugin _notifications;
  
  // Channel IDs
  static const String alarmChannelId = 'alarm_channel';
  static const String timerChannelId = 'timer_channel';
  static const String stopwatchChannelId = 'stopwatch_channel';
  static const String foregroundServiceChannelId = 'foreground_service';
  
  // Singleton Pattern
  static AndroidNotificationManager? _instance;
  
  factory AndroidNotificationManager() {
    _instance ??= AndroidNotificationManager._internal(FlutterLocalNotificationsPlugin());
    return _instance!;
  }
  
  AndroidNotificationManager._internal(this._notifications);
  
  @override
  Future<void> initializeChannels() async {
    if (!Platform.isAndroid) {
      debugPrint('⚠️ AndroidNotificationManager: Nicht auf Android-Plattform');
      return;
    }
    
    debugPrint('🔔 AndroidNotificationManager: Initialisiere Channels...');
    
    try {
      // ═══════════════════════════════════════════════════════════
      // ALARM CHANNEL (Highest Priority)
      // ═══════════════════════════════════════════════════════════
      const alarmChannel = AndroidNotificationChannel(
        alarmChannelId,
        'Alarme',
        description: 'Benachrichtigungen für Wecker und Alarme',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF00FF00),
        showBadge: true,
      );
      
      // ═══════════════════════════════════════════════════════════
      // TIMER CHANNEL (High Priority)
      // ═══════════════════════════════════════════════════════════
      const timerChannel = AndroidNotificationChannel(
        timerChannelId,
        'Timer',
        description: 'Benachrichtigungen für ablaufende Timer',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      
      // ═══════════════════════════════════════════════════════════
      // STOPWATCH CHANNEL (Low Priority, Persistent)
      // ═══════════════════════════════════════════════════════════
      const stopwatchChannel = AndroidNotificationChannel(
        stopwatchChannelId,
        'Stoppuhr',
        description: 'Laufende Stoppuhr Anzeige',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );
      
      // ═══════════════════════════════════════════════════════════
      // FOREGROUND SERVICE CHANNEL (Low Priority)
      // ═══════════════════════════════════════════════════════════
      const foregroundServiceChannel = AndroidNotificationChannel(
        foregroundServiceChannelId,
        'App Dienst',
        description: 'Hintergrunddienst für Alarme und Timer',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );
      
      // Erstelle alle Channels
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(alarmChannel);
      
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(timerChannel);
      
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(stopwatchChannel);
      
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(foregroundServiceChannel);
      
      debugPrint('✅ AndroidNotificationManager: Alle Channels erstellt');
      
    } catch (e) {
      debugPrint('❌ AndroidNotificationManager: Channel Erstellung fehlgeschlagen: $e');
    }
  }
  
  @override
  Future<void> showAlarmNotification({
    required String id,
    required String title,
    required String body,
    String? soundAsset,
    List<int>? vibrationPattern,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      debugPrint('⏰ Showing Alarm Notification: $id');
      
      // Android Notification Details mit Full-Screen Intent
      final androidDetails = AndroidNotificationDetails(
        alarmChannelId,
        'Alarme',
        channelDescription: 'Benachrichtigungen für Wecker und Alarme',
        importance: Importance.max,
        
        // Full-Screen Intent (zeigt Alarm auf Lock Screen)
        fullScreenIntent: true,
        
        // Sound
        sound: soundAsset != null 
            ? RawResourceAndroidNotificationSound(soundAsset)
            : const RawResourceAndroidNotificationSound('alarm_default'),
        playSound: true,
        
        // Vibration
        enableVibration: true,
        vibrationPattern: vibrationPattern != null 
            ? Int64List.fromList(vibrationPattern)
            : Int64List.fromList([0, 1000, 500, 1000]),
        
        // LED
        enableLights: true,
        ledColor: const Color(0xFFFF0000),
        ledOnMs: 1000,
        ledOffMs: 500,
        
        // Weitere Eigenschaften
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        ongoing: true, // Kann nicht weggewischt werden
        autoCancel: false,
        
        // Actions
        actions: [
          const AndroidNotificationAction(
            'snooze',
            'Schlummern',
            icon: DrawableResourceAndroidBitmap('snooze_icon'),
            showsUserInterface: true,
          ),
          const AndroidNotificationAction(
            'dismiss',
            'Ausschalten',
            icon: DrawableResourceAndroidBitmap('dismiss_icon'),
            cancelNotification: true,
          ),
        ],
      );
      
      final notificationDetails = NotificationDetails(android: androidDetails);
      
      // Zeige Notification
      await _notifications.show(
        id.hashCode,
        title,
        body,
        notificationDetails,
      );
      
      debugPrint('✅ Alarm Notification angezeigt');
      
    } catch (e) {
      debugPrint('❌ Failed to show alarm notification: $e');
    }
  }
  
  @override
  Future<void> showTimerNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      debugPrint('⏲️ Showing Timer Notification: $id');
      
      final androidDetails = AndroidNotificationDetails(
        timerChannelId,
        'Timer',
        channelDescription: 'Benachrichtigungen für ablaufende Timer',
        importance: Importance.high,
        
        // Sound & Vibration
        sound: const RawResourceAndroidNotificationSound('timer_sound'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        
        // Weitere Eigenschaften
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        
        // Actions
        actions: [
          const AndroidNotificationAction(
            'dismiss',
            'OK',
            cancelNotification: true,
          ),
        ],
      );
      
      final notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        id.hashCode,
        title,
        body,
        notificationDetails,
      );
      
      debugPrint('✅ Timer Notification angezeigt');
      
    } catch (e) {
      debugPrint('❌ Failed to show timer notification: $e');
    }
  }
  
  @override
  Future<void> showStopwatchNotification({
    required String id,
    required Duration elapsedTime,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      final hours = elapsedTime.inHours.toString().padLeft(2, '0');
      final minutes = (elapsedTime.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (elapsedTime.inSeconds % 60).toString().padLeft(2, '0');
      final timeString = '$hours:$minutes:$seconds';
      
      final androidDetails = AndroidNotificationDetails(
        stopwatchChannelId,
        'Stoppuhr',
        channelDescription: 'Laufende Stoppuhr Anzeige',
        importance: Importance.low,
        
        // Persistent notification
        ongoing: true,
        autoCancel: false,
        
        // Keine Sounds/Vibration
        playSound: false,
        enableVibration: false,
        
        // Zeige Zeit in Notification
        showWhen: true,
        usesChronometer: true,
        
        // Actions
        actions: [
          const AndroidNotificationAction(
            'stop',
            'Stoppen',
            cancelNotification: true,
          ),
        ],
      );
      
      final notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        id.hashCode,
        'Stoppuhr läuft',
        timeString,
        notificationDetails,
      );
      
    } catch (e) {
      debugPrint('❌ Failed to show stopwatch notification: $e');
    }
  }
  
  @override
  Future<void> showForegroundServiceNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid) return;
    
    try {
      final androidDetails = AndroidNotificationDetails(
        foregroundServiceChannelId,
        'App Dienst',
        channelDescription: 'Hintergrunddienst für Alarme und Timer',
        importance: Importance.low,
        
        // Persistent service notification
        ongoing: true,
        autoCancel: false,
        
        // Keine Sounds/Vibration
        playSound: false,
        enableVibration: false,
        
        // Kategorie
        category: AndroidNotificationCategory.service,
      );
      
      final notificationDetails = NotificationDetails(android: androidDetails);
      
      await _notifications.show(
        id.hashCode,
        title,
        body,
        notificationDetails,
      );
      
    } catch (e) {
      debugPrint('❌ Failed to show foreground service notification: $e');
    }
  }
  
  @override
  Future<void> updateNotification({
    required String id,
    required String title,
    required String body,
  }) async {
    // Update wird durch erneutes show() mit gleicher ID durchgeführt
    await showStopwatchNotification(id: id, elapsedTime: Duration.zero);
  }
  
  @override
  Future<void> cancelNotification(String id) async {
    if (!Platform.isAndroid) return;
    
    try {
      await _notifications.cancel(id.hashCode);
      debugPrint('🚫 Notification cancelled: $id');
    } catch (e) {
      debugPrint('❌ Failed to cancel notification: $e');
    }
  }
  
  @override
  Future<void> cancelAllNotifications() async {
    if (!Platform.isAndroid) return;
    
    try {
      await _notifications.cancelAll();
      debugPrint('🚫 All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Failed to cancel all notifications: $e');
    }
  }
  
  @override
  Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // Android 13+ (API 33) benötigt POST_NOTIFICATIONS permission
      final result = await _channel.invokeMethod<bool>('hasNotificationPermission');
      return result ?? true; // Vor Android 13 immer true
      
    } catch (e) {
      debugPrint('❌ Failed to check notification permission: $e');
      return false;
    }
  }
  
  @override
  Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return false;
    
    try {
      debugPrint('📋 Requesting POST_NOTIFICATIONS permission...');
      
      final result = await _channel.invokeMethod<bool>('requestNotificationPermission');
      
      debugPrint('📋 Permission request result: $result');
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to request notification permission: $e');
      return false;
    }
  }
  
  @override
  Future<bool> isChannelEnabled(String channelId) async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('isChannelEnabled', {
        'channelId': channelId,
      });
      
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to check channel status: $e');
      return false;
    }
  }
}
