package com.example.nova

import android.content.Context
import android.util.Log
import java.util.concurrent.atomic.AtomicLong

class ModelBridge(private val appContext: Context? = null) {

    companion object {
        private const val TAG = "NovaModelBridge"
        private val generationSerial = AtomicLong(0L)
    }

    fun backendState(): String {
        return "backend=api;ready=false;message=Yerel Gemma LiteRT-LM motoru Nova API-first APK sürümünde devre dışı. Aktif beyin Gemini/OpenAI API router üzerinden çalışır."
    }

    fun cancelGeneration(): Boolean {
        val serial = generationSerial.incrementAndGet()
        Log.i(TAG, "NOVA_API_FIRST_LOCAL_GENERATION_CANCELLED serial=$serial")
        return true
    }

    fun releaseEngine(reason: String = "manual_release"): Boolean {
        Log.i(TAG, "NOVA_API_FIRST_LOCAL_ENGINE_RELEASE_NOOP reason=$reason")
        return true
    }

    fun hasRealBackend(): Boolean = false

    fun generate(
        prompt: String,
        systemPrompt: String,
        modelPath: String,
        fastMode: Boolean,
        maxOutputTokens: Int = if (fastMode) 64 else 128,
        stopOnNewline: Boolean = false
    ): String {
        throw IllegalStateException(
            "API-first Nova sürümünde yerel Gemma/LiteRT-LM üretimi kapalıdır; cevap Dart API router üzerinden alınmalıdır."
        )
    }
}
