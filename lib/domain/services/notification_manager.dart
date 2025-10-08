/// Domain Layer: Notification Manager Interface
/// 
/// Abstrakte Schnittstelle für plattformspezifische Notification Features.
/// Zuständig für Notification Channels, Full-Screen Intents, Sound, Vibration.
abstract class NotificationManager {
  /// Initialisiert alle Notification Channels.
  /// 
  /// Muss beim App-Start aufgerufen werden.
  /// Erstellt separate Channels für:
  /// - Alarme (HIGH importance, Sound, Vibration)
  /// - Timer (HIGH importance)
  /// - Stopwatch (LOW importance, persistent)
  /// - Foreground Service (LOW importance)
  Future<void> initializeChannels();

  /// Zeigt eine High-Priority Alarm Notification an.
  /// 
  /// Mit Full-Screen Intent um auch bei gesperrtem Screen anzuzeigen.
  /// 
  /// [id]: Notification ID
  /// [title]: Titel
  /// [body]: Nachricht
  /// [soundAsset]: Optional custom sound
  /// [vibrationPattern]: Optional vibration pattern in ms
  Future<void> showAlarmNotification({
    required String id,
    required String title,
    required String body,
    String? soundAsset,
    List<int>? vibrationPattern,
  });

  /// Zeigt eine Timer-abgelaufen Notification an.
  /// 
  /// [id]: Notification ID
  /// [title]: Titel
  /// [body]: Nachricht
  Future<void> showTimerNotification({
    required String id,
    required String title,
    required String body,
  });

  /// Zeigt eine persistente Stopwatch Notification an.
  /// 
  /// Zeigt laufende Zeit im Notification Drawer.
  /// 
  /// [id]: Notification ID
  /// [elapsedTime]: Verstrichene Zeit
  Future<void> showStopwatchNotification({
    required String id,
    required Duration elapsedTime,
  });

  /// Zeigt eine Foreground Service Notification an.
  /// 
  /// Erforderlich für Foreground Services (Android 8+).
  /// 
  /// [id]: Service ID
  /// [title]: Service Titel
  /// [body]: Service Beschreibung
  Future<void> showForegroundServiceNotification({
    required String id,
    required String title,
    required String body,
  });

  /// Aktualisiert eine existierende Notification.
  /// 
  /// [id]: Notification ID
  /// [title]: Neuer Titel
  /// [body]: Neue Nachricht
  Future<void> updateNotification({
    required String id,
    required String title,
    required String body,
  });

  /// Entfernt eine Notification.
  /// 
  /// [id]: Notification ID
  Future<void> cancelNotification(String id);

  /// Entfernt alle Notifications.
  Future<void> cancelAllNotifications();

  /// Prüft ob Notification Permission erteilt wurde.
  /// 
  /// Ab Android 13 (API 33) erforderlich.
  Future<bool> hasNotificationPermission();

  /// Fordert Notification Permission an.
  Future<bool> requestNotificationPermission();

  /// Prüft ob ein spezifischer Notification Channel aktiviert ist.
  /// 
  /// [channelId]: ID des Channels
  Future<bool> isChannelEnabled(String channelId);
}
