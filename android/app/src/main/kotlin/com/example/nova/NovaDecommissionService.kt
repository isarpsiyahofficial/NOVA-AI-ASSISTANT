package com.example.nova

import android.app.Service
import android.content.Intent
import android.os.IBinder

// NOVA_API_FIRST_DECOMMISSION_PASSIVE_V1
class NovaDecommissionService : Service() {
    override fun onBind(intent: Intent?): IBinder? = null
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        stopSelf(startId)
        return START_NOT_STICKY
    }
}
