package com.example.nova

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.speech.SpeechRecognizer
import androidx.core.content.ContextCompat

object NovaSpeechSessionManager {
    @Volatile
    private var recognizer: SpeechRecognizer? = null

    @Volatile
    private var activeClientCount: Int = 0

    @Volatile
    private var lastTouchedAt: Long = 0L

    private val mainHandler = Handler(Looper.getMainLooper())
    private const val AUTO_RELEASE_MS = 90_000L

    @Volatile
    private var keepWarmUntil: Long = 0L

    fun acquire(context: Context): SpeechRecognizer? {
        if (!hasRecordPermission(context)) return null
        if (!SpeechRecognizer.isRecognitionAvailable(context)) return null

        synchronized(this) {
            val existing = recognizer
            if (existing != null) {
                activeClientCount += 1
                lastTouchedAt = System.currentTimeMillis()
                scheduleReleaseCheck()
                return existing
            }

            val created = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    try {
                        SpeechRecognizer.createOnDeviceSpeechRecognizer(context)
                    } catch (_: Throwable) {
                        SpeechRecognizer.createSpeechRecognizer(context)
                    }
                } else {
                    SpeechRecognizer.createSpeechRecognizer(context)
                }
            } catch (_: Throwable) {
                null
            }

            recognizer = created
            if (created != null) {
                activeClientCount = 1
                lastTouchedAt = System.currentTimeMillis()
                scheduleReleaseCheck()
            }
            return created
        }
    }

    fun touch() {
        synchronized(this) {
            lastTouchedAt = System.currentTimeMillis()
        }
    }

    fun prewarm(context: Context, holdForMs: Long = 120_000L): Boolean {
        val acquired = acquire(context) ?: return false
        synchronized(this) {
            keepWarmUntil = System.currentTimeMillis() + holdForMs.coerceIn(15_000L, 30 * 60_000L)
            if (activeClientCount > 0) {
                activeClientCount -= 1
            }
            lastTouchedAt = System.currentTimeMillis()
            scheduleReleaseCheck()
        }
        return acquired != null
    }

    fun currentState(): Map<String, Any> {
        synchronized(this) {
            val now = System.currentTimeMillis()
            return mapOf(
                "hasRecognizer" to (recognizer != null),
                "activeClientCount" to activeClientCount,
                "lastTouchedAt" to lastTouchedAt,
                "keepWarmUntil" to keepWarmUntil,
                "keepWarmActive" to (keepWarmUntil > now),
                "autoReleaseMs" to AUTO_RELEASE_MS,
            )
        }
    }

    fun releaseSoft() {
        synchronized(this) {
            if (activeClientCount > 0) activeClientCount -= 1
            lastTouchedAt = System.currentTimeMillis()
            scheduleReleaseCheck()
        }
    }

    fun releaseHard() {
        synchronized(this) {
            val target = recognizer
            recognizer = null
            activeClientCount = 0
            lastTouchedAt = 0L
            keepWarmUntil = 0L
            try {
                target?.cancel()
            } catch (_: Throwable) {}
            try {
                target?.destroy()
            } catch (_: Throwable) {}
        }
    }

    private fun scheduleReleaseCheck() {
        mainHandler.removeCallbacksAndMessages(null)
        mainHandler.postDelayed({
            synchronized(this) {
                val now = System.currentTimeMillis()
                val keepWarmActive = keepWarmUntil > now
                val idleTooLong = activeClientCount <= 0 &&
                    lastTouchedAt > 0L &&
                    !keepWarmActive &&
                    (now - lastTouchedAt) >= AUTO_RELEASE_MS
                if (idleTooLong) {
                    releaseHard()
                } else if (recognizer != null) {
                    scheduleReleaseCheck()
                }
            }
        }, AUTO_RELEASE_MS)
    }

    private fun hasRecordPermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED
    }
}
