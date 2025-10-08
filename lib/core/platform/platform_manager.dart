import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Zentrales Platform Management System
/// Erkennt die Plattform beim Start und passt Features dynamisch an
class PlatformManager {
  static PlatformManager? _instance;
  static PlatformManager get instance => _instance ??= PlatformManager._();

  PlatformManager._() {
    _detectPlatform();
  }

  // Platform Detection
  late final PlatformType _platformType;
  late final bool _isDesktop;
  late final bool _isMobile;
  late final bool _supportsBackgroundTasks;
  late final bool _supportsExactAlarms;
  late final bool _supportsFullScreenIntent;
  late final bool _supportsSystemAlarmManager;

  /// Platform Types
  PlatformType get platformType => _platformType;
  bool get isWeb => _platformType == PlatformType.web;
  bool get isAndroid => _platformType == PlatformType.android;
  bool get isIOS => _platformType == PlatformType.iOS;
  bool get isWindows => _platformType == PlatformType.windows;
  bool get isMacOS => _platformType == PlatformType.macOS;
  bool get isLinux => _platformType == PlatformType.linux;

  /// Platform Categories
  bool get isDesktop => _isDesktop;
  bool get isMobile => _isMobile;

  /// Feature Support
  bool get supportsBackgroundTasks => _supportsBackgroundTasks;
  bool get supportsExactAlarms => _supportsExactAlarms;
  bool get supportsFullScreenIntent => _supportsFullScreenIntent;
  bool get supportsSystemAlarmManager => _supportsSystemAlarmManager;

  /// Detect current platform und set capabilities
  void _detectPlatform() {
    if (kIsWeb) {
      _platformType = PlatformType.web;
      _isDesktop = false;
      _isMobile = false;
      _supportsBackgroundTasks = false;
      _supportsExactAlarms = false;
      _supportsFullScreenIntent = false;
      _supportsSystemAlarmManager = false;
    } else if (Platform.isAndroid) {
      _platformType = PlatformType.android;
      _isDesktop = false;
      _isMobile = true;
      _supportsBackgroundTasks = true; // Workmanager / AndroidAlarmManager
      _supportsExactAlarms = true; // SCHEDULE_EXACT_ALARM permission
      _supportsFullScreenIntent = true; // Full-screen alarm UI
      _supportsSystemAlarmManager = true; // android_alarm_manager_plus
    } else if (Platform.isIOS) {
      _platformType = PlatformType.iOS;
      _isDesktop = false;
      _isMobile = true;
      _supportsBackgroundTasks = true; // Background fetch
      _supportsExactAlarms = false; // iOS doesn't support exact alarms
      _supportsFullScreenIntent = false; // iOS uses notifications
      _supportsSystemAlarmManager = false; // iOS uses different approach
    } else if (Platform.isWindows) {
      _platformType = PlatformType.windows;
      _isDesktop = true;
      _isMobile = false;
      _supportsBackgroundTasks = true; // Windows Task Scheduler
      _supportsExactAlarms = true;
      _supportsFullScreenIntent = false;
      _supportsSystemAlarmManager = false;
    } else if (Platform.isMacOS) {
      _platformType = PlatformType.macOS;
      _isDesktop = true;
      _isMobile = false;
      _supportsBackgroundTasks = true; // LaunchAgents
      _supportsExactAlarms = true;
      _supportsFullScreenIntent = false;
      _supportsSystemAlarmManager = false;
    } else if (Platform.isLinux) {
      _platformType = PlatformType.linux;
      _isDesktop = true;
      _isMobile = false;
      _supportsBackgroundTasks = true; // Cron / systemd
      _supportsExactAlarms = true;
      _supportsFullScreenIntent = false;
      _supportsSystemAlarmManager = false;
    } else {
      _platformType = PlatformType.unknown;
      _isDesktop = false;
      _isMobile = false;
      _supportsBackgroundTasks = false;
      _supportsExactAlarms = false;
      _supportsFullScreenIntent = false;
      _supportsSystemAlarmManager = false;
    }

    _logPlatformInfo();
  }

