package com.example.nova

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat

class NovaReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val reminderId = intent.getStringExtra("reminder_id").orEmpty()
        val text = intent.getStringExtra("text").orEmpty().ifBlank {
            "Bir hatırlatmanız var efendim."
        }
        val isWakeAlarm = intent.getBooleanExtra("is_wake_alarm", false)

        val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val contentPendingIntent = PendingIntent.getActivity(
            context,
            reminderId.hashCode(),
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val title = if (isWakeAlarm) "Nova Uyandırma" else "Nova Hatırlatma"
        val body = if (isWakeAlarm) "Efendim dikkat. $text" else "Hatırlatma efendim. $text"

        val notification = NotificationCompat.Builder(context, NovaReminderScheduler.CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(contentPendingIntent)
            .build()

        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(reminderId.hashCode(), notification)
    }
}
