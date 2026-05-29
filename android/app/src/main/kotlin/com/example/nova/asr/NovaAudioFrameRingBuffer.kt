package com.example.nova.asr

class NovaAudioFrameRingBuffer(private val capacity: Int = 32) {
    private val frames = ArrayDeque<ShortArray>()
    @Volatile var droppedFrames: Int = 0
        private set

    @Synchronized
    fun push(frame: ShortArray) {
        if (frames.size >= capacity) {
            frames.removeFirstOrNull()
            droppedFrames += 1
        }
        frames.addLast(frame.copyOf())
    }

    @Synchronized
    fun pop(): ShortArray? = if (frames.isEmpty()) null else frames.removeFirst()

    @Synchronized
    fun clear() {
        frames.clear()
        droppedFrames = 0
    }
}