  /// Log platform information at startup
  void _logPlatformInfo() {
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('🚀 Platform Manager Initialized');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('Platform: ${_platformType.displayName}');
    debugPrint('Category: ${_isMobile ? "Mobile" : _isDesktop ? "Desktop" : "Web"}');
    debugPrint('───────────────────────────────────────────────');
    debugPrint('Features:');
    debugPrint('  ✓ Background Tasks: ${_supportsBackgroundTasks ? "YES" : "NO"}');
    debugPrint('  ✓ Exact Alarms: ${_supportsExactAlarms ? "YES" : "NO"}');
    debugPrint('  ✓ Full-Screen Intent: ${_supportsFullScreenIntent ? "YES" : "NO"}');
    debugPrint('  ✓ System Alarm Manager: ${_supportsSystemAlarmManager ? "YES" : "NO"}');
    debugPrint('═══════════════════════════════════════════════');
  }

  /// Get recommended alarm strategy for current platform
  AlarmStrategy getAlarmStrategy() {
    if (isAndroid) {
      return AlarmStrategy.androidAlarmManager; // android_alarm_manager_plus
    } else if (isIOS) {
      return AlarmStrategy.localNotifications; // flutter_local_notifications
    } else if (isDesktop) {
      return AlarmStrategy.periodicCheck; // In-app periodic checking
    } else {
      return AlarmStrategy.periodicCheck; // Web fallback
    }
  }

  /// Get recommended notification channel
  String getNotificationChannelId() {
    if (supportsFullScreenIntent) {
      return 'critical_alarm_channel'; // Android full-screen alarms
    } else if (isMobile) {
      return 'alarm_channel'; // Standard mobile notifications
    } else {
      return 'desktop_alarm_channel'; // Desktop notifications
    }
  }

  /// Get notification importance based on platform
  NotificationImportance getNotificationImportance() {
    if (supportsFullScreenIntent) {
      return NotificationImportance.critical; // Android critical
    } else if (isMobile) {
      return NotificationImportance.high; // iOS/Mobile high
    } else {
      return NotificationImportance.normal; // Desktop/Web normal
    }
  }

  /// Check if platform supports Material 3 Expressive animations
  bool get supportsMaterial3Expressive => !isWeb; // Web has limited animation support

  /// Get vibration pattern based on platform
  List<int>? getVibrationPattern() {
    if (isAndroid) {
      return [0, 1000, 500, 1000, 500, 1000]; // Strong Android vibration
    } else if (isIOS) {
      return null; // iOS uses haptic feedback API instead
    } else {
      return null; // Desktop/Web no vibration
    }
  }

  /// Get alarm sound asset path based on platform
  String getAlarmSoundPath(String soundName) {
    // Normalisiere Sound-Namen plattformübergreifend
    final cleanName = soundName.toLowerCase().replaceAll(' ', '_');
    
    if (isAndroid) {
      return 'assets/sounds/android/$cleanName.mp3';
    } else if (isIOS) {
      return 'assets/sounds/ios/$cleanName.m4a';
    } else {
      return 'assets/sounds/default/$cleanName.mp3';
    }
  }
}

/// Platform Types
enum PlatformType {
  android,
  iOS,
  web,
  windows,
  macOS,
  linux,
  unknown;

  String get displayName {
    switch (this) {
      case PlatformType.android:
        return 'Android';
      case PlatformType.iOS:
        return 'iOS';
      case PlatformType.web:
        return 'Web';
      case PlatformType.windows:
        return 'Windows';
      case PlatformType.macOS:
        return 'macOS';
      case PlatformType.linux:
        return 'Linux';
      case PlatformType.unknown:
        return 'Unknown';
    }
  }
}

/// Alarm Strategies based on platform
enum AlarmStrategy {
  androidAlarmManager, // Android: android_alarm_manager_plus für echte System-Alarme
  localNotifications, // iOS/Mobile: flutter_local_notifications mit timezone
  periodicCheck, // Desktop/Web: In-app periodic checking
  workManager, // Legacy: workmanager (fallback)
}

/// Notification Importance Levels
enum NotificationImportance {
  critical, // Android full-screen intent
  high, // iOS/Mobile high priority
  normal, // Desktop/Web standard
}
