package com.example.alarum

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.os.PowerManager
import android.app.KeyguardManager

/**
 * BroadcastReceiver der ausgelöst wird wenn ein Alarm klingelt
 * 
 * AUFGABEN:
 * - Alarm Intent empfangen
 * - Screen wecken (WakeLock)
 * - Lock Screen umgehen (KeyguardManager)
 * - AlarmActivity starten mit Full-Screen Intent
 * - Notification anzeigen (über Flutter)
 */
class AlarmReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "AlarmReceiver"
        const val ACTION_ALARM_TRIGGERED = "com.example.alarum.ALARM_TRIGGERED"
        const val EXTRA_ALARM_ID = "alarm_id"
        const val EXTRA_ALARM_TITLE = "alarm_title"
        const val EXTRA_ALARM_BODY = "alarm_body"
        const val EXTRA_SOUND_ASSET = "sound_asset"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_ALARM_TRIGGERED) {
            return
        }
        
        val alarmId = intent.getIntExtra(EXTRA_ALARM_ID, -1)
        val title = intent.getStringExtra(EXTRA_ALARM_TITLE) ?: "Alarm"
        val body = intent.getStringExtra(EXTRA_ALARM_BODY) ?: ""
        val soundAsset = intent.getStringExtra(EXTRA_SOUND_ASSET)
        
        Log.d(TAG, "⏰ Alarm triggered: ID=$alarmId, Title=$title")
        
        // ═══════════════════════════════════════════════════════════
        // 1. WAKE SCREEN (WakeLock für 60 Sekunden)
        // ═══════════════════════════════════════════════════════════
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or 
            PowerManager.ACQUIRE_CAUSES_WAKEUP or 
            PowerManager.ON_AFTER_RELEASE,
            "Alarum::AlarmWakeLock"
        )
        
        wakeLock.acquire(60 * 1000L) // 60 Sekunden
        
        // ═══════════════════════════════════════════════════════════
        // 2. UNLOCK SCREEN (KeyguardManager)
        // ═══════════════════════════════════════════════════════════
        val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        
        // Dismiss Keyguard (funktioniert nur auf älteren Android Versionen)
        @Suppress("DEPRECATION")
        val keyguardLock = keyguardManager.newKeyguardLock("Alarum::AlarmKeyguardLock")
        @Suppress("DEPRECATION")
        keyguardLock.disableKeyguard()
        
        // ═══════════════════════════════════════════════════════════
        // 3. START ALARM ACTIVITY (Full-Screen Intent)
        // ═══════════════════════════════════════════════════════════
        val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_NO_USER_ACTION or
                    Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS or
                    Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
            
            putExtra(EXTRA_ALARM_ID, alarmId)
            putExtra(EXTRA_ALARM_TITLE, title)
            putExtra(EXTRA_ALARM_BODY, body)
            putExtra(EXTRA_SOUND_ASSET, soundAsset)
        }
        
        context.startActivity(alarmIntent)
        
        Log.d(TAG, "✅ Alarm activity started, screen woken")
        
        // WakeLock wird nach 60 Sekunden automatisch released
    }
}
