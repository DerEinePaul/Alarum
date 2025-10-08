/// Domain Layer: Alarm Scheduler Interface
/// 
/// Abstrakte Schnittstelle für plattformspezifisches Alarm Scheduling.
/// Implementierungen müssen garantieren, dass Alarme zuverlässig
/// ausgeführt werden, auch wenn die App geschlossen oder das Gerät
/// neu gestartet wurde.
abstract class AlarmScheduler {
  /// Schedult einen exakten Alarm zur angegebenen Zeit.
  /// 
  /// Verwendet die höchste verfügbare Priorität (AlarmClock API auf Android).
  /// Weckt das Gerät auch aus Doze Mode auf.
  /// 
  /// [alarmId]: Eindeutige ID des Alarms
  /// [scheduledTime]: Zeitpunkt zu dem der Alarm ausgelöst werden soll
  /// [title]: Titel für Notification
  /// [body]: Nachrichtentext für Notification
  /// [soundAsset]: Optionaler Pfad zu Custom Sound
  Future<bool> scheduleExactAlarm({
    required String alarmId,
    required DateTime scheduledTime,
    required String title,
    required String body,
    String? soundAsset,
  });

  /// Schedult einen Timer mit ExactAndAllowWhileIdle.
  /// 
  /// Weniger restriktiv als AlarmClock, aber immer noch zuverlässig.
  /// 
  /// [timerId]: Eindeutige ID des Timers
  /// [duration]: Dauer bis Timer abläuft
  /// [title]: Titel für Notification
  /// [body]: Nachrichtentext für Notification
  Future<bool> scheduleTimer({
    required String timerId,
    required Duration duration,
    required String title,
    required String body,
  });

  /// Cancelt einen geplanten Alarm oder Timer.
  /// 
  /// [id]: ID des zu cancelnden Alarms/Timers
  Future<bool> cancelScheduledAlarm(String id);

  /// Cancelt alle geplanten Alarme.
  Future<bool> cancelAllAlarms();

  /// Registriert alle gespeicherten Alarme neu.
  /// 
  /// Wird benötigt nach:
  /// - Geräte-Neustart (Boot Completed)
  /// - App Update
  /// - Zeitzonenänderung
  /// - System-Zeit Änderung
  Future<bool> rescheduleAllAlarms();

  /// Prüft ob die App die Berechtigung hat, exakte Alarme zu setzen.
  /// 
  /// Ab Android 12 (API 31) ist SCHEDULE_EXACT_ALARM erforderlich.
  /// Ab Android 14 (API 34) kann USE_EXACT_ALARM genutzt werden.
  Future<bool> hasExactAlarmPermission();

  /// Fordert die Berechtigung für exakte Alarme an.
  /// 
  /// Öffnet die System-Einstellungen auf Android 12+.
  Future<bool> requestExactAlarmPermission();

  /// Prüft ob Battery Optimization für die App deaktiviert ist.
  /// 
  /// Wichtig für zuverlässige Alarme im Doze Mode.
  Future<bool> isBatteryOptimizationDisabled();

  /// Fordert Benutzer auf, Battery Optimization zu deaktivieren.
  Future<bool> requestDisableBatteryOptimization();
}
