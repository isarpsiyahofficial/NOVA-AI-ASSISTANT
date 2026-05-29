package com.example.nova

import android.app.Service
import android.content.Intent
import android.os.IBinder

// NOVA_API_FIRST_NIGHT_WATCH_PASSIVE_V1
class NovaNightWatchService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        stopSelf(startId)
        return START_NOT_STICKY
    }
}
