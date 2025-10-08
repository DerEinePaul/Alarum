import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/services/permission_manager.dart';
import '../widgets/dialogs/permission_request_dialog.dart';
import '../widgets/dialogs/battery_optimization_dialog.dart';

/// Controller für Alarm Permission Management
/// 
/// Orchestriert Permission Requests mit Material 3 UI Dialogen.
/// 
/// RESPONSIBILITIES:
/// - Permission Status überwachen
/// - Material 3 Dialoge anzeigen (mit Animationen)
/// - Permission Request Lifecycle
/// - Permanently Denied Handling
class AlarmPermissionController extends ChangeNotifier {
  final PermissionManager _permissionManager;
  
  // Permission Status Cache
  Map<String, bool> _permissionStatus = {};
  bool _isCheckingPermissions = false;
  
  AlarmPermissionController(this._permissionManager);
  
  /// Alle benötigten Permissions
  Map<String, bool> get permissionStatus => _permissionStatus;
  
  /// Sind alle Permissions gewährt?
  bool get allPermissionsGranted {
    if (_permissionStatus.isEmpty) return false;
    return _permissionStatus.values.every((granted) => granted);
  }
  
  /// Wird Permission Check gerade durchgeführt?
  bool get isCheckingPermissions => _isCheckingPermissions;
  
  // ═══════════════════════════════════════════════════════════
  // PERMISSION CHECK
  // ═══════════════════════════════════════════════════════════
  
  /// Prüfe alle Alarm Permissions
  Future<void> checkAllPermissions() async {
    if (_isCheckingPermissions) return;
    
    _isCheckingPermissions = true;
    notifyListeners();
    
    try {
      debugPrint('🔍 Checking all alarm permissions...');
      
      _permissionStatus = await _permissionManager.checkAllAlarmPermissions();
      
      debugPrint('📋 Permission Status: $_permissionStatus');
      
    } catch (e) {
      debugPrint('❌ Failed to check permissions: $e');
    } finally {
      _isCheckingPermissions = false;
      notifyListeners();
    }
  }
  
  /// Prüfe einzelne Permission
  Future<bool> checkPermission(String permission) async {
    try {
      final granted = await _permissionManager.checkPermission(permission);
      
      _permissionStatus[permission] = granted;
      notifyListeners();
      
      return granted;
      
    } catch (e) {
      debugPrint('❌ Failed to check permission $permission: $e');
      return false;
    }
  }
  
  // ═══════════════════════════════════════════════════════════
  // PERMISSION REQUEST WITH UI
  // ═══════════════════════════════════════════════════════════
  
  /// Request alle Permissions mit UI
  Future<bool> requestAllPermissionsWithUI(BuildContext context) async {
    debugPrint('📋 Requesting all permissions with UI...');
    
    // 1. Exact Alarm Permission
    bool exactAlarmGranted = _permissionStatus[AndroidPermissions.scheduleExactAlarm] ?? false;
    
    if (!exactAlarmGranted) {
      exactAlarmGranted = await requestPermissionWithDialog(
        context,
        permission: AndroidPermissions.scheduleExactAlarm,
        title: 'Exakte Alarme',
        description: 'Für zuverlässige Alarme zur genauen Uhrzeit',
        icon: Icons.alarm,
        iconColor: Theme.of(context).colorScheme.primary,
      );
    }
    
    if (!exactAlarmGranted) {
      debugPrint('❌ Exact Alarm permission denied');
      return false;
    }
    
    // 2. Notification Permission
    bool notificationGranted = _permissionStatus[AndroidPermissions.postNotifications] ?? false;
    
    if (!notificationGranted) {
      notificationGranted = await requestPermissionWithDialog(
        context,
        permission: AndroidPermissions.postNotifications,
        title: 'Benachrichtigungen',
        description: 'Um Alarm-Benachrichtigungen anzuzeigen',
        icon: Icons.notifications_active,
        iconColor: Theme.of(context).colorScheme.secondary,
      );
    }
    
    if (!notificationGranted) {
      debugPrint('❌ Notification permission denied');
      return false;
    }
    
    // 3. Battery Optimization
    bool batteryOptGranted = _permissionStatus[AndroidPermissions.ignoreBatteryOptimizations] ?? false;
    
    if (!batteryOptGranted) {
      batteryOptGranted = await requestBatteryOptimizationWithDialog(context);
    }
    
    // Refresh Status
    await checkAllPermissions();
    
    final allGranted = allPermissionsGranted;
    debugPrint(allGranted ? '✅ All permissions granted!' : '⚠️ Some permissions missing');
    
    return allGranted;
  }
  
