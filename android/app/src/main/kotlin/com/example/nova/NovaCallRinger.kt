package com.example.nova

import android.content.Context
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

object NovaCallRinger {

    private var ringtone: Ringtone? = null
    private var vibrating = false

    fun start(context: Context, rawNumber: String? = null) {
        try {
            val appContext = context.applicationContext
            if (ringtone?.isPlaying != true) {
                val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
                    ?: RingtoneManager.getActualDefaultRingtoneUri(appContext, RingtoneManager.TYPE_RINGTONE)
                ringtone = RingtoneManager.getRingtone(appContext, uri)?.apply {
                    audioAttributes = AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                    play()
                }
            }
            startVibration(appContext)
        } catch (_: Throwable) {
        }
    }

    fun stop(context: Context) {
        try {
            ringtone?.stop()
        } catch (_: Throwable) {
        }
        ringtone = null
        stopVibration(context.applicationContext)
    }

    private fun startVibration(context: Context) {
        if (vibrating) return
        try {
            val pattern = longArrayOf(0, 350, 250, 350)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                val vibrator = manager?.defaultVibrator
                vibrator?.let {
                    it.vibrate(VibrationEffect.createWaveform(pattern, 0))
                    vibrating = true
                }
            } else {
                @Suppress("DEPRECATION")
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                @Suppress("DEPRECATION")
                vibrator?.vibrate(pattern, 0)
                vibrating = vibrator != null
            }
        } catch (_: Throwable) {
            vibrating = false
        }
    }

    private fun stopVibration(context: Context) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
                manager?.defaultVibrator?.cancel()
            } else {
                @Suppress("DEPRECATION")
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
                vibrator?.cancel()
            }
        } catch (_: Throwable) {
        }
        vibrating = false
    }
}
