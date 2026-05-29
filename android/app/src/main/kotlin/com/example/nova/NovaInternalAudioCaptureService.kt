package com.example.nova

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class NovaInternalAudioCaptureService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        ensureChannel()
        startForeground(
            NOTIFICATION_ID,
            buildNotification("Nova telefon içi sesi yakalamaya hazır.")
        )
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.getStringExtra(EXTRA_ACTION).orEmpty()

        when (action) {
            ACTION_RUNNING -> updateNotification("Nova telefon içi ses örneği alıyor.")
            ACTION_IDLE -> updateNotification("Nova telefon içi ses izni hazır.")
            ACTION_STOP -> {
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }

        return START_NOT_STICKY
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Nova Internal Audio Capture",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Nova telefon içi ses yakalama bildirimi"
        }

        manager.createNotificationChannel(channel)
    }

    private fun buildNotification(text: String): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Nova")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.sym_def_app_icon)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(text: String) {
        val manager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(NOTIFICATION_ID, buildNotification(text))
    }

    companion object {
        const val CHANNEL_ID = "nova_internal_audio_capture_channel"
        const val NOTIFICATION_ID = 4119
        const val EXTRA_ACTION = "nova_internal_audio_capture_action"

        const val ACTION_RUNNING = "running"
        const val ACTION_IDLE = "idle"
        const val ACTION_STOP = "stop"

        fun start(context: Context) {
            val intent = Intent(context, NovaInternalAudioCaptureService::class.java).apply {
                putExtra(EXTRA_ACTION, ACTION_IDLE)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun showRunning(context: Context) {
            val intent = Intent(context, NovaInternalAudioCaptureService::class.java).apply {
                putExtra(EXTRA_ACTION, ACTION_RUNNING)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, NovaInternalAudioCaptureService::class.java).apply {
                putExtra(EXTRA_ACTION, ACTION_STOP)
            }
            context.startService(intent)
        }
    }
}