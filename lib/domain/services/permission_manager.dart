/// Domain Layer: Permission Manager Interface
/// 
/// Abstrakte Schnittstelle für Permission Management.
/// Zentralisiert alle Permission-Anfragen und Status-Checks.
abstract class PermissionManager {
  /// Prüft alle erforderlichen Permissions für Alarm-Funktionalität.
  /// 
  /// Returns: Map mit Permission Name als Key und Status als Value.
  Future<Map<String, bool>> checkAllAlarmPermissions();

  /// Fordert alle erforderlichen Permissions für Alarme an.
  /// 
  /// Zeigt UI-Dialoge mit Erklärungen warum Permissions benötigt werden.
  /// 
  /// Returns: true wenn alle Permissions erteilt wurden.
  Future<bool> requestAllAlarmPermissions();

  /// Prüft spezifische Permission.
  /// 
  /// [permission]: Name der Permission (z.B. 'SCHEDULE_EXACT_ALARM')
  Future<bool> checkPermission(String permission);

  /// Fordert spezifische Permission an.
  /// 
  /// [permission]: Name der Permission
  /// [rationale]: Erklärung warum die Permission benötigt wird
  Future<bool> requestPermission(String permission, String rationale);

  /// Öffnet App-Einstellungen für manuelle Permission Verwaltung.
  Future<void> openAppSettings();

  /// Prüft ob Permission dauerhaft abgelehnt wurde.
  /// 
  /// Returns: true wenn Benutzer "Don't ask again" gewählt hat.
  Future<bool> isPermissionPermanentlyDenied(String permission);

  /// Zeigt Rationale Dialog warum Permission benötigt wird.
  /// 
  /// [permission]: Permission Name
  /// [title]: Dialog Titel
  /// [description]: Erklärung
  Future<bool> showPermissionRationale({
    required String permission,
    required String title,
    required String description,
  });
}

/// Vordefinierte Permission Namen für Android
class AndroidPermissions {
  static const String scheduleExactAlarm = 'SCHEDULE_EXACT_ALARM';
  static const String useExactAlarm = 'USE_EXACT_ALARM';
  static const String wakeLock = 'WAKE_LOCK';
  static const String receiveBootCompleted = 'RECEIVE_BOOT_COMPLETED';
  static const String postNotifications = 'POST_NOTIFICATIONS';
  static const String ignoreBatteryOptimizations = 'REQUEST_IGNORE_BATTERY_OPTIMIZATIONS';
  static const String foregroundService = 'FOREGROUND_SERVICE';
  static const String foregroundServiceMediaPlayback = 'FOREGROUND_SERVICE_MEDIA_PLAYBACK';
  static const String systemAlertWindow = 'SYSTEM_ALERT_WINDOW';
  static const String vibrate = 'VIBRATE';
}
