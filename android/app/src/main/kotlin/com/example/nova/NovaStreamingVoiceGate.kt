package com.example.nova

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.os.SystemClock
import androidx.core.content.ContextCompat
import kotlin.concurrent.thread
import kotlin.math.min
import kotlin.math.sqrt

object NovaStreamingVoiceGate {
    @Volatile private var running = false
    @Volatile private var speechActive = false
    @Volatile private var lastSpeechAt = 0L
    @Volatile private var lastSampleAt = 0L
    @Volatile private var avgRms = 0.0
    @Volatile private var peakRms = 0.0
    @Volatile private var baselineRms = 260.0
    @Volatile private var thresholdRms = 520.0
    @Volatile private var lastError = ""
    @Volatile private var speechOpenCounter = 0
    @Volatile private var speechCloseCounter = 0

    private var worker: Thread? = null
    private var audioRecord: AudioRecord? = null
    private val pcmRingBuffer = ShortArray(SAMPLE_RATE * 24)
    @Volatile private var pcmWriteIndex = 0
    @Volatile private var pcmBufferedSamples = 0

    private const val SAMPLE_RATE = 16000
    private const val CHANNEL_MASK = AudioFormat.CHANNEL_IN_MONO
    private const val ENCODING = AudioFormat.ENCODING_PCM_16BIT

