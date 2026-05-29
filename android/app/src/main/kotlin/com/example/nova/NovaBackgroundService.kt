package com.example.nova

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

class NovaBackgroundService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        try {
            ensureChannel()
            startForeground(
                NOTIFICATION_ID,
                buildNotification("Nova arka planda hazır.")
            )
        } catch (t: Throwable) {
            Log.e(TAG, "Foreground start failed", t)
            stopSelf()
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    return try {
        when (intent?.getStringExtra(EXTRA_ACTION).orEmpty()) {
            ACTION_KEEP_ALIVE -> {
                updateNotification("Nova arka planda hazır bekliyor.")
                START_STICKY
            }
            ACTION_RUNNING -> {
                updateNotification("Nova aktif çalışma modunda.")
                START_STICKY
            }
            ACTION_SLEEPING -> {
                updateNotification("Nova pasif beklemede.")
                START_STICKY
            }
            ACTION_FULLY_OFF -> {
                updateNotification("Nova arka plan hizmeti kapatılıyor.")
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
                START_NOT_STICKY
            }
            else -> {
                updateNotification("Nova arka plan hizmeti çalışıyor.")
                START_STICKY
            }
        }
    } catch (t: Throwable) {
        Log.e(TAG, "onStartCommand failed", t)
        stopSelf()
        START_NOT_STICKY
    }
}

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Nova Background",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Nova arka plan çalışma bildirimi"
            setShowBadge(false)
        }

        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(text: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Nova")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.sym_def_app_icon)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(text: String) {
        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(text))
    }

    companion object {
        private const val TAG = "NovaBackgroundSvc"
        const val CHANNEL_ID = "nova_background_channel"
        const val NOTIFICATION_ID = 4120
        const val EXTRA_ACTION = "nova_background_action"

        const val ACTION_KEEP_ALIVE = "keep_alive"
        const val ACTION_RUNNING = "running"
        const val ACTION_SLEEPING = "sleeping"
        const val ACTION_FULLY_OFF = "fully_off"
    }
}
