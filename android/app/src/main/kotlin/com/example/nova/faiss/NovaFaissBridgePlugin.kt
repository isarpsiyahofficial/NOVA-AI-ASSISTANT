package com.example.nova.faiss

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.min

class NovaFaissBridgePlugin private constructor(
    private val context: Context,
    messenger: io.flutter.plugin.common.BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL)
    private var currentHandle: Long = 0L
    private var currentDimension: Int = DEFAULT_DIMENSION
    private var vectorCount: Int = 0

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(safeIsAvailable())
            "createIndex" -> {
                val dimension = call.argument<Int>("dimension") ?: DEFAULT_DIMENSION
                val useCosine = call.argument<Boolean>("useCosine") ?: true
                currentHandle = safeCreateIndex(dimension, useCosine)
                currentDimension = dimension
                vectorCount = 0
                result.success(mapOf(
                    "success" to (currentHandle != 0L),
                    "handle" to currentHandle,
                    "dimension" to currentDimension,
                    "backend" to if (currentHandle != 0L) "faiss" else "unavailable"
                ))
            }
            "resetIndex" -> {
                if (currentHandle != 0L) {
                    safeReset(currentHandle)
                }
                vectorCount = 0
                result.success(true)
            }
            "replaceAll" -> {
                if (currentHandle == 0L) {
                    result.success(mapOf("success" to false, "message" to "FAISS index hazır değil"))
                    return
                }
                safeReset(currentHandle)
                vectorCount = 0
                val items = call.argument<List<Map<String, Any?>>>("items") ?: emptyList()
                for (item in items) {
                    val idNumber = when (val raw = item["id"]) {
                        is Number -> raw.toLong()
                        is String -> raw.toLongOrNull() ?: continue
                        else -> continue
                    }
                    val vector = toFloatArray(item["vector"]) ?: continue
                    if (vector.size != currentDimension) continue
                    val added = safeAdd(currentHandle, idNumber, vector)
                    if (added) vectorCount += 1
                }
                result.success(mapOf("success" to true, "count" to vectorCount, "dimension" to currentDimension))
            }
            "search" -> {
                if (currentHandle == 0L) {
                    result.success(emptyList<Map<String, Any?>>())
                    return
                }
                val query = toFloatArray(call.argument<Any>("query"))
                val k = call.argument<Int>("k") ?: 4
                if (query == null || query.size != currentDimension || k <= 0) {
                    result.success(emptyList<Map<String, Any?>>())
                    return
                }
                val ids = safeSearchIds(currentHandle, query, k)
                val scores = safeSearchScores(currentHandle, query, k)
                val out = ArrayList<Map<String, Any?>>()
                val limit = min(ids.size, scores.size)
                for (i in 0 until limit) {
                    if (ids[i] <= 0L) continue
                    out.add(mapOf("id" to ids[i], "score" to scores[i]))
                }
                result.success(out)
            }
            "stats" -> result.success(mapOf(
                "available" to safeIsAvailable(),
                "dimension" to currentDimension,
                "count" to vectorCount,
                "backend" to if (safeIsAvailable()) "faiss" else "unavailable"
            ))
            else -> result.notImplemented()
        }
    }

    private fun safeIsAvailable(): Boolean = try {
        NovaFaissNativeBridge.nativeIsAvailable()
    } catch (_: Throwable) {
        false
    }

    private fun safeCreateIndex(dimension: Int, useCosine: Boolean): Long = try {
        NovaFaissNativeBridge.nativeCreateIndex(dimension, useCosine)
    } catch (_: Throwable) {
        0L
    }

    private fun safeReset(handle: Long) {
        try {
            NovaFaissNativeBridge.nativeReset(handle)
        } catch (_: Throwable) {
            // Native FAISS is optional at runtime; failures must not crash Nova.
        }
    }

    private fun safeAdd(handle: Long, id: Long, vector: FloatArray): Boolean = try {
        NovaFaissNativeBridge.nativeAdd(handle, id, vector)
    } catch (_: Throwable) {
        false
    }

    private fun safeSearchIds(handle: Long, query: FloatArray, k: Int): LongArray = try {
        NovaFaissNativeBridge.nativeSearchIds(handle, query, k)
    } catch (_: Throwable) {
        LongArray(0)
    }

    private fun safeSearchScores(handle: Long, query: FloatArray, k: Int): FloatArray = try {
        NovaFaissNativeBridge.nativeSearchScores(handle, query, k)
    } catch (_: Throwable) {
        FloatArray(0)
    }

    private fun toFloatArray(raw: Any?): FloatArray? {
        val list = raw as? List<*> ?: return null
        val out = FloatArray(list.size)
        for (i in list.indices) {
            val value = list[i]
            out[i] = when (value) {
                is Number -> value.toFloat()
                else -> return null
            }
        }
        return out
    }

    companion object {
        private const val CHANNEL = "nova/faiss_bridge"
        private const val DEFAULT_DIMENSION = 128

        fun register(flutterEngine: FlutterEngine, context: Context) {
            NovaFaissBridgePlugin(
                context = context.applicationContext,
                messenger = flutterEngine.dartExecutor.binaryMessenger,
            )
        }
    }
}
