package com.example.nova

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import kotlin.math.sqrt

data class NovaStoredVoiceprint(
    val voiceId: String,
    val displayName: String,
    val embedding: FloatArray,
    val createdAtMillis: Long,
    val updatedAtMillis: Long,
)

class NovaVoiceprintStore(
    private val context: Context
) {

    private val lock = Any()

    private val storeDir: File by lazy {
        File(context.filesDir, "nova_voiceprints").apply {
            if (!exists()) {
                mkdirs()
            }
        }
    }

    private val storeFile: File by lazy {
        File(storeDir, "voiceprints.json")
    }

    fun getAll(): List<NovaStoredVoiceprint> {
        synchronized(lock) {
            return loadAllUnsafe()
        }
    }

    fun findByVoiceId(voiceId: String): NovaStoredVoiceprint? {
        val normalized = voiceId.trim()
        if (normalized.isEmpty()) return null

        synchronized(lock) {
            return loadAllUnsafe().firstOrNull { it.voiceId == normalized }
        }
    }

    fun upsert(
        voiceId: String,
        displayName: String,
        embedding: FloatArray
    ): Boolean {
        val normalizedVoiceId = voiceId.trim()
        val normalizedDisplayName = displayName.trim()

        if (normalizedVoiceId.isEmpty()) return false
        if (normalizedDisplayName.isEmpty()) return false
        if (embedding.isEmpty()) return false

        synchronized(lock) {
            val now = System.currentTimeMillis()
            val current = loadAllUnsafe().toMutableList()

            val existingIndex = current.indexOfFirst { it.voiceId == normalizedVoiceId }
            if (existingIndex >= 0) {
                val previous = current[existingIndex]
                current[existingIndex] = previous.copy(
                    displayName = normalizedDisplayName,
                    embedding = embedding.copyOf(),
                    updatedAtMillis = now,
                )
            } else {
                current.add(
                    NovaStoredVoiceprint(
                        voiceId = normalizedVoiceId,
                        displayName = normalizedDisplayName,
                        embedding = embedding.copyOf(),
                        createdAtMillis = now,
                        updatedAtMillis = now,
                    )
                )
            }

            return saveAllUnsafe(current)
        }
    }

    fun remove(voiceId: String): Boolean {
        val normalized = voiceId.trim()
        if (normalized.isEmpty()) return false

        synchronized(lock) {
            val current = loadAllUnsafe().toMutableList()
            val removed = current.removeAll { it.voiceId == normalized }
            if (!removed) return false
            return saveAllUnsafe(current)
        }
    }

    fun clearAll(): Boolean {
        synchronized(lock) {
            return try {
                if (storeFile.exists()) {
                    storeFile.delete()
                } else {
                    true
                }
            } catch (_: Throwable) {
                false
            }
        }
    }

    fun findBestMatch(
        embedding: FloatArray,
        minSimilarity: Float = 0.64f
    ): MatchResult? {
        if (embedding.isEmpty()) return null

        synchronized(lock) {
            val all = loadAllUnsafe()
            if (all.isEmpty()) return null

            var best: NovaStoredVoiceprint? = null
            var bestScore = -1f

            for (item in all) {
                val score = cosineSimilarity(
                    embedding,
                    item.embedding
                )
                if (score > bestScore) {
                    bestScore = score
                    best = item
                }
            }

            if (best == null) return null
            if (bestScore < minSimilarity) return null

            return MatchResult(
                voiceId = best.voiceId,
                displayName = best.displayName,
                similarity = bestScore,
            )
        }
    }

    private fun loadAllUnsafe(): List<NovaStoredVoiceprint> {
        if (!storeFile.exists()) {
            return emptyList()
        }

        return try {
            val raw = storeFile.readText(Charsets.UTF_8)
            if (raw.isBlank()) {
                return emptyList()
            }

            val array = JSONArray(raw)
            val results = ArrayList<NovaStoredVoiceprint>(array.length())

            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue

                val voiceId = obj.optString("voiceId").trim()
                val displayName = obj.optString("displayName").trim()
                val createdAtMillis = obj.optLong("createdAtMillis", 0L)
                val updatedAtMillis = obj.optLong("updatedAtMillis", createdAtMillis)

                if (voiceId.isEmpty() || displayName.isEmpty()) {
                    continue
                }

                val embeddingArray = obj.optJSONArray("embedding") ?: continue
                val embedding = FloatArray(embeddingArray.length())

                for (j in 0 until embeddingArray.length()) {
                    embedding[j] = embeddingArray.optDouble(j, 0.0).toFloat()
                }

                if (embedding.isEmpty()) {
                    continue
                }

                results.add(
                    NovaStoredVoiceprint(
                        voiceId = voiceId,
                        displayName = displayName,
                        embedding = embedding,
                        createdAtMillis = createdAtMillis,
                        updatedAtMillis = updatedAtMillis,
                    )
                )
            }

            results
        } catch (_: Throwable) {
            emptyList()
        }
    }

    private fun saveAllUnsafe(items: List<NovaStoredVoiceprint>): Boolean {
        return try {
            if (!storeDir.exists()) {
                storeDir.mkdirs()
            }

            val array = JSONArray()

            for (item in items) {
                val obj = JSONObject()
                obj.put("voiceId", item.voiceId)
                obj.put("displayName", item.displayName)
                obj.put("createdAtMillis", item.createdAtMillis)
                obj.put("updatedAtMillis", item.updatedAtMillis)

                val embeddingArray = JSONArray()
                item.embedding.forEach { embeddingArray.put(it.toDouble()) }
                obj.put("embedding", embeddingArray)

                array.put(obj)
            }

            storeFile.writeText(array.toString(), Charsets.UTF_8)
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun cosineSimilarity(
        a: FloatArray,
        b: FloatArray
    ): Float {
        if (a.isEmpty() || b.isEmpty()) return -1f
        if (a.size != b.size) return -1f

        var dot = 0.0
        var normA = 0.0
        var normB = 0.0

        for (i in a.indices) {
            val av = a[i].toDouble()
            val bv = b[i].toDouble()

            dot += av * bv
            normA += av * av
            normB += bv * bv
        }

        if (normA <= 0.0 || normB <= 0.0) {
            return -1f
        }

        return (dot / (sqrt(normA) * sqrt(normB))).toFloat()
    }

    data class MatchResult(
        val voiceId: String,
        val displayName: String,
        val similarity: Float,
    )
}