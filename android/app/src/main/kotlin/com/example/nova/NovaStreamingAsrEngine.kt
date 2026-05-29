package com.example.nova

import android.content.Context

/**
 * Geri uyumluluk sarmalayıcısı.
 * Gerçek implementasyon com.example.nova.asr paketindeki engine içinde tutulur.
 * Böylece eski importlar bozulmadan kalır ve çift sınıf tanımı oluşmaz.
 */
class NovaStreamingAsrEngine(private val context: Context) {
    private val delegate = com.example.nova.asr.NovaStreamingAsrEngine(context)

    fun initialize(): Boolean = delegate.initialize()

    fun start(onEvent: (String, com.example.nova.asr.NovaStreamingAsrResult, String) -> Unit): Boolean =
        delegate.start(onEvent)

    fun decodeStreamingSnapshot(
        mode: String,
        maxDurationSeconds: Int,
        callback: (success: Boolean, text: String, locale: String, message: String, usedEmbedded: Boolean) -> Unit,
    ) = delegate.decodeStreamingSnapshot(mode, maxDurationSeconds, callback)

    fun pause(): Boolean = delegate.pause()
    fun resume(): Boolean = delegate.resume()
    fun stop(): Boolean = delegate.stop()
    fun flush(): Boolean = delegate.flush()
    fun clearBuffer(): Boolean = delegate.clearBuffer()
    fun setForegroundServiceRunning(value: Boolean) = delegate.setForegroundServiceRunning(value)
    fun stateMap(): Map<String, Any> = delegate.stateMap()
}
