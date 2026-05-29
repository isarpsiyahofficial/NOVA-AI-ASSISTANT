package com.example.nova.faiss

object NovaFaissNativeBridge {
    external fun nativeIsAvailable(): Boolean
    external fun nativeCreateIndex(dimension: Int, useCosine: Boolean): Long
    external fun nativeReset(handle: Long)
    external fun nativeAdd(handle: Long, id: Long, vector: FloatArray): Boolean
    external fun nativeSearchIds(handle: Long, query: FloatArray, k: Int): LongArray
    external fun nativeSearchScores(handle: Long, query: FloatArray, k: Int): FloatArray
}
