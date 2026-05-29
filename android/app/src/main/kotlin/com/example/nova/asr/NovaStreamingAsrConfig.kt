package com.example.nova.asr

data class NovaStreamingAsrConfig(
    val sampleRate: Int = 16000,
    val chunkSize: Int = 1600,
    val beamSize: Int = 4,
    val endpointingMs: Long = 1100L,
    val stabilizeTokenWindow: Int = 4,
    val partialConfidenceFloor: Float = 0.35f,
    val maxSessionMs: Long = 45_000L,
    val minSpeechMs: Long = 180L,
    val minSilenceGapMs: Long = 220L,
    val ownerPriorityBoost: Float = 0.18f,
    val knownSpeakerBoost: Float = 0.10f,
    val overlapPenalty: Float = 0.14f,
    val bargeInSensitivity: Float = 0.58f,
    val emotionalPauseHoldMs: Long = 420L,
    val duplicatePartialPenalty: Float = 0.12f,
) {
    fun normalized(): NovaStreamingAsrConfig {
        return copy(
            sampleRate = sampleRate.coerceIn(8000, 48000),
            chunkSize = chunkSize.coerceIn(320, 4096),
            beamSize = beamSize.coerceIn(1, 12),
            endpointingMs = endpointingMs.coerceIn(350L, 4000L),
            stabilizeTokenWindow = stabilizeTokenWindow.coerceIn(1, 12),
            partialConfidenceFloor = partialConfidenceFloor.coerceIn(0.05f, 0.95f),
            maxSessionMs = maxSessionMs.coerceIn(5_000L, 120_000L),
            minSpeechMs = minSpeechMs.coerceIn(60L, 2_000L),
            minSilenceGapMs = minSilenceGapMs.coerceIn(60L, 2_000L),
            ownerPriorityBoost = ownerPriorityBoost.coerceIn(0.0f, 1.0f),
            knownSpeakerBoost = knownSpeakerBoost.coerceIn(0.0f, 1.0f),
            overlapPenalty = overlapPenalty.coerceIn(0.0f, 1.0f),
            bargeInSensitivity = bargeInSensitivity.coerceIn(0.0f, 1.0f),
            emotionalPauseHoldMs = emotionalPauseHoldMs.coerceIn(80L, 2_500L),
            duplicatePartialPenalty = duplicatePartialPenalty.coerceIn(0.0f, 1.0f),
        )
    }

    fun toDebugMap(): Map<String, Any> {
        val normalized = normalized()
        return linkedMapOf(
            "sampleRate" to normalized.sampleRate,
            "chunkSize" to normalized.chunkSize,
            "beamSize" to normalized.beamSize,
            "endpointingMs" to normalized.endpointingMs,
            "stabilizeTokenWindow" to normalized.stabilizeTokenWindow,
            "partialConfidenceFloor" to normalized.partialConfidenceFloor,
            "maxSessionMs" to normalized.maxSessionMs,
            "minSpeechMs" to normalized.minSpeechMs,
            "minSilenceGapMs" to normalized.minSilenceGapMs,
            "ownerPriorityBoost" to normalized.ownerPriorityBoost,
            "knownSpeakerBoost" to normalized.knownSpeakerBoost,
            "overlapPenalty" to normalized.overlapPenalty,
            "bargeInSensitivity" to normalized.bargeInSensitivity,
            "emotionalPauseHoldMs" to normalized.emotionalPauseHoldMs,
            "duplicatePartialPenalty" to normalized.duplicatePartialPenalty,
        )
    }

    companion object {
        fun fromMap(raw: Map<String, Any?>?): NovaStreamingAsrConfig {
            if (raw == null) return NovaStreamingAsrConfig().normalized()
            return NovaStreamingAsrConfig(
                sampleRate = (raw["sampleRate"] as? Number)?.toInt() ?: 16000,
                chunkSize = (raw["chunkSize"] as? Number)?.toInt() ?: 1600,
                beamSize = (raw["beamSize"] as? Number)?.toInt() ?: 4,
                endpointingMs = (raw["endpointingMs"] as? Number)?.toLong() ?: 1100L,
                stabilizeTokenWindow = (raw["stabilizeTokenWindow"] as? Number)?.toInt() ?: 4,
                partialConfidenceFloor = (raw["partialConfidenceFloor"] as? Number)?.toFloat() ?: 0.35f,
                maxSessionMs = (raw["maxSessionMs"] as? Number)?.toLong() ?: 45_000L,
                minSpeechMs = (raw["minSpeechMs"] as? Number)?.toLong() ?: 180L,
                minSilenceGapMs = (raw["minSilenceGapMs"] as? Number)?.toLong() ?: 220L,
                ownerPriorityBoost = (raw["ownerPriorityBoost"] as? Number)?.toFloat() ?: 0.18f,
                knownSpeakerBoost = (raw["knownSpeakerBoost"] as? Number)?.toFloat() ?: 0.10f,
                overlapPenalty = (raw["overlapPenalty"] as? Number)?.toFloat() ?: 0.14f,
                bargeInSensitivity = (raw["bargeInSensitivity"] as? Number)?.toFloat() ?: 0.58f,
                emotionalPauseHoldMs = (raw["emotionalPauseHoldMs"] as? Number)?.toLong() ?: 420L,
                duplicatePartialPenalty = (raw["duplicatePartialPenalty"] as? Number)?.toFloat() ?: 0.12f,
            ).normalized()
        }
    }
}
