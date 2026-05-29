package com.example.nova.asr

import android.content.Context

object NovaStreamingAsrEngineProvider {
    @Volatile
    private var engine: NovaStreamingAsrEngine? = null

    fun get(context: Context): NovaStreamingAsrEngine {
        val existing = engine
        if (existing != null) return existing
        return synchronized(this) {
            engine ?: NovaStreamingAsrEngine(context.applicationContext).also { engine = it }
        }
    }
}
