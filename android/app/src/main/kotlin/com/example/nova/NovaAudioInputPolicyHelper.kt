package com.example.nova

import android.content.Context

object NovaAudioInputPolicyHelper {

    fun beginPassiveListening(context: Context): Map<String, Any?> {
        return NovaAudioInputPolicy.beginPassiveListening(context)
    }

    fun beginCallCompanionListening(context: Context): Map<String, Any?> {
        return NovaAudioInputPolicy.beginCallCompanionListening(context)
    }

    fun endListeningSession(context: Context): Map<String, Any?> {
        return NovaAudioInputPolicy.endListeningSession(context)
    }

    fun getState(context: Context): Map<String, Any?> {
        return NovaAudioInputPolicy.getState(context)
    }

    fun buildDebugSummary(context: Context): Map<String, Any?> {
        val state = NovaAudioInputPolicy.getState(context)
        val owner = state["owner"] as? String ?: "idle"
        val mode = state["mode"] as? String ?: "unknown"
        val mic = state["micOpen"] as? Boolean ?: false
        val speech = state["speechActive"] as? Boolean ?: false
        val shouldHold = owner == "call" || owner == "continuousListening"
        return linkedMapOf(
            "owner" to owner,
            "mode" to mode,
            "micOpen" to mic,
            "speechActive" to speech,
            "shouldHoldMic" to shouldHold,
            "humanDigitalPresenceReady" to (mic && shouldHold),
        )
    }
}
