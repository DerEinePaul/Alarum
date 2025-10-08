package com.example.alarum

import android.app.KeyguardManager
import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView
import io.flutter.embedding.android.FlutterActivity

/**
 * Full-Screen Activity die angezeigt wird wenn ein Alarm klingelt
 * 
 * FEATURES:
 * - Full-Screen über Lock Screen
 * - MediaPlayer für Alarm Sound
 * - Vibration
 * - Snooze Button (5 Minuten)
 * - Dismiss Button
 * - Screen bleibt an (WakeLock)
 */
class AlarmActivity : FlutterActivity() {
    
    companion object {
        private const val TAG = "AlarmActivity"
        private const val SNOOZE_DURATION_MILLIS = 5 * 60 * 1000L // 5 Minuten
    }
    
    private var mediaPlayer: MediaPlayer? = null
    private var vibrator: Vibrator? = null
    private var wakeLock: PowerManager.WakeLock? = null
    
    private var alarmId: Int = -1
    private var alarmTitle: String = "Alarm"
    private var alarmBody: String = ""
    private var soundAsset: String? = null
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Get Alarm Data from Intent
        alarmId = intent.getIntExtra(AlarmReceiver.EXTRA_ALARM_ID, -1)
        alarmTitle = intent.getStringExtra(AlarmReceiver.EXTRA_ALARM_TITLE) ?: "Alarm"
        alarmBody = intent.getStringExtra(AlarmReceiver.EXTRA_ALARM_BODY) ?: ""
        soundAsset = intent.getStringExtra(AlarmReceiver.EXTRA_SOUND_ASSET)
        
        Log.d(TAG, "⏰ AlarmActivity started: ID=$alarmId, Title=$alarmTitle")
        
        // ═══════════════════════════════════════════════════════════
        // 1. SETUP WINDOW FLAGS (Show over Lock Screen)
        // ═══════════════════════════════════════════════════════════
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
            
            val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
            keyguardManager.requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }
        
        // ═══════════════════════════════════════════════════════════
        // 2. ACQUIRE WAKE LOCK
        // ═══════════════════════════════════════════════════════════
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or 
            PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "Alarum::AlarmActivityWakeLock"
        )
        wakeLock?.acquire(10 * 60 * 1000L) // 10 Minuten max
        
        // ═══════════════════════════════════════════════════════════
        // 3. START SOUND & VIBRATION
        // ═══════════════════════════════════════════════════════════
        startAlarmSound()
        startVibration()
        
        // ═══════════════════════════════════════════════════════════
        // 4. SETUP UI
        // ═══════════════════════════════════════════════════════════
        // TODO: Hier könntest du ein eigenes Layout laden
        // Für jetzt nutzen wir Flutter UI über MethodChannel
    }
    
    /**
     * Startet Alarm Sound über MediaPlayer
     */
    private fun startAlarmSound() {
        try {
            // Wähle Sound: Custom Asset oder Default Ringtone
            val soundUri: Uri = if (soundAsset != null) {
                // TODO: Load from Flutter assets
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            } else {
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
            }
            
            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@AlarmActivity, soundUri)
                
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                
                isLooping = true
                prepare()
                start()
            }
            
            Log.d(TAG, "🔊 Alarm sound started")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start alarm sound: ${e.message}")
        }
    }
    
    /**
     * Startet Vibration Pattern
     */
    private fun startVibration() {
        try {
            vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            
            // Vibration Pattern: [Pause, Vibrate, Pause, Vibrate, ...]
            val pattern = longArrayOf(0, 1000, 500, 1000, 500, 1000)
            
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = VibrationEffect.createWaveform(pattern, 0) // 0 = repeat
                vibrator?.vibrate(effect)
            } else {
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
            }
            
            Log.d(TAG, "📳 Vibration started")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start vibration: ${e.message}")
        }
    }
    
    /**
     * Stoppt Sound und Vibration
     */
    private fun stopAlarmSound() {
        mediaPlayer?.apply {
            if (isPlaying) {
                stop()
            }
            release()
        }
        mediaPlayer = null
        
        vibrator?.cancel()
        vibrator = null
        
        Log.d(TAG, "🔇 Alarm sound stopped")
    }
    
    /**
     * Snooze Alarm (5 Minuten später)
     */
    fun snoozeAlarm() {
        Log.d(TAG, "😴 Snoozing alarm for 5 minutes...")
        
        // TODO: Reschedule alarm über MethodChannel
        // flutterEngine.dartExecutor.binaryMessenger.send(...)
        
        stopAlarmSound()
        finish()
    }
    
    /**
     * Dismiss Alarm (komplett beenden)
     */
    fun dismissAlarm() {
        Log.d(TAG, "✅ Dismissing alarm")
        
        stopAlarmSound()
        finish()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        stopAlarmSound()
        
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
        
        Log.d(TAG, "🗑️ AlarmActivity destroyed")
    }
    
    override fun onBackPressed() {
        // Verhindere dass Benutzer Alarm mit Back-Button schließen kann
        // Er muss Snooze oder Dismiss drücken
    }
}
