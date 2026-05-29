package com.example.nova.audio

object NovaUnifiedAudioSessionCoordinator {
    @Volatile private var currentOwner: String = "idle"
    @Volatile private var lastTransitionMs: Long = 0L

    @Synchronized
    fun tryAcquire(owner: String): Boolean {
        if (currentOwner == owner) return true
        if (currentOwner == "call" && owner == "continuousListening") return false
        if (currentOwner == "tts" && owner == "continuousListening") return false
        currentOwner = owner
        lastTransitionMs = System.currentTimeMillis()
        return true
    }

    @Synchronized
    fun release(owner: String) {
        if (currentOwner == owner) {
            currentOwner = "idle"
            lastTransitionMs = System.currentTimeMillis()
        }
    }

    fun state(): String = currentOwner

    fun debugState(): Map<String, Any> = linkedMapOf(
        "owner" to currentOwner,
        "lastTransitionMs" to lastTransitionMs,
        "canContinuousListeningAcquire" to (currentOwner != "call" && currentOwner != "tts"),
        "callHasPriority" to (currentOwner == "call"),
    )
}
