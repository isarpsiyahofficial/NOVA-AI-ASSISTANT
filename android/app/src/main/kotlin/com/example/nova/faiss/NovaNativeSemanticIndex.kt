package com.example.nova.faiss

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import kotlin.math.sqrt

internal class NovaNativeSemanticIndex(private val context: Context) {
    private data class Entry(
        val id: String,
        val content: String,
        val type: String,
        val createdAt: String,
        val expiresAt: String?,
        val vector: FloatArray,
    )

    private data class IndexState(
        val name: String,
        val dimension: Int,
        val entries: MutableList<Entry>,
    )

    private val states = mutableMapOf<String, IndexState>()

    fun ensureIndex(indexName: String, dimension: Int) {
        if (states[indexName] != null) return
        val loaded = load(indexName)
        states[indexName] = loaded ?: IndexState(indexName, dimension, mutableListOf())
    }

    fun replaceAll(indexName: String, dimension: Int, records: List<Map<String, Any?>>) {
        val entries = mutableListOf<Entry>()
        for (record in records) {
            val metadata = record["metadata"] as? Map<*, *>
            val embeddingRaw = metadata?.get("embedding") as? List<*>
            val vector = embeddingRaw
                ?.mapNotNull { (it as? Number)?.toFloat() }
                ?.toFloatArray()
                ?: FloatArray(dimension)
            entries += Entry(
                id = record["id"]?.toString().orEmpty(),
                content = record["content"]?.toString().orEmpty(),
                type = record["type"]?.toString().orEmpty().ifBlank { "contextual" },
                createdAt = record["createdAt"]?.toString().orEmpty(),
                expiresAt = record["expiresAt"]?.toString(),
                vector = normalize(vector, dimension),
            )
        }
        val state = IndexState(indexName, dimension, entries)
        states[indexName] = state
        persist(state)
    }

    fun search(indexName: String, queryVector: List<Double>, topK: Int, minScore: Double): List<Map<String, Any?>> {
        val state = states[indexName] ?: return emptyList()
        val query = normalize(queryVector.map { it.toFloat() }.toFloatArray(), state.dimension)
        val nowIso = System.currentTimeMillis()

        return state.entries
            .asSequence()
            .filter { entry ->
                val expiresAt = entry.expiresAt ?: return@filter true
                runCatching { java.time.Instant.parse(expiresAt).toEpochMilli() > nowIso }.getOrDefault(true)
            }
            .map { entry -> entry to cosine(query, entry.vector) }
            .filter { it.second >= minScore }
            .sortedByDescending { it.second }
            .take(topK)
            .map { (entry, score) ->
                mapOf(
                    "record" to mapOf(
                        "id" to entry.id,
                        "content" to entry.content,
                        "type" to entry.type,
                        "createdAt" to entry.createdAt,
                        "expiresAt" to entry.expiresAt,
                        "metadata" to emptyMap<String, Any>(),
                    ),
                    "score" to score,
                    "backend" to "native_semantic",
                )
            }
            .toList()
    }

    fun stats(indexName: String): Map<String, Any?> {
        val state = states[indexName]
        return mapOf(
            "indexName" to indexName,
            "ready" to (state != null),
            "dimension" to (state?.dimension ?: 0),
            "size" to (state?.entries?.size ?: 0),
            "backend" to "native_semantic",
            "faissNativeLoaded" to false,
        )
    }

    private fun normalize(source: FloatArray, dimension: Int): FloatArray {
        val vector = if (source.size == dimension) source.copyOf() else FloatArray(dimension).also { target ->
            val limit = minOf(source.size, dimension)
            for (i in 0 until limit) {
                target[i] = source[i]
            }
        }
        var sum = 0f
        for (value in vector) {
            sum += value * value
        }
        if (sum <= 0f) return vector
        val norm = sqrt(sum)
        for (i in vector.indices) {
            vector[i] = vector[i] / norm
        }
        return vector
    }

    private fun cosine(left: FloatArray, right: FloatArray): Double {
        val limit = minOf(left.size, right.size)
        var sum = 0.0
        for (i in 0 until limit) {
            sum += left[i] * right[i]
        }
        return sum
    }

    private fun persist(state: IndexState) {
        val file = fileFor(state.name)
        val root = JSONObject()
        root.put("name", state.name)
        root.put("dimension", state.dimension)
        val entries = JSONArray()
        for (entry in state.entries) {
            val item = JSONObject()
            item.put("id", entry.id)
            item.put("content", entry.content)
            item.put("type", entry.type)
            item.put("createdAt", entry.createdAt)
            item.put("expiresAt", entry.expiresAt)
            val vector = JSONArray()
            for (value in entry.vector) {
                vector.put(value.toDouble())
            }
            item.put("vector", vector)
            entries.put(item)
        }
        root.put("entries", entries)
        file.parentFile?.mkdirs()
        file.writeText(root.toString())
    }

    private fun load(indexName: String): IndexState? {
        val file = fileFor(indexName)
        if (!file.exists()) return null
        return runCatching {
            val root = JSONObject(file.readText())
            val dimension = root.optInt("dimension", 96)
            val entriesRaw = root.optJSONArray("entries") ?: JSONArray()
            val entries = mutableListOf<Entry>()
            for (i in 0 until entriesRaw.length()) {
                val item = entriesRaw.optJSONObject(i) ?: continue
                val vectorRaw = item.optJSONArray("vector") ?: JSONArray()
                val vector = FloatArray(dimension)
                for (j in 0 until minOf(vectorRaw.length(), dimension)) {
                    vector[j] = vectorRaw.optDouble(j, 0.0).toFloat()
                }
                entries += Entry(
                    id = item.optString("id"),
                    content = item.optString("content"),
                    type = item.optString("type", "contextual"),
                    createdAt = item.optString("createdAt"),
                    expiresAt = item.optString("expiresAt").ifBlank { null },
                    vector = normalize(vector, dimension),
                )
            }
            IndexState(indexName, dimension, entries)
        }.getOrNull()
    }

    private fun fileFor(indexName: String): File {
        val safe = indexName.replace(Regex("[^a-zA-Z0-9._-]"), "_")
        return File(context.filesDir, "nova/faiss_bridge/$safe.json")
    }
}
