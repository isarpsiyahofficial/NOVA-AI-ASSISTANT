package com.example.nova

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log

object NovaNativeServiceBridge {

    private const val TAG = "NovaNativeBridge"

    fun startBackground(context: Context): Boolean {
        return startBackgroundWithAction(
            context,
            NovaBackgroundService.ACTION_KEEP_ALIVE
        )
    }

    fun setBackgroundRunning(context: Context): Boolean {
        return startBackgroundWithAction(
            context,
            NovaBackgroundService.ACTION_RUNNING
        )
    }

    fun setBackgroundSleeping(context: Context): Boolean {
        return startBackgroundWithAction(
            context,
            NovaBackgroundService.ACTION_SLEEPING
        )
    }

    fun setBackgroundFullyOff(context: Context): Boolean {
        return startBackgroundWithAction(
            context,
            NovaBackgroundService.ACTION_FULLY_OFF
        )
    }

    fun showOverlayIdle(context: Context): Boolean {
        if (!Settings.canDrawOverlays(context)) return false
        return startOverlay(
            context = context,
            action = NovaOverlayService.ACTION_SHOW_IDLE
        )
    }

    fun showOverlayListening(context: Context): Boolean {
        if (!Settings.canDrawOverlays(context)) return false
        return startOverlay(
            context = context,
            action = NovaOverlayService.ACTION_SHOW_LISTENING
        )
    }

    fun showOverlaySpeaking(context: Context): Boolean {
        if (!Settings.canDrawOverlays(context)) return false
        return startOverlay(
            context = context,
            action = NovaOverlayService.ACTION_SHOW_SPEAKING
        )
    }

    fun showOverlaySleeping(context: Context): Boolean {
        if (!Settings.canDrawOverlays(context)) return false
        return startOverlay(
            context = context,
            action = NovaOverlayService.ACTION_SHOW_SLEEPING
        )
    }

    fun showCloneOverlayProgress(
        context: Context,
        title: String,
        status: String,
        progress: Float,
    ): Boolean {
        if (!Settings.canDrawOverlays(context)) return false
        return startOverlay(
            context = context,
            action = NovaOverlayService.ACTION_SHOW_CLONE_PROGRESS,
            title = title,
            status = status,
            progress = progress
        )
    }

    fun hideOverlay(context: Context): Boolean {
        if (!Settings.canDrawOverlays(context)) return false
        return startOverlay(
            context = context,
            action = NovaOverlayService.ACTION_HIDE
        )
    }

    fun removeOverlay(context: Context): Boolean {
        if (!Settings.canDrawOverlays(context)) return false
        return startOverlay(
            context = context,
            action = NovaOverlayService.ACTION_REMOVE
        )
    }

    private fun startBackgroundWithAction(context: Context, action: String): Boolean {
        return try {
            val intent = Intent(context, NovaBackgroundService::class.java).apply {
                putExtra(NovaBackgroundService.EXTRA_ACTION, action)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            true
        } catch (t: Throwable) {
            Log.w(TAG, "Background service start skipped: ${t.message}")
            false
        }
    }

    private fun startOverlay(
        context: Context,
        action: String,
        title: String? = null,
        status: String? = null,
        progress: Float? = null,
    ): Boolean {
        return try {
            val intent = Intent(context, NovaOverlayService::class.java).apply {
                putExtra(NovaOverlayService.EXTRA_ACTION, action)

                if (title != null) {
                    putExtra(NovaOverlayService.EXTRA_TITLE, title)
                }
                if (status != null) {
                    putExtra(NovaOverlayService.EXTRA_STATUS, status)
                }
                if (progress != null) {
                    putExtra(NovaOverlayService.EXTRA_PROGRESS, progress)
                }
            }

            context.startService(intent)
            true
        } catch (t: Throwable) {
            Log.w(TAG, "Overlay start skipped: ${t.message}")
            false
        }
    }
}