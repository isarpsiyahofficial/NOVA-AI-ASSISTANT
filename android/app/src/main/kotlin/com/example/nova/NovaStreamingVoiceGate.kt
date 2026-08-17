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
import com.k2fsa.sherpa.onnx.SileroVadModelConfig
import com.k2fsa.sherpa.onnx.Vad
import com.k2fsa.sherpa.onnx.VadModelConfig
import java.util.ArrayDeque
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * The single microphone/VAD authority used by Nova streaming ASR.
 *
 * Audio is captured in 32 ms frames and classified by the packaged Silero VAD
 * model. Completed speech segments are queued for Whisper exactly once. RMS is
 * retained only for diagnostics; it never decides whether speech exists.
 */
object NovaStreamingVoiceGate {
    private const val SAMPLE_RATE = 16_000
    private const val CHANNEL_MASK = AudioFormat.CHANNEL_IN_MONO
    private const val ENCODING = AudioFormat.ENCODING_PCM_16BIT
    private const val FRAME_SAMPLES = 512
    private const val FRAME_MS = 32
    private const val MAX_RECENT_SECONDS = 28
    private const val MAX_SEGMENT_QUEUE = 3
    private const val RECENT_SPEECH_HOLD_MS = 900L
    private const val VAD_ASSET_PATH = "sherpa_vad/silero_vad.onnx"

    private val stateLock = Any()
    private val recentRing = ShortRingBuffer(SAMPLE_RATE * MAX_RECENT_SECONDS)
    private val completedSegments = ArrayDeque<ShortArray>()

    @Volatile private var running = false
    @Volatile private var speechActive = false
    @Volatile private var lastSpeechAt = 0L
    @Volatile private var lastSampleAt = 0L
    @Volatile private var lastSegmentAt = 0L
    @Volatile private var avgRms = 0.0
    @Volatile private var peakRms = 0.0
    @Volatile private var lastError = ""
    @Volatile private var frameCount = 0L
    @Volatile private var droppedFrames = 0L
    @Volatile private var completedSegmentCount = 0L

    private var worker: Thread? = null
    private var audioRecord: AudioRecord? = null
    private var vad: Vad? = null
    private var acousticEchoCanceler: AcousticEchoCanceler? = null
    private var noiseSuppressor: NoiseSuppressor? = null
    private var automaticGainControl: AutomaticGainControl? = null

    fun start(context: Context): Map<String, Any> {
        synchronized(stateLock) {
            if (!hasRecordPermission(context)) {
                lastError = "Mikrofon izni eksik."
                return stateMap(success = false, message = lastError)
            }
            if (running) {
                return stateMap(
                    success = true,
                    message = "Silero VAD mikrofon kapısı zaten çalışıyor.",
                )
            }

            val createdVad = try {
                Vad(
                    context.assets,
                    VadModelConfig(
                        sileroVadModelConfig = SileroVadModelConfig(
                            model = VAD_ASSET_PATH,
                            threshold = 0.48f,
                            minSilenceDuration = 0.42f,
                            minSpeechDuration = 0.08f,
                            windowSize = FRAME_SAMPLES,
                            maxSpeechDuration = 25.0f,
                        ),
                        sampleRate = SAMPLE_RATE,
                        numThreads = 1,
                        provider = "cpu",
                        debug = false,
                    ),
                )
            } catch (t: Throwable) {
                lastError = "Silero VAD açılamadı: ${t.message ?: t.javaClass.simpleName}"
                return stateMap(success = false, message = lastError)
            }

            val minBuffer = AudioRecord.getMinBufferSize(
                SAMPLE_RATE,
                CHANNEL_MASK,
                ENCODING,
            )
            if (minBuffer <= 0) {
                createdVad.release()
                lastError = "AudioRecord buffer boyutu alınamadı: $minBuffer"
                return stateMap(success = false, message = lastError)
            }

            val createdRecord = try {
                AudioRecord(
                    MediaRecorder.AudioSource.VOICE_RECOGNITION,
                    SAMPLE_RATE,
                    CHANNEL_MASK,
                    ENCODING,
                    max(minBuffer * 2, FRAME_SAMPLES * 2 * 8),
                )
            } catch (t: Throwable) {
                createdVad.release()
                lastError = "AudioRecord oluşturulamadı: ${t.message ?: t.javaClass.simpleName}"
                return stateMap(success = false, message = lastError)
            }

            if (createdRecord.state != AudioRecord.STATE_INITIALIZED) {
                try {
                    createdRecord.release()
                } catch (_: Throwable) {
                }
                createdVad.release()
                lastError = "AudioRecord başlatılamadı."
                return stateMap(success = false, message = lastError)
            }

            resetStateLocked(clearDiagnostics = true)
            audioRecord = createdRecord
            vad = createdVad
            attachAudioEffects(createdRecord.audioSessionId)
            running = true

            worker = Thread {
                captureLoop(createdRecord, createdVad)
            }.apply {
                name = "NovaSileroVadCapture"
                isDaemon = true
                start()
            }

            return stateMap(
                success = true,
                message = "Silero VAD tek mikrofon kapısı 32 ms framelerle başladı.",
            )
        }
    }

