package com.example.nova

import android.content.Context

class NovaXttsEngine(
    private val context: Context
) {
    @Volatile private var warmedUp: Boolean = false

    fun isReady(): Boolean = warmedUp

    fun getCapabilities(): Map<String, Any> {
        return mapOf(
            "ready" to isReady(),
            "assetReady" to false,
            "currentModelKey" to "android_platform_tts",
            "assetDir" to "",
            "modelFileName" to "",
            "tokensFileName" to "",
            "supportsSpeakerId" to false,
            "supportsReferenceAudio" to false,
            "availableModels" to listOf("android_platform_tts"),
            "message" to "Sherpa/ONNX TTS AAR zorunluluğu kaldırıldı; Türkçe konuşma Android platform TTS ağız adaptörüyle yürür."
        )
    }

    fun warmup(preferredModelKey: String = "android_platform_tts"): Boolean {
        warmedUp = true
        return true
    }

    fun speak(
        text: String,
        language: String = "tr",
        speakerPath: String = ""
    ): Boolean {
        val prepared = text.replace(Regex("\\s+"), " ").trim()
        if (prepared.isEmpty()) return false
        warmedUp = true
        return NovaAndroidTtsMouthEngine.speak(
            context = context,
            text = prepared,
            language = language.ifBlank { "tr" },
            preferFemale = true,
            allowUnknownGenderTurkish = true,
            waitForDone = true
        )
    }

    fun stop() {
        try {
            NovaAndroidTtsMouthEngine.stop()
        } catch (_: Throwable) {
        }
    }
}
