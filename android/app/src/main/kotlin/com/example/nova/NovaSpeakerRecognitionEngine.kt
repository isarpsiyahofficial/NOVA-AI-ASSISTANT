package com.example.nova

data class NovaSpeakerEnrollResult(
    val success: Boolean,
    val voiceId: String,
    val displayName: String,
    val message: String,
    val embeddingSize: Int,
)

data class NovaSpeakerIdentifyResult(
    val success: Boolean,
    val matched: Boolean,
    val voiceId: String,
    val displayName: String,
    val similarity: Float,
    val message: String,
    val embeddingSize: Int,
)

class NovaSpeakerRecognitionEngine(
    private val voiceprintStore: NovaVoiceprintStore,
    private val embeddingProvider: EmbeddingProvider,
) {

    interface EmbeddingProvider {
        fun isReady(): Boolean
        fun warmup(): Boolean

        fun extractEmbeddingFromFile(
            audioPath: String,
        ): FloatArray?

        fun extractEmbeddingFromBytes(
            audioBytes: ByteArray,
            sampleRate: Int,
        ): FloatArray?
    }

    fun isReady(): Boolean {
        return embeddingProvider.isReady()
    }

    fun warmup(): Boolean {
        return embeddingProvider.warmup()
    }

    fun enrollFromFile(
        voiceId: String,
        displayName: String,
        audioPath: String,
    ): NovaSpeakerEnrollResult {
        val normalizedVoiceId = voiceId.trim()
        val normalizedDisplayName = displayName.trim()
        val normalizedAudioPath = audioPath.trim()

        if (normalizedVoiceId.isEmpty()) {
            return NovaSpeakerEnrollResult(
                success = false,
                voiceId = "",
                displayName = normalizedDisplayName,
                message = "Ses kimliği boş olamaz.",
                embeddingSize = 0,
            )
        }

        if (normalizedDisplayName.isEmpty()) {
            return NovaSpeakerEnrollResult(
                success = false,
                voiceId = normalizedVoiceId,
                displayName = "",
                message = "Görünen ad boş olamaz.",
                embeddingSize = 0,
            )
        }

        if (normalizedAudioPath.isEmpty()) {
            return NovaSpeakerEnrollResult(
                success = false,
                voiceId = normalizedVoiceId,
                displayName = normalizedDisplayName,
                message = "Referans ses dosyası yolu boş olamaz.",
                embeddingSize = 0,
            )
        }

        if (!embeddingProvider.isReady()) {
            val warmed = embeddingProvider.warmup()
            if (!warmed) {
                return NovaSpeakerEnrollResult(
                    success = false,
                    voiceId = normalizedVoiceId,
                    displayName = normalizedDisplayName,
                    message = "Speaker motoru hazırlanamadı.",
                    embeddingSize = 0,
                )
            }
        }

        val embedding = try {
            embeddingProvider.extractEmbeddingFromFile(normalizedAudioPath)
        } catch (_: Throwable) {
            null
        }

        if (embedding == null || embedding.isEmpty()) {
            return NovaSpeakerEnrollResult(
                success = false,
                voiceId = normalizedVoiceId,
                displayName = normalizedDisplayName,
                message = "Referans sesten embedding üretilemedi.",
                embeddingSize = 0,
            )
        }

        val stored = voiceprintStore.upsert(
            voiceId = normalizedVoiceId,
            displayName = normalizedDisplayName,
            embedding = embedding,
        )

        if (!stored) {
            return NovaSpeakerEnrollResult(
                success = false,
                voiceId = normalizedVoiceId,
                displayName = normalizedDisplayName,
                message = "Voiceprint kaydedilemedi.",
                embeddingSize = embedding.size,
            )
        }

        return NovaSpeakerEnrollResult(
            success = true,
            voiceId = normalizedVoiceId,
            displayName = normalizedDisplayName,
            message = "Voiceprint başarıyla kaydedildi.",
            embeddingSize = embedding.size,
        )
    }

    fun enrollFromBytes(
        voiceId: String,
        displayName: String,
        audioBytes: ByteArray,
        sampleRate: Int,
    ): NovaSpeakerEnrollResult {
        val normalizedVoiceId = voiceId.trim()
        val normalizedDisplayName = displayName.trim()

        if (normalizedVoiceId.isEmpty()) {
            return NovaSpeakerEnrollResult(
                success = false,
                voiceId = "",
                displayName = normalizedDisplayName,
                message = "Ses kimliği boş olamaz.",
                embeddingSize = 0,
            )
        }

        if (normalizedDisplayName.isEmpty()) {
            return NovaSpeakerEnrollResult(
                success = false,
                voiceId = normalizedVoiceId,
                displayName = "",
                message = "Görünen ad boş olamaz.",
                embeddingSize = 0,
            )
        }

        if (audioBytes.isEmpty()) {
            return NovaSpeakerEnrollResult(
                success = false,
                voiceId = normalizedVoiceId,
                displayName = normalizedDisplayName,
                message = "Ses verisi boş olamaz.",
                embeddingSize = 0,
            )
        }

        if (sampleRate <= 0) {
            return NovaSpeakerEnrollResult(
                success = false,
                voiceId = normalizedVoiceId,
                displayName = normalizedDisplayName,
                message = "Geçersiz sample rate.",
                embeddingSize = 0,
            )
        }

        if (!embeddingProvider.isReady()) {
            val warmed = embeddingProvider.warmup()
            if (!warmed) {
                return NovaSpeakerEnrollResult(
                    success = false,
                    voiceId = normalizedVoiceId,
                    displayName = normalizedDisplayName,
                    message = "Speaker motoru hazırlanamadı.",
                    embeddingSize = 0,
                )
            }
        }

        val embedding = try {
            embeddingProvider.extractEmbeddingFromBytes(
                audioBytes = audioBytes,
                sampleRate = sampleRate,
            )
        } catch (_: Throwable) {
            null
        }

        if (embedding == null || embedding.isEmpty()) {
            return NovaSpeakerEnrollResult(
                success = false,
                voiceId = normalizedVoiceId,
                displayName = normalizedDisplayName,
                message = "Ses verisinden embedding üretilemedi.",
                embeddingSize = 0,
            )
        }

        val stored = voiceprintStore.upsert(
            voiceId = normalizedVoiceId,
            displayName = normalizedDisplayName,
            embedding = embedding,
        )

        if (!stored) {
            return NovaSpeakerEnrollResult(
                success = false,
                voiceId = normalizedVoiceId,
                displayName = normalizedDisplayName,
                message = "Voiceprint kaydedilemedi.",
                embeddingSize = embedding.size,
            )
        }

        return NovaSpeakerEnrollResult(
            success = true,
            voiceId = normalizedVoiceId,
            displayName = normalizedDisplayName,
            message = "Voiceprint başarıyla kaydedildi.",
            embeddingSize = embedding.size,
        )
    }

    fun identifyFromFile(
        audioPath: String,
        minSimilarity: Float = 0.64f,
    ): NovaSpeakerIdentifyResult {
        val normalizedAudioPath = audioPath.trim()

        if (normalizedAudioPath.isEmpty()) {
            return NovaSpeakerIdentifyResult(
                success = false,
                matched = false,
                voiceId = "",
                displayName = "",
                similarity = 0f,
                message = "Ses dosyası yolu boş olamaz.",
                embeddingSize = 0,
            )
        }

        if (!embeddingProvider.isReady()) {
            val warmed = embeddingProvider.warmup()
            if (!warmed) {
                return NovaSpeakerIdentifyResult(
                    success = false,
                    matched = false,
                    voiceId = "",
                    displayName = "",
                    similarity = 0f,
                    message = "Speaker motoru hazırlanamadı.",
                    embeddingSize = 0,
                )
            }
        }

        val embedding = try {
            embeddingProvider.extractEmbeddingFromFile(normalizedAudioPath)
        } catch (_: Throwable) {
            null
        }

        if (embedding == null || embedding.isEmpty()) {
            return NovaSpeakerIdentifyResult(
                success = false,
                matched = false,
                voiceId = "",
                displayName = "",
                similarity = 0f,
                message = "Ses dosyasından embedding üretilemedi.",
                embeddingSize = 0,
            )
        }

        val match = voiceprintStore.findBestMatch(
            embedding = embedding,
            minSimilarity = minSimilarity,
        )

        if (match == null) {
            return NovaSpeakerIdentifyResult(
                success = true,
                matched = false,
                voiceId = "",
                displayName = "",
                similarity = 0f,
                message = "Eşleşen kayıtlı ses bulunamadı.",
                embeddingSize = embedding.size,
            )
        }

        return NovaSpeakerIdentifyResult(
            success = true,
            matched = true,
            voiceId = match.voiceId,
            displayName = match.displayName,
            similarity = match.similarity,
            message = "Ses eşleşmesi bulundu.",
            embeddingSize = embedding.size,
        )
    }

    fun identifyFromBytes(
        audioBytes: ByteArray,
        sampleRate: Int,
        minSimilarity: Float = 0.64f,
    ): NovaSpeakerIdentifyResult {
        if (audioBytes.isEmpty()) {
            return NovaSpeakerIdentifyResult(
                success = false,
                matched = false,
                voiceId = "",
                displayName = "",
                similarity = 0f,
                message = "Ses verisi boş olamaz.",
                embeddingSize = 0,
            )
        }

        if (sampleRate <= 0) {
            return NovaSpeakerIdentifyResult(
                success = false,
                matched = false,
                voiceId = "",
                displayName = "",
                similarity = 0f,
                message = "Geçersiz sample rate.",
                embeddingSize = 0,
            )
        }

        if (!embeddingProvider.isReady()) {
            val warmed = embeddingProvider.warmup()
            if (!warmed) {
                return NovaSpeakerIdentifyResult(
                    success = false,
                    matched = false,
                    voiceId = "",
                    displayName = "",
                    similarity = 0f,
                    message = "Speaker motoru hazırlanamadı.",
                    embeddingSize = 0,
                )
            }
        }

        val embedding = try {
            embeddingProvider.extractEmbeddingFromBytes(
                audioBytes = audioBytes,
                sampleRate = sampleRate,
            )
        } catch (_: Throwable) {
            null
        }

        if (embedding == null || embedding.isEmpty()) {
            return NovaSpeakerIdentifyResult(
                success = false,
                matched = false,
                voiceId = "",
                displayName = "",
                similarity = 0f,
                message = "Ses verisinden embedding üretilemedi.",
                embeddingSize = 0,
            )
        }

        val match = voiceprintStore.findBestMatch(
            embedding = embedding,
            minSimilarity = minSimilarity,
        )

        if (match == null) {
            return NovaSpeakerIdentifyResult(
                success = true,
                matched = false,
                voiceId = "",
                displayName = "",
                similarity = 0f,
                message = "Eşleşen kayıtlı ses bulunamadı.",
                embeddingSize = embedding.size,
            )
        }

        return NovaSpeakerIdentifyResult(
            success = true,
            matched = true,
            voiceId = match.voiceId,
            displayName = match.displayName,
            similarity = match.similarity,
            message = "Ses eşleşmesi bulundu.",
            embeddingSize = embedding.size,
        )
    }

    fun removeVoiceprint(
        voiceId: String,
    ): Boolean {
        return voiceprintStore.remove(voiceId)
    }

    fun clearAllVoiceprints(): Boolean {
        return voiceprintStore.clearAll()
    }

    fun getRegisteredVoiceCount(): Int {
        return voiceprintStore.getAll().size
    }
}