    fun start(context: Context): Map<String, Any> {
        synchronized(this) {
            if (!hasRecordPermission(context)) {
                lastError = "Mikrofon izni eksik."
                return stateMap(success = false, message = lastError)
            }
            if (running) {
                return stateMap(success = true, message = "Streaming ses kapısı zaten çalışıyor.")
            }
            val minBuffer = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_MASK, ENCODING)
            if (minBuffer <= 0) {
                lastError = "AudioRecord buffer boyutu alınamadı."
                return stateMap(success = false, message = lastError)
            }
            val targetBuffer = (minBuffer * 6).coerceAtLeast(SAMPLE_RATE * 2) // GEMMA6644: TECNO/ALSA read timeout ve frame drop azaltma
            val record = try {
                AudioRecord(
                    MediaRecorder.AudioSource.VOICE_RECOGNITION,
                    SAMPLE_RATE,
                    CHANNEL_MASK,
                    ENCODING,
                    targetBuffer,
                )
            } catch (t: Throwable) {
                lastError = t.message ?: "AudioRecord oluşturulamadı."
                null
            }
            if (record == null || record.state != AudioRecord.STATE_INITIALIZED) {
                try { record?.release() } catch (_: Throwable) {}
                lastError = if (lastError.isBlank()) "AudioRecord başlatılamadı." else lastError
                return stateMap(success = false, message = lastError)
            }
            audioRecord = record
            running = true
            speechActive = false
            lastSpeechAt = 0L
            lastSampleAt = 0L
            avgRms = 0.0
            peakRms = 0.0
            baselineRms = 260.0
            thresholdRms = 520.0
            lastError = ""
            speechOpenCounter = 0
            speechCloseCounter = 0
            clearPcmBufferLocked()
            worker = thread(start = true, isDaemon = true, name = "NovaStreamingVoiceGate") {
                runLoop(record, targetBuffer)
            }
            return stateMap(success = true, message = "Streaming ses kapısı başlatıldı.")
        }
    }

    fun stop(): Map<String, Any> {
        synchronized(this) {
            running = false
            val current = audioRecord
            audioRecord = null
            try { current?.stop() } catch (_: Throwable) {}
            try { current?.release() } catch (_: Throwable) {}
            worker = null
            speechActive = false
            clearPcmBufferLocked()
            return stateMap(success = true, message = "Streaming ses kapısı durduruldu.")
        }
    }

    fun clearBuffer(): Map<String, Any> {
        synchronized(this) {
            speechActive = false
            speechOpenCounter = 0
            speechCloseCounter = 0
            lastSpeechAt = 0L
            clearPcmBufferLocked()
            return stateMap(success = true, message = "Streaming voice gate buffer cleared.")
        }
    }

    fun stateMap(success: Boolean = true, message: String = "OK"): Map<String, Any> {
        val now = SystemClock.elapsedRealtime()
        val lastSpeechAgo = if (lastSpeechAt <= 0L) Long.MAX_VALUE else now - lastSpeechAt
        return mapOf(
            "success" to success,
            "message" to message,
            "running" to running,
            "speechActive" to speechActive,
            "speechRecentlyActive" to (lastSpeechAgo in 0..1800),
            "lastSpeechAt" to lastSpeechAt,
            "lastSampleAt" to lastSampleAt,
            "avgRms" to avgRms,
            "peakRms" to peakRms,
            "baselineRms" to baselineRms,
            "thresholdRms" to thresholdRms,
            "lastError" to lastError,
            "speechOpenCounter" to speechOpenCounter,
            "speechCloseCounter" to speechCloseCounter,
            "sampleRate" to SAMPLE_RATE,
            "bufferedPcmSamples" to pcmBufferedSamples,
        )
    }

    @Synchronized
    fun snapshotRecentPcm(maxSeconds: Int = 12): ShortArray {
        val cappedSeconds = maxSeconds.coerceIn(1, 18)
        val requested = (SAMPLE_RATE * cappedSeconds).coerceAtMost(pcmRingBuffer.size)
        val available = min(requested, pcmBufferedSamples)
        if (available <= 0) return ShortArray(0)
        val result = ShortArray(available)
        val start = (pcmWriteIndex - available + pcmRingBuffer.size) % pcmRingBuffer.size
        if (start + available <= pcmRingBuffer.size) {
            System.arraycopy(pcmRingBuffer, start, result, 0, available)
        } else {
            val first = pcmRingBuffer.size - start
            System.arraycopy(pcmRingBuffer, start, result, 0, first)
            System.arraycopy(pcmRingBuffer, 0, result, first, available - first)
        }
        return result
    }

    private fun runLoop(record: AudioRecord, targetBuffer: Int) {
        val buffer = ShortArray((targetBuffer / 4).coerceAtLeast(4096))
        val audioSessionId = record.audioSessionId
        val aec = if (AcousticEchoCanceler.isAvailable()) runCatching { AcousticEchoCanceler.create(audioSessionId) }.getOrNull() else null
        val ns = if (NoiseSuppressor.isAvailable()) runCatching { NoiseSuppressor.create(audioSessionId) }.getOrNull() else null
        val agc = if (AutomaticGainControl.isAvailable()) runCatching { AutomaticGainControl.create(audioSessionId) }.getOrNull() else null
        runCatching { aec?.enabled = true }
        runCatching { ns?.enabled = true }
        runCatching { agc?.enabled = true }

        try {
            record.startRecording()
        } catch (t: Throwable) {
            lastError = t.message ?: "AudioRecord recording başlatılamadı."
            running = false
            try { aec?.release() } catch (_: Throwable) {}
            try { ns?.release() } catch (_: Throwable) {}
            try { agc?.release() } catch (_: Throwable) {}
            try { record.release() } catch (_: Throwable) {}
            audioRecord = null
            return
        }

        while (running && audioRecord === record) {
            try {
                val read = record.read(buffer, 0, buffer.size)
                if (read <= 0) {
                    Thread.sleep(30)
                    continue
                }
                val rms = calculateRms(buffer, read)
                val now = SystemClock.elapsedRealtime()
                lastSampleAt = now

                if (!speechActive) {
                    baselineRms = (baselineRms * 0.985) + (rms * 0.015)
                } else {
                    baselineRms = (baselineRms * 0.997) + (rms * 0.003)
                }

                thresholdRms = maxOf(420.0, baselineRms * 1.72)
                avgRms = if (avgRms <= 0.0) rms else (avgRms * 0.92) + (rms * 0.08)
                peakRms = maxOf(peakRms * 0.985, rms)

                val openThreshold = thresholdRms
                val closeThreshold = maxOf(300.0, baselineRms * 1.18)

                if (rms >= openThreshold) {
                    if (!speechActive && speechOpenCounter == 0) {
                        clearPcmBufferLocked()
                    }
                    speechOpenCounter += 1
                    speechCloseCounter = 0
                    if (!speechActive && speechOpenCounter >= 3) {
                        speechActive = true
                    }
                    appendSamples(buffer, read)
                    if (speechActive) {
                        lastSpeechAt = now
                    }
                } else if (speechActive) {
                    appendSamples(buffer, read)
                    if (rms <= closeThreshold) {
                        speechCloseCounter += 1
                    } else {
                        speechCloseCounter = 0
                    }
                    if (lastSpeechAt > 0L && speechCloseCounter >= 10 && (now - lastSpeechAt) > 2200L) {
                        speechActive = false
                        speechOpenCounter = 0
                    }
                } else {
                    speechOpenCounter = 0
                    speechCloseCounter = 0
                    clearPcmBufferLocked()
                }
            } catch (t: Throwable) {
                lastError = t.message ?: "Streaming ses kapısı hata verdi."
                speechActive = false
                clearPcmBufferLocked()
                Thread.sleep(60)
            }
        }

        try { record.stop() } catch (_: Throwable) {}
        try { aec?.release() } catch (_: Throwable) {}
        try { ns?.release() } catch (_: Throwable) {}
        try { agc?.release() } catch (_: Throwable) {}
        try { record.release() } catch (_: Throwable) {}
    }

    @Synchronized
    private fun appendSamples(buffer: ShortArray, length: Int) {
        if (length <= 0) return
        for (i in 0 until length) {
            pcmRingBuffer[pcmWriteIndex] = buffer[i]
            pcmWriteIndex = (pcmWriteIndex + 1) % pcmRingBuffer.size
            if (pcmBufferedSamples < pcmRingBuffer.size) {
                pcmBufferedSamples += 1
            }
        }
    }

    private fun clearPcmBufferLocked() {
        pcmWriteIndex = 0
        pcmBufferedSamples = 0
    }

    private fun calculateRms(buffer: ShortArray, length: Int): Double {
        if (length <= 0) return 0.0
        var sum = 0.0
        for (i in 0 until length) {
            val sample = buffer[i].toDouble()
            sum += sample * sample
        }
        return sqrt(sum / length)
    }

    private fun hasRecordPermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO,
        ) == PackageManager.PERMISSION_GRANTED
    }
}
