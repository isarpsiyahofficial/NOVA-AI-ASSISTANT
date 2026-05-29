package com.example.nova.asr

class NovaStreamingAsrSession {
    @Volatile var running: Boolean = false
        private set
    @Volatile var paused: Boolean = false
        private set
    @Volatile var segmentId: Int = 0
        private set

    fun start() {
        running = true
        paused = false
    }

    fun pause() {
        if (running) paused = true
    }

    fun resume() {
        if (running) paused = false
    }

    fun finalizeSegment() {
        segmentId += 1
    }

    fun stop() {
        running = false
        paused = false
    }
}