data class NovaCrowdSpeakerDecision(
    val matchedVoiceId: String,
    val matchedDisplayName: String,
    val similarity: Float,
    val authorityHint: String,
)

class NovaCrowdSpeakerDecisionEngine {
    fun chooseBest(results: List<NovaSpeakerIdentifyResult>): NovaCrowdSpeakerDecision? {
        if (results.isEmpty()) return null
        val sorted = results.sortedByDescending { it.similarity }
        val best = sorted.first()
        val authorityHint = when {
            best.displayName.contains("owner", ignoreCase = true) -> "owner"
            best.displayName.contains("yetkili", ignoreCase = true) -> "authorized"
            else -> "recognized_or_guest"
        }
        return NovaCrowdSpeakerDecision(
            matchedVoiceId = best.voiceId,
            matchedDisplayName = best.displayName,
            similarity = best.similarity,
            authorityHint = authorityHint,
        )
    }
}


object NovaSpeakerRecognitionRules {
    fun render(): String {
        return buildString {
            append("SPEAKER RULES\n")
            append("- owner sesi ve yetkili sesler kalabalıkta ayrıştırılmalı\n")
            append("- similarity düşükse sahte güven kurulmaz\n")
            append("- tanınmış ama yetkisiz kişiler sohbet edebilir, komut veremez\n")
            append("- aynı anda çok konuşmacıda en yüksek benzerlik tek başına yetki sayılmaz")
        }
    }
}


data class NovaSpeakerConfidenceBand(
    val similarity: Float,
    val label: String,
)

object NovaSpeakerConfidenceBands {
    fun classify(similarity: Float): NovaSpeakerConfidenceBand {
        val label = when {
            similarity >= 0.88f -> "very_strong"
            similarity >= 0.76f -> "strong"
            similarity >= 0.62f -> "borderline"
            else -> "weak"
        }
        return NovaSpeakerConfidenceBand(similarity, label)
    }
}


data class NovaSpeakerAuthorityHint(
    val displayName: String,
    val suggestedAuthority: String,
)

object NovaSpeakerAuthorityHints {
    fun infer(displayName: String): NovaSpeakerAuthorityHint {
        val normalized = displayName.lowercase()
        val authority = when {
            normalized.contains("owner") || normalized.contains("patron") -> "owner"
            normalized.contains("yetkili") -> "authorized"
            else -> "chat_only"
        }
        return NovaSpeakerAuthorityHint(displayName, authority)
    }
}
