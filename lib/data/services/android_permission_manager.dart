import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/services/permission_manager.dart';

/// Android Implementation des PermissionManager
/// 
/// Verwaltet Runtime Permissions mit Material 3 UI Dialogen.
/// 
/// PERMISSIONS:
/// - SCHEDULE_EXACT_ALARM (Android 12+)
/// - USE_EXACT_ALARM (Android 14+)
/// - POST_NOTIFICATIONS (Android 13+)
/// - Battery Optimization Exclusion
class AndroidPermissionManager implements PermissionManager {
  static const MethodChannel _channel = MethodChannel('com.alarum.alarm/permissions');
  
  // Singleton Pattern
  static AndroidPermissionManager? _instance;
  
  factory AndroidPermissionManager() {
    _instance ??= AndroidPermissionManager._internal();
    return _instance!;
  }
  
  AndroidPermissionManager._internal();
  
  @override
  Future<Map<String, bool>> checkAllAlarmPermissions() async {
    if (!Platform.isAndroid) {
      return {};
    }
    
    try {
      debugPrint('📋 Checking all alarm permissions...');
      
      final permissions = <String, bool>{};
      
      // Exact Alarm Permission (Android 12+)
      final exactAlarm = await checkPermission(AndroidPermissions.scheduleExactAlarm);
      permissions[AndroidPermissions.scheduleExactAlarm] = exactAlarm;
      
      // Notification Permission (Android 13+)
      final notification = await checkPermission(AndroidPermissions.postNotifications);
      permissions[AndroidPermissions.postNotifications] = notification;
      
      // Battery Optimization
      final batteryOpt = await checkPermission(AndroidPermissions.ignoreBatteryOptimizations);
      permissions[AndroidPermissions.ignoreBatteryOptimizations] = batteryOpt;
      
      debugPrint('📋 Permission Status: $permissions');
      return permissions;
      
    } catch (e) {
      debugPrint('❌ Failed to check permissions: $e');
      return {};
    }
  }
  
  @override
  Future<bool> requestAllAlarmPermissions() async {
    if (!Platform.isAndroid) return false;
    
    try {
      debugPrint('📋 Requesting all alarm permissions...');
      
      // 1. Check Exact Alarm Permission
      bool exactAlarmGranted = await checkPermission(AndroidPermissions.scheduleExactAlarm);
      
      if (!exactAlarmGranted) {
        exactAlarmGranted = await requestPermission(
          AndroidPermissions.scheduleExactAlarm,
          'Für zuverlässige Alarme benötigt',
        );
      }
      
      // 2. Check Notification Permission
      bool notificationGranted = await checkPermission(AndroidPermissions.postNotifications);
      
      if (!notificationGranted) {
        notificationGranted = await requestPermission(
          AndroidPermissions.postNotifications,
          'Um Alarme anzuzeigen',
        );
      }
      
      // 3. Check Battery Optimization
      bool batteryOptGranted = await checkPermission(AndroidPermissions.ignoreBatteryOptimizations);
      
      if (!batteryOptGranted) {
        batteryOptGranted = await requestPermission(
          AndroidPermissions.ignoreBatteryOptimizations,
          'Für Alarme im Energiesparmodus',
        );
      }
      
      final allGranted = exactAlarmGranted && notificationGranted && batteryOptGranted;
      debugPrint('📋 All permissions granted: $allGranted');
      
      return allGranted;
      
    } catch (e) {
      debugPrint('❌ Failed to request all permissions: $e');
      return false;
    }
  }
  
  @override
  Future<bool> checkPermission(String permission) async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('checkPermission', {
        'permission': permission,
      });
      
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to check permission $permission: $e');
      return false;
    }
  }
  
  @override
  Future<bool> requestPermission(String permission, String rationale) async {
    if (!Platform.isAndroid) return false;
    
    try {
      debugPrint('📋 Requesting permission: $permission');
      
      // Zeige Permission Rationale Dialog erst
      final shouldRequest = await showPermissionRationale(
        permission: permission,
        title: _getPermissionTitle(permission),
        description: rationale,
      );
      
      if (!shouldRequest) {
        return false;
      }
      
      // Request Permission über native Android
      final result = await _channel.invokeMethod<bool>('requestPermission', {
        'permission': permission,
      });
      
      debugPrint('📋 Permission $permission result: $result');
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to request permission $permission: $e');
      return false;
    }
  }
  
  @override
  Future<void> openAppSettings() async {
    if (!Platform.isAndroid) return;
    
    try {
      debugPrint('⚙️ Opening app settings...');
      
      await _channel.invokeMethod('openAppSettings');
      
    } catch (e) {
      debugPrint('❌ Failed to open app settings: $e');
    }
  }
  
  @override
  Future<bool> isPermissionPermanentlyDenied(String permission) async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await _channel.invokeMethod<bool>('isPermissionPermanentlyDenied', {
        'permission': permission,
      });
      
      return result ?? false;
      
    } catch (e) {
      debugPrint('❌ Failed to check if permission permanently denied: $e');
      return false;
    }
  }
  
  @override
  Future<bool> showPermissionRationale({
    required String permission,
    required String title,
    required String description,
  }) async {
    // Diese Methode wird vom Presentation Layer aufgerufen
    // und zeigt die Material 3 Permission Dialoge
    
    // Für Battery Optimization zeigen wir speziellen Dialog
    if (permission == AndroidPermissions.ignoreBatteryOptimizations) {
      return await _showBatteryOptimizationDialog();
    }
    
    // Für andere Permissions zeigen wir Standard Permission Dialog
    return await _showPermissionRequestDialog(
      title: title,
      description: description,
      permission: permission,
    );
  }
  
  /// Zeigt Battery Optimization Dialog
  Future<bool> _showBatteryOptimizationDialog() async {
    // Muss vom Widget Context aufgerufen werden
    // Wird von AlarmPermissionController verwendet
    return false; // Placeholder - wird vom Controller überschrieben
  }
  
  /// Zeigt Permission Request Dialog
  Future<bool> _showPermissionRequestDialog({
    required String title,
    required String description,
    required String permission,
  }) async {
    // Muss vom Widget Context aufgerufen werden
    // Wird von AlarmPermissionController verwendet
    return false; // Placeholder - wird vom Controller überschrieben
  }
  
  /// Hilfsmethode: Hole Permission Titel
  String _getPermissionTitle(String permission) {
    switch (permission) {
      case AndroidPermissions.scheduleExactAlarm:
        return 'Exakte Alarme';
      case AndroidPermissions.postNotifications:
        return 'Benachrichtigungen';
      case AndroidPermissions.ignoreBatteryOptimizations:
        return 'Akku-Optimierung';
      case AndroidPermissions.wakeLock:
        return 'Bildschirm aktivieren';
      case AndroidPermissions.receiveBootCompleted:
        return 'Neustart-Wiederherstellung';
      default:
        return 'Berechtigung';
    }
  }
}
