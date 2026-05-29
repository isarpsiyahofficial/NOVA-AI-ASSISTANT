package com.example.nova

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

object NovaReminderScheduler {
    const val CHANNEL_ID = "nova_reminders"
    private const val REQUEST_BASE = 730000

    fun sync(context: Context, items: List<Map<String, Any?>>) {
        ensureNotificationChannel(context)
        clearAll(context)

        for (item in items) {
            scheduleOne(context, item)
        }
    }

    fun rescheduleFromPreferences(context: Context) {
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val raw = prefs.getString("flutter.nova_reminders_v1", null) ?: return

        val parsed = NovaReminderJsonParser.parsePendingReminderMaps(raw)
        sync(context, parsed)
    }

    private fun scheduleOne(context: Context, item: Map<String, Any?>) {
        val dueAtIso = (item["dueAtIso"] as? String)?.trim().orEmpty()
        val reminderId = (item["id"] as? String)?.trim().orEmpty()
        val text = (item["text"] as? String)?.trim().orEmpty()
        val isWakeAlarm = item["isWakeAlarm"] as? Boolean ?: false
        val isCompleted = item["isCompleted"] as? Boolean ?: false

        if (dueAtIso.isEmpty() || reminderId.isEmpty() || isCompleted) return

        val triggerAtMillis = NovaReminderTimeParser.parseIsoToEpochMillis(dueAtIso)
        if (triggerAtMillis <= System.currentTimeMillis()) return

        val intent = Intent(context, NovaReminderReceiver::class.java).apply {
            putExtra("reminder_id", reminderId)
            putExtra("text", text)
            putExtra("is_wake_alarm", isWakeAlarm)
        }

        val requestCode = REQUEST_BASE + (reminderId.hashCode() and 0x7FFFFFFF)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            triggerAtMillis,
            pendingIntent
        )
    }

    private fun clearAll(context: Context) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        for (i in 0..999) {
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                REQUEST_BASE + i,
                Intent(context, NovaReminderReceiver::class.java),
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            )
            if (pendingIntent != null) {
                manager.cancel(pendingIntent)
                pendingIntent.cancel()
            }
        }
    }

    private fun ensureNotificationChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val notificationManager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Nova Hatırlatıcılar",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "Nova hatırlatıcı ve uyandırma bildirimleri"
        }

        notificationManager.createNotificationChannel(channel)
    }
}