    fun stop(): Map<String, Any> {
        val currentWorker: Thread?
        val currentRecord: AudioRecord?
        val currentVad: Vad?
        synchronized(stateLock) {
            running = false
            speechActive = false
            currentWorker = worker
            currentRecord = audioRecord
            currentVad = vad
            worker = null
            audioRecord = null
            vad = null
        }

        try {
            currentRecord?.stop()
        } catch (_: Throwable) {
        }
        try {
            currentWorker?.interrupt()
            if (currentWorker != Thread.currentThread()) {
                currentWorker?.join(900L)
            }
        } catch (_: Throwable) {
        }
        try {
            currentRecord?.release()
        } catch (_: Throwable) {
        }
        releaseAudioEffects()
        try {
            currentVad?.flush()
            if (currentVad != null) {
                synchronized(stateLock) {
                    drainVadSegmentsLocked(currentVad)
                }
            }
        } catch (_: Throwable) {
        }
        try {
            currentVad?.release()
        } catch (_: Throwable) {
        }

        synchronized(stateLock) {
            recentRing.clear()
            completedSegments.clear()
        }
        return stateMap(
            success = true,
            message = "Silero VAD mikrofon kapısı durduruldu ve AudioRecord serbest bırakıldı.",
        )
    }

    fun clearBuffer(): Map<String, Any> {
        synchronized(stateLock) {
            recentRing.clear()
            completedSegments.clear()
            speechActive = false
            lastSpeechAt = 0L
            lastSegmentAt = 0L
            try {
                vad?.clear()
                vad?.reset()
            } catch (_: Throwable) {
            }
        }
        return stateMap(
            success = true,
            message = "Silero VAD konuşma ve PCM kuyrukları temizlendi.",
        )
    }

    /** Returns and removes one completed VAD speech segment. */
    fun takeCompletedSpeechPcm(maxSeconds: Int = MAX_RECENT_SECONDS): ShortArray {
        synchronized(stateLock) {
            if (completedSegments.isEmpty()) return ShortArray(0)
            val segment = completedSegments.removeFirst()
            val maxSamples = SAMPLE_RATE * maxSeconds.coerceIn(1, MAX_RECENT_SECONDS)
            return if (segment.size <= maxSamples) {
                segment
            } else {
                segment.copyOfRange(0, maxSamples)
            }
        }
    }

    /** Snapshot is used only for throttled partial text while speech is live. */
    fun snapshotRecentPcm(maxSeconds: Int = 12): ShortArray {
        synchronized(stateLock) {
            return recentRing.snapshotTail(
                SAMPLE_RATE * maxSeconds.coerceIn(1, MAX_RECENT_SECONDS),
            )
        }
    }