  /// Request Permission mit Material 3 Dialog
  Future<bool> requestPermissionWithDialog(
    BuildContext context, {
    required String permission,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
  }) async {
    if (!context.mounted) return false;
    
    // Baue Explanation basierend auf Permission Type
    final explanation = PermissionExplanation(
      icon: icon,
      title: title,
      description: description,
    );
    
    // Zeige Permission Rationale Dialog
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRequestDialog(
        title: 'Berechtigung erforderlich',
        description: 'Alarum benötigt die folgende Berechtigung:',
        icon: Icons.security,
        explanations: [explanation],
        onGrantPressed: () => Navigator.of(context).pop(true),
        onDenyPressed: () => Navigator.of(context).pop(false),
      ),
    );
    
    if (shouldRequest != true) {
      return false;
    }
    
    // Request Permission
    final granted = await _permissionManager.requestPermission(permission, description);
    
    // Update Status
    await checkPermission(permission);
    
    // Wenn permanently denied, zeige Settings Dialog
    if (!granted) {
      final isPermanentlyDenied = await _permissionManager.isPermissionPermanentlyDenied(permission);
      
      if (isPermanentlyDenied && context.mounted) {
        await _showPermanentlyDeniedDialog(context, title);
      }
    }
    
    return granted;
  }
  
  /// Request Battery Optimization mit speziellem Dialog
  Future<bool> requestBatteryOptimizationWithDialog(BuildContext context) async {
    if (!context.mounted) return false;
    
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => BatteryOptimizationDialog(
        onOpenSettings: () {
          Navigator.of(context).pop(true);
        },
        onSkip: () {
          Navigator.of(context).pop(false);
        },
      ),
    );
    
    if (shouldRequest != true) {
      return false;
    }
    
    // Request Battery Optimization Exclusion
    final granted = await _permissionManager.requestPermission(
      AndroidPermissions.ignoreBatteryOptimizations,
      'Für Alarme im Energiesparmodus',
    );
    
    // Update Status
    await checkPermission(AndroidPermissions.ignoreBatteryOptimizations);
    
    return granted;
  }
  
  // ═══════════════════════════════════════════════════════════
  // HELPER DIALOGS
  // ═══════════════════════════════════════════════════════════
  
  /// Zeige "Permanently Denied" Dialog
  Future<void> _showPermanentlyDeniedDialog(BuildContext context, String permissionName) async {
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.block,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text('$permissionName blockiert'),
        content: Text(
          'Die Berechtigung "$permissionName" wurde dauerhaft abgelehnt.\n\n'
          'Bitte aktiviere sie manuell in den App-Einstellungen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await _permissionManager.openAppSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Einstellungen'),
          ),
        ],
      ),
    );
  }
  
  /// Zeige Permission Summary
  Future<void> showPermissionSummary(BuildContext context) async {
    if (!context.mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Berechtigungen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPermissionStatusTile(
              'Exakte Alarme',
              _permissionStatus[AndroidPermissions.scheduleExactAlarm] ?? false,
              Icons.alarm,
            ),
            _buildPermissionStatusTile(
              'Benachrichtigungen',
              _permissionStatus[AndroidPermissions.postNotifications] ?? false,
              Icons.notifications,
            ),
            _buildPermissionStatusTile(
              'Akku-Optimierung',
              _permissionStatus[AndroidPermissions.ignoreBatteryOptimizations] ?? false,
              Icons.battery_charging_full,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Schließen'),
          ),
          if (!allPermissionsGranted)
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await requestAllPermissionsWithUI(context);
              },
              child: const Text('Berechtigungen anfordern'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPermissionStatusTile(String title, bool granted, IconData icon) {
    return ListTile(
      leading: Icon(
        icon,
        color: granted ? Colors.green : Colors.red,
      ),
      title: Text(title),
      trailing: Icon(
        granted ? Icons.check_circle : Icons.cancel,
        color: granted ? Colors.green : Colors.red,
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════
  
  @override
  void dispose() {
    debugPrint('🗑️ AlarmPermissionController disposed');
    super.dispose();
  }
}
