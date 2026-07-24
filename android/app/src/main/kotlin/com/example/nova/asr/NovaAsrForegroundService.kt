package com.example.nova.asr

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat
import com.example.nova.NovaStreamingVoiceGate

class NovaAsrForegroundService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ensureChannel()
        val notification: Notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Nova sürekli dinleme")
            .setContentText("Yerel mikrofon ve embedded ASR oturumu aktif")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .build()
        ServiceCompat.startForeground(
            this,
            NOTIFICATION_ID,
            notification,
            android.content.pm.ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
        )

        // A sticky notification without a live Flutter/EventChannel consumer is
        // misleading and can leave an orphan microphone session after process
        // recreation. The runtime explicitly starts the service whenever the
        // single ASR owner is restored.
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        try {
            NovaStreamingAsrEngineProvider.get(applicationContext).stop()
        } catch (_: Throwable) {
        }
        try {
            NovaStreamingVoiceGate.stop()
        } catch (_: Throwable) {
        }
        stopForeground(STOP_FOREGROUND_REMOVE)
        super.onDestroy()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Nova sürekli dinleme",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Nova'nın cihaz üzerinde çalışan sürekli mikrofon ve konuşma tanıma oturumu"
            setShowBadge(false)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val CHANNEL_ID = "nova_asr_runtime"
        private const val NOTIFICATION_ID = 4701
    }
}