    fun stateMap(success: Boolean = true, message: String = "OK"): Map<String, Any> {
        val now = SystemClock.elapsedRealtime()
        val recent = speechActive ||
            synchronized(stateLock) { completedSegments.isNotEmpty() } ||
            (lastSpeechAt > 0L && now - lastSpeechAt <= RECENT_SPEECH_HOLD_MS)
        val queued = synchronized(stateLock) { completedSegments.size }
        val buffered = synchronized(stateLock) { recentRing.size() }
        return mapOf(
            "success" to success,
            "message" to message,
            "running" to running,
            "speechActive" to speechActive,
            "speechRecentlyActive" to recent,
            "lastSpeechAt" to lastSpeechAt,
            "lastSampleAt" to lastSampleAt,
            "lastSegmentAt" to lastSegmentAt,
            "avgRms" to avgRms,
            "peakRms" to peakRms,
            "baselineRms" to 0.0,
            "thresholdRms" to 0.48,
            "lastError" to lastError,
            "speechOpenCounter" to if (speechActive) 1 else 0,
            "speechCloseCounter" to 0,
            "sampleRate" to SAMPLE_RATE,
            "frameSamples" to FRAME_SAMPLES,
            "frameMs" to FRAME_MS,
            "bufferedPcmSamples" to buffered,
            "queuedSpeechSegments" to queued,
            "completedSegmentCount" to completedSegmentCount,
            "frameCount" to frameCount,
            "droppedFrames" to droppedFrames,
            "vadReady" to (vad != null),
            "vadEngine" to "sherpa_onnx_silero_vad",
            "vadModel" to VAD_ASSET_PATH,
            "aecActive" to (acousticEchoCanceler?.enabled == true),
            "noiseSuppressorActive" to (noiseSuppressor?.enabled == true),
            "agcActive" to (automaticGainControl?.enabled == true),
        )
    }

    private fun captureLoop(record: AudioRecord, activeVad: Vad) {
        val readBuffer = ShortArray(FRAME_SAMPLES * 4)
        val frame = ShortArray(FRAME_SAMPLES)
        var frameFill = 0

        try {
            record.startRecording()
            if (record.recordingState != AudioRecord.RECORDSTATE_RECORDING) {
                throw IllegalStateException("AudioRecord recording durumuna geçmedi.")
            }

            while (running && audioRecord === record && !Thread.currentThread().isInterrupted) {
                val read = record.read(
                    readBuffer,
                    0,
                    readBuffer.size,
                    AudioRecord.READ_BLOCKING,
                )
                if (read <= 0) {
                    droppedFrames += 1
                    if (read == AudioRecord.ERROR_INVALID_OPERATION ||
                        read == AudioRecord.ERROR_BAD_VALUE ||
                        read == AudioRecord.ERROR_DEAD_OBJECT
                    ) {
                        throw IllegalStateException("AudioRecord read hatası: $read")
                    }
                    continue
                }

                var sourceOffset = 0
                while (sourceOffset < read) {
                    val copyCount = min(FRAME_SAMPLES - frameFill, read - sourceOffset)
                    System.arraycopy(readBuffer, sourceOffset, frame, frameFill, copyCount)
                    sourceOffset += copyCount
                    frameFill += copyCount
                    if (frameFill == FRAME_SAMPLES) {
                        processFrame(frame, activeVad)
                        frameFill = 0
                    }
                }
            }
        } catch (t: Throwable) {
            if (running) {
                lastError = "Silero VAD capture hatası: ${t.message ?: t.javaClass.simpleName}"
            }
        } finally {
            try {
                record.stop()
            } catch (_: Throwable) {
            }
            synchronized(stateLock) {
                if (audioRecord === record) {
                    audioRecord = null
                    running = false
                }
                if (worker === Thread.currentThread()) {
                    worker = null
                }
            }
        }
    }

    private fun processFrame(frame: ShortArray, activeVad: Vad) {
        val rms = calculateRms(frame)
        avgRms = if (avgRms <= 0.0) rms else avgRms * 0.92 + rms * 0.08
        peakRms = max(peakRms * 0.985, rms)
        lastSampleAt = SystemClock.elapsedRealtime()

        val floatFrame = FloatArray(frame.size) { index -> frame[index] / 32768.0f }
        synchronized(stateLock) {
            activeVad.acceptWaveform(floatFrame)
            frameCount += 1
            speechActive = activeVad.isSpeechDetected()
            if (speechActive) {
                lastSpeechAt = SystemClock.elapsedRealtime()
                recentRing.push(frame)
            }
            drainVadSegmentsLocked(activeVad)
        }
    }

