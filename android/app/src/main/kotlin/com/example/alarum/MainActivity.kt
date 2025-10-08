package com.example.alarum

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity mit MethodChannel Handlers für:
 * - com.alarum.alarm/scheduler (AlarmManager API)
 * - com.alarum.alarm/permissions (Runtime Permissions)
 * - com.alarum.alarm/notifications (Notification Permissions)
 */
class MainActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "MainActivity"
        private const val ALARM_CHANNEL = "com.alarum.alarm/scheduler"
        private const val PERMISSION_CHANNEL = "com.alarum.alarm/permissions"
        private const val NOTIFICATION_CHANNEL = "com.alarum.alarm/notifications"
        
        private const val REQUEST_CODE_EXACT_ALARM = 1001
        private const val REQUEST_CODE_NOTIFICATION = 1002
        private const val REQUEST_CODE_BATTERY_OPT = 1003
    }
    
    private var alarmManager: AlarmManager? = null
    private var notificationManager: NotificationManager? = null
    private var powerManager: PowerManager? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize System Services
        alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        
        // ═══════════════════════════════════════════════════════════
        // 1. ALARM SCHEDULER CHANNEL
        // ═══════════════════════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ALARM_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleExactAlarm" -> {
                    val alarmId = call.argument<Int>("alarmId") ?: -1
                    val triggerAtMillis = call.argument<Long>("triggerAtMillis") ?: 0L
                    val title = call.argument<String>("title") ?: "Alarm"
                    val body = call.argument<String>("body") ?: ""
                    val soundAsset = call.argument<String>("soundAsset")
                    val useAlarmClock = call.argument<Boolean>("useAlarmClock") ?: true
                    
                    scheduleExactAlarm(alarmId, triggerAtMillis, title, body, soundAsset, useAlarmClock)
                    result.success(true)
                }
                
                "cancelScheduledAlarm" -> {
                    val alarmId = call.argument<Int>("alarmId") ?: -1
                    cancelScheduledAlarm(alarmId)
                    result.success(true)
                }
                
                "canScheduleExactAlarms" -> {
                    val canSchedule = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        alarmManager?.canScheduleExactAlarms() == true
                    } else {
                        true
                    }
                    result.success(canSchedule)
                }
                
                "openExactAlarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                    }
                    result.success(true)
                }
                
                "isIgnoringBatteryOptimizations" -> {
                    val isIgnoring = powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
                    result.success(isIgnoring)
                }
                
                "requestIgnoreBatteryOptimizations" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                            data = Uri.parse("package:$packageName")
                        }
                        startActivity(intent)
                    }
                    result.success(true)
                }
                
                else -> result.notImplemented()
            }
        }
        
        // ═══════════════════════════════════════════════════════════
        // 2. PERMISSION CHANNEL
        // ═══════════════════════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    val permission = call.argument<String>("permission") ?: ""
                    val granted = checkPermission(permission)
                    result.success(granted)
                }
                
                "requestPermission" -> {
                    val permission = call.argument<String>("permission") ?: ""
                    requestPermission(permission)
                    result.success(true)
                }
                
                "openAppSettings" -> {
                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                    result.success(true)
                }
                
                "isPermissionPermanentlyDenied" -> {
                    // TODO: Track permission denials in SharedPreferences
                    result.success(false)
                }
                
                else -> result.notImplemented()
            }
        }
        
        // ═══════════════════════════════════════════════════════════
        // 3. NOTIFICATION CHANNEL
        // ═══════════════════════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasNotificationPermission" -> {
                    val hasPermission = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ContextCompat.checkSelfPermission(
                            this,
                            android.Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                    } else {
                        true
                    }
                    result.success(hasPermission)
                }
                
                "requestNotificationPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                            REQUEST_CODE_NOTIFICATION
                        )
                    }
                    result.success(true)
                }
                
                "isChannelEnabled" -> {
                    val channelId = call.argument<String>("channelId") ?: ""
                    val enabled = notificationManager?.getNotificationChannel(channelId)?.importance != 
                                  NotificationManager.IMPORTANCE_NONE
                    result.success(enabled)
                }
                
                else -> result.notImplemented()
            }
        }
    }
    
    /**
     * Schedule Exact Alarm using AlarmManager
     */
    private fun scheduleExactAlarm(
        alarmId: Int,
        triggerAtMillis: Long,
        title: String,
        body: String,
        soundAsset: String?,
        useAlarmClock: Boolean
    ) {
        Log.d(TAG, "⏰ Scheduling alarm: ID=$alarmId, Time=$triggerAtMillis, UseAlarmClock=$useAlarmClock")
        
        // Create Intent for AlarmReceiver
        val intent = Intent(this, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_TRIGGERED
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, alarmId)
            putExtra(AlarmReceiver.EXTRA_ALARM_TITLE, title)
            putExtra(AlarmReceiver.EXTRA_ALARM_BODY, body)
            putExtra(AlarmReceiver.EXTRA_SOUND_ASSET, soundAsset)
        }
        
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Schedule Alarm
        if (useAlarmClock && Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            // AlarmManager.setAlarmClock() - Höchste Priorität
            val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, pendingIntent)
            alarmManager?.setAlarmClock(alarmClockInfo, pendingIntent)
            Log.d(TAG, "✅ Alarm scheduled with setAlarmClock()")
        } else {
            // ExactAndAllowWhileIdle - Für Timer
            alarmManager?.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
            Log.d(TAG, "✅ Alarm scheduled with setExactAndAllowWhileIdle()")
        }
    }
    
    /**
     * Cancel Scheduled Alarm
     */
    private fun cancelScheduledAlarm(alarmId: Int) {
        Log.d(TAG, "❌ Cancelling alarm: ID=$alarmId")
        
        val intent = Intent(this, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        alarmManager?.cancel(pendingIntent)
        pendingIntent.cancel()
        
        Log.d(TAG, "✅ Alarm cancelled")
    }
    
    /**
     * Check Permission
     */
    private fun checkPermission(permission: String): Boolean {
        return when (permission) {
            "android.permission.SCHEDULE_EXACT_ALARM" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    alarmManager?.canScheduleExactAlarms() == true
                } else {
                    true
                }
            }
            
            "android.permission.POST_NOTIFICATIONS" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    ContextCompat.checkSelfPermission(
                        this,
                        android.Manifest.permission.POST_NOTIFICATIONS
                    ) == PackageManager.PERMISSION_GRANTED
                } else {
                    true
                }
            }
            
            "android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" -> {
                powerManager?.isIgnoringBatteryOptimizations(packageName) ?: false
            }
            
            else -> {
                ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
            }
        }
    }
    
    /**
     * Request Permission
     */
    private fun requestPermission(permission: String) {
        when (permission) {
            "android.permission.SCHEDULE_EXACT_ALARM" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                }
            }
            
            "android.permission.POST_NOTIFICATIONS" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    ActivityCompat.requestPermissions(
                        this,
                        arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                        REQUEST_CODE_NOTIFICATION
                    )
                }
            }
            
            "android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                    startActivity(intent)
                }
            }
            
            else -> {
                ActivityCompat.requestPermissions(this, arrayOf(permission), REQUEST_CODE_EXACT_ALARM)
            }
        }
    }
}
