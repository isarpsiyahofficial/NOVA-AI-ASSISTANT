package com.example.nova.asr

data class NovaStreamingAsrResult(
    val text: String,
    val isFinal: Boolean,
    val confidence: Float,
    val segmentId: Int,
    val startMs: Int,
    val endMs: Int,
    val locale: String = "tr-TR",
)
