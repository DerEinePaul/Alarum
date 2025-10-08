package com.example.alarum

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.os.Build

/**
 * BroadcastReceiver der nach Geräte-Neustart ausgelöst wird
 * 
 * AUFGABEN:
 * - BOOT_COMPLETED Intent empfangen
 * - Alle gespeicherten Alarme aus Hive lesen
 * - Alarme erneut im AlarmManager registrieren
 * - Läuft im Hintergrund (keine UI)
 */
class BootCompletedReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootCompletedReceiver"
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) {
            return
        }
        
        Log.d(TAG, "🔄 Device booted, rescheduling alarms...")
        
        // ═══════════════════════════════════════════════════════════
        // Starte Flutter Engine um Alarme zu reschedule
        // ═══════════════════════════════════════════════════════════
        // Flutter's MethodChannel Handler wird die Arbeit machen:
        // - rescheduleAllAlarms() aufrufen
        // - Alarme aus Hive lesen
        // - Jeden Alarm erneut schedulen
        
        // Starte MainActivity im Hintergrund
        val mainActivityIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            putExtra("BOOT_RESCHEDULE", true)
        }
        
        try {
            context.startActivity(mainActivityIntent)
            Log.d(TAG, "✅ MainActivity started for alarm rescheduling")
        } catch (e: Exception) {
            Log.e(TAG, "❌ Failed to start MainActivity after boot: ${e.message}")
        }
    }
}