    private fun drainVadSegmentsLocked(activeVad: Vad) {
        while (!activeVad.empty()) {
            val segment = activeVad.front()
            activeVad.pop()
            if (segment.samples.isEmpty()) continue
            val pcm = ShortArray(segment.samples.size) { index ->
                (segment.samples[index] * 32767.0f)
                    .toInt()
                    .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
                    .toShort()
            }
            if (pcm.size < SAMPLE_RATE / 12) continue
            completedSegments.addLast(pcm)
            while (completedSegments.size > MAX_SEGMENT_QUEUE) {
                completedSegments.removeFirst()
            }
            recentRing.clear()
            recentRing.push(pcm)
            completedSegmentCount += 1
            lastSegmentAt = SystemClock.elapsedRealtime()
            lastSpeechAt = lastSegmentAt
            speechActive = false
        }
    }

    private fun attachAudioEffects(audioSessionId: Int) {
        acousticEchoCanceler = if (AcousticEchoCanceler.isAvailable()) {
            runCatching { AcousticEchoCanceler.create(audioSessionId) }.getOrNull()
        } else {
            null
        }
        noiseSuppressor = if (NoiseSuppressor.isAvailable()) {
            runCatching { NoiseSuppressor.create(audioSessionId) }.getOrNull()
        } else {
            null
        }
        automaticGainControl = if (AutomaticGainControl.isAvailable()) {
            runCatching { AutomaticGainControl.create(audioSessionId) }.getOrNull()
        } else {
            null
        }
        runCatching { acousticEchoCanceler?.enabled = true }
        runCatching { noiseSuppressor?.enabled = true }
        runCatching { automaticGainControl?.enabled = true }
    }

    private fun releaseAudioEffects() {
        try {
            acousticEchoCanceler?.release()
        } catch (_: Throwable) {
        }
        try {
            noiseSuppressor?.release()
        } catch (_: Throwable) {
        }
        try {
            automaticGainControl?.release()
        } catch (_: Throwable) {
        }
        acousticEchoCanceler = null
        noiseSuppressor = null
        automaticGainControl = null
    }

    private fun resetStateLocked(clearDiagnostics: Boolean) {
        recentRing.clear()
        completedSegments.clear()
        speechActive = false
        lastSpeechAt = 0L
        lastSampleAt = 0L
        lastSegmentAt = 0L
        frameCount = 0L
        droppedFrames = 0L
        completedSegmentCount = 0L
        if (clearDiagnostics) {
            avgRms = 0.0
            peakRms = 0.0
            lastError = ""
        }
    }

    private fun calculateRms(samples: ShortArray): Double {
        if (samples.isEmpty()) return 0.0
        var sum = 0.0
        for (sample in samples) {
            val value = sample.toDouble()
            sum += value * value
        }
        return sqrt(sum / samples.size.toDouble())
    }

    private fun hasRecordPermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.RECORD_AUDIO,
        ) == PackageManager.PERMISSION_GRANTED
    }

    private class ShortRingBuffer(capacity: Int) {
        private val data = ShortArray(capacity.coerceAtLeast(1))
        private var writeIndex = 0
        private var currentSize = 0

        fun clear() {
            writeIndex = 0
            currentSize = 0
        }

        fun size(): Int = currentSize

        fun push(samples: ShortArray) {
            for (sample in samples) {
                data[writeIndex] = sample
                writeIndex = (writeIndex + 1) % data.size
                if (currentSize < data.size) currentSize += 1
            }
        }

        fun snapshotTail(maxSamples: Int): ShortArray {
            val count = min(currentSize, maxSamples.coerceAtLeast(0))
            if (count <= 0) return ShortArray(0)
            val out = ShortArray(count)
            var sourceIndex = (writeIndex - count + data.size) % data.size
            for (index in 0 until count) {
                out[index] = data[sourceIndex]
                sourceIndex = (sourceIndex + 1) % data.size
            }
            return out
        }
    }
}
