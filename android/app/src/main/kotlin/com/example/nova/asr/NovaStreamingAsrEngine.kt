package com.example.nova.asr

import android.content.Context
import android.os.SystemClock
import com.example.nova.NovaAppSandboxGuard
import com.example.nova.NovaStreamingVoiceGate
import com.k2fsa.sherpa.onnx.FeatureConfig
import com.k2fsa.sherpa.onnx.HomophoneReplacerConfig
import com.k2fsa.sherpa.onnx.OfflineModelConfig
import com.k2fsa.sherpa.onnx.OfflineRecognizer
import com.k2fsa.sherpa.onnx.OfflineRecognizerConfig
import com.k2fsa.sherpa.onnx.OfflineWhisperModelConfig
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.min

class NovaStreamingAsrEngine(private val context: Context) {
    private val config = NovaStreamingAsrConfig()
    private val modelLocator = NovaAsrModelLocator(context)
    private val endpointDetector = NovaEndpointDetector(config.endpointingMs)
    private val stabilizer = NovaPartialTranscriptStabilizer()
    private val ringBuffer = NovaAudioFrameRingBuffer()
    private val session = NovaStreamingAsrSession()
    private val recognizerLock = Any()
    private val continuousLoopRunning = AtomicBoolean(false)
    private val transcriptionInFlight = AtomicBoolean(false)

    @Volatile private var lastLoopTranscribeStartedAt: Long = 0L
    @Volatile private var lastLoopTranscribeFinishedAt: Long = 0L

    @Volatile private var lastPartial: String = ""
    @Volatile private var lastError: String = ""
    @Volatile private var lastMode: String = "idle"
    @Volatile private var finalCount: Int = 0
    @Volatile private var partialCount: Int = 0
    @Volatile private var foregroundServiceRunning: Boolean = false
    @Volatile private var sherpaReady: Boolean = false
    @Volatile private var lastLocale: String = "tr-TR"

    private var recognizer: OfflineRecognizer? = null
    @Volatile private var eventCallback: ((String, NovaStreamingAsrResult, String) -> Unit)? = null

    fun initialize(): Boolean {
        val resolution = modelLocator.resolve()
        sherpaReady = resolution.modelReady && warmupRecognizer(resolution)
        if (!sherpaReady) {
            lastMode = "embedded_unavailable"
            lastError = if (resolution.message.isBlank()) {
                "Embedded Sherpa ASR hazır değil; tek otorite streaming zinciri başlatılamadı."
            } else {
                resolution.message
            }
        } else {
            lastMode = "embedded_sherpa"
            lastError = ""
        }
        return sherpaReady
    }

    fun start(onEvent: (String, NovaStreamingAsrResult, String) -> Unit): Boolean {
        eventCallback = onEvent
        if (session.running) {
            onEvent(
                "status",
                NovaStreamingAsrResult("", false, 0f, session.segmentId, 0, 0, lastLocale),
                "Embedded Sherpa ASR zaten çalışıyor; mevcut tek oturum korunuyor.",
            )
            if (!continuousLoopRunning.get()) {
                startContinuousLoop(onEvent)
            }
            return true
        }
        val ready = if (sherpaReady) true else initialize()
        if (!ready) {
            onEvent(
                "error",
                NovaStreamingAsrResult("", false, 0f, session.segmentId, 0, 0, lastLocale),
                if (lastError.isBlank()) "Embedded Sherpa ASR başlatılamadı." else lastError,
            )
            return false
        }
        session.start()
        lastMode = "embedded_sherpa"
        onEvent(
            "status",
            NovaStreamingAsrResult("", false, 0f, session.segmentId, 0, 0, lastLocale),
            "Embedded Sherpa ASR tek otorite olarak başlatıldı.",
        )
        startContinuousLoop(onEvent)
        return true
    }

    fun decodeStreamingSnapshot(
        mode: String,
        maxDurationSeconds: Int,
        callback: (success: Boolean, text: String, locale: String, message: String, usedEmbedded: Boolean) -> Unit,
    ) {
        val resolution = modelLocator.resolve()
        if (!(sherpaReady || warmupRecognizer(resolution))) {
            sherpaReady = false
            lastMode = "embedded_unavailable"
            callback(false, "", "tr-TR", if (resolution.message.isBlank()) "Embedded Sherpa ASR hazır değil." else resolution.message, true)
            return
        }
        sherpaReady = true
        val samples = NovaStreamingVoiceGate.snapshotRecentPcm(maxDurationSeconds)
        if (samples.isEmpty()) {
            callback(false, "", "tr-TR", "Streaming ses kapısında çözülecek taze konuşma penceresi bulunamadı.", true)
            return
        }
        val transcript = decodeSamplesWithSherpa(samples, resolution)
        if (transcript == null || transcript.text.isBlank()) {
            callback(false, "", "tr-TR", if (lastError.isBlank()) "Embedded Sherpa decode boş döndü." else lastError, true)
            return
        }
        val locale = transcript.locale.ifBlank { "tr-TR" }
        callback(true, transcript.text, locale, transcript.message, true)
    }

    fun pause(): Boolean {
        session.pause()
        return true
    }

    fun resume(): Boolean {
        session.resume()
        val callback = eventCallback
        if (session.running && !continuousLoopRunning.get() && callback != null) {
            startContinuousLoop(callback)
        }
        return true
    }

    fun stop(): Boolean {
        session.stop()
        continuousLoopRunning.set(false)
        transcriptionInFlight.set(false)
        lastLoopTranscribeStartedAt = 0L
        lastLoopTranscribeFinishedAt = 0L
        stabilizer.reset()
        endpointDetector.reset()
        ringBuffer.clear()
        lastPartial = ""
        NovaStreamingVoiceGate.clearBuffer()
        eventCallback = null
        return true
    }

    fun flush(): Boolean {
        session.finalizeSegment()
        clearBuffer()
        return true
    }

    fun clearBuffer(): Boolean {
        ringBuffer.clear()
        stabilizer.reset()
        endpointDetector.reset()
        transcriptionInFlight.set(false)
        lastLoopTranscribeStartedAt = 0L
        lastLoopTranscribeFinishedAt = 0L
        lastPartial = ""
        NovaStreamingVoiceGate.clearBuffer()
        return true
    }

    fun setForegroundServiceRunning(value: Boolean) {
        foregroundServiceRunning = value
    }

    fun stateMap(): Map<String, Any> {
        val resolution = modelLocator.resolve()
        return mapOf(
            "initialized" to true,
            "running" to session.running,
            "foregroundServiceRunning" to foregroundServiceRunning,
            "modelReady" to resolution.modelReady,
            "singleAuthorityConfirmed" to true,
            "embeddedSherpaReady" to sherpaReady,
            "message" to if (lastError.isNotBlank()) lastError else resolution.message,
            "partialCount" to partialCount,
            "finalCount" to finalCount,
            "droppedFrames" to ringBuffer.droppedFrames,
            "modelChecksum" to resolution.checksum,
            "lastPartial" to lastPartial,
            "lastLocale" to lastLocale,
            "lastMode" to lastMode,
            "modelAssetPath" to resolution.modelAssetPath,
            "decoderAssetPath" to resolution.decoderAssetPath,
            "tokenAssetPath" to resolution.tokenAssetPath,
            "configAssetPath" to resolution.configAssetPath,
        )
    }

    private fun startContinuousLoop(onEvent: (String, NovaStreamingAsrResult, String) -> Unit) {
        if (!continuousLoopRunning.compareAndSet(false, true)) return
        Thread {
            try {
                while (session.running) {
                    if (session.paused) {
                        Thread.sleep(250)
                        continue
                    }

                    val gate = NovaStreamingVoiceGate.stateMap()
                    val gateSpeechActive = gate["speechActive"] as? Boolean ?: false
                    val gateSpeechRecent = gate["speechRecentlyActive"] as? Boolean ?: false
                    if (!gateSpeechActive && !gateSpeechRecent) {
                        Thread.sleep(180)
                        continue
                    }

                    val now = SystemClock.elapsedRealtime()
                    val minGapMs = if (gateSpeechActive) 1500L else 2200L
                    if (transcriptionInFlight.get() || (now - lastLoopTranscribeStartedAt) < minGapMs) {
                        Thread.sleep(if (gateSpeechActive) 180 else 260)
                        continue
                    }

                    val loopSegmentId = session.segmentId
                    transcriptionInFlight.set(true)
                    lastLoopTranscribeStartedAt = now
                    decodeStreamingSnapshot(
                        mode = "normalCommandListening",
                        maxDurationSeconds = 8,
                    ) { success, text, locale, message, embedded ->
                        try {
                            if (!session.running || session.paused || loopSegmentId != session.segmentId) {
                                return@decodeStreamingSnapshot
                            }

                            if (!success) {
                                lastError = message
                                lastMode = if (embedded) "embedded_sherpa_error" else "embedded_sherpa_error"
                                onEvent(
                                    "error",
                                    NovaStreamingAsrResult("", false, 0f, session.segmentId, 0, 0, locale),
                                    message,
                                )
                                return@decodeStreamingSnapshot
                            }

                            val stabilized = stabilizer.stabilize(text).trim()
                            if (stabilized.isBlank()) {
                                return@decodeStreamingSnapshot
                            }

                            lastPartial = stabilized
                            lastLocale = locale
                            partialCount += 1
                            val eventNow = SystemClock.elapsedRealtime()
                            if (gateSpeechActive) {
                                endpointDetector.markSpeech(eventNow)
                            }
                            onEvent(
                                "partial",
                                NovaStreamingAsrResult(
                                    stabilized,
                                    false,
                                    if (embedded) 0.82f else 0.62f,
                                    session.segmentId,
                                    0,
                                    0,
                                    locale,
                                ),
                                if (embedded) "Embedded partial transcript hazır." else "Embedded partial transcript hazır.",
                            )

                            if (gateSpeechActive || !endpointDetector.shouldFinalize(eventNow)) {
                                return@decodeStreamingSnapshot
                            }

                            finalCount += 1
                            lastMode = if (embedded) "embedded_sherpa" else "embedded_sherpa"
                            onEvent(
                                "final",
                                NovaStreamingAsrResult(
                                    stabilized,
                                    true,
                                    if (embedded) 0.91f else 0.79f,
                                    session.segmentId,
                                    0,
                                    0,
                                    locale,
                                ),
                                if (embedded) "Embedded final transcript hazır." else "Embedded final transcript hazır.",
                            )
                            session.finalizeSegment()
                            clearBuffer()
                        } finally {
                            lastLoopTranscribeFinishedAt = SystemClock.elapsedRealtime()
                            transcriptionInFlight.set(false)
                        }
                    }
                    Thread.sleep(if (gateSpeechActive) 260 else 340)
                }
            } catch (t: Throwable) {
                lastError = t.message ?: "Streaming ASR sürekli döngüsü beklenmedik şekilde durdu."
                onEvent(
                    "error",
                    NovaStreamingAsrResult("", false, 0f, session.segmentId, 0, 0, lastLocale),
                    lastError,
                )
            } finally {
                continuousLoopRunning.set(false)
            }
        }.start()
    }

    private fun warmupRecognizer(resolution: NovaAsrModelLocator.ModelResolution): Boolean {
        synchronized(recognizerLock) {
            if (recognizer != null) return true
            if (!resolution.modelReady) return false
            return try {
                recognizer = OfflineRecognizer(context.assets, buildRecognizerConfig(resolution))
                true
            } catch (_: Throwable) {
                recognizer = null
                false
            }
        }
    }

    private fun buildRecognizerConfig(resolution: NovaAsrModelLocator.ModelResolution): OfflineRecognizerConfig {
        val whisperConfig = OfflineWhisperModelConfig().apply {
            encoder = resolution.modelAssetPath.ifBlank { "sherpa_asr/encoder.onnx" }
            decoder = resolution.decoderAssetPath.ifBlank { inferDecoderAssetPath(resolution.modelAssetPath) }
            language = "tr"
            task = "transcribe"
            tailPaddings = 20
            enableSegmentTimestamps = true
            enableTokenTimestamps = false
        }
        val modelConfig = OfflineModelConfig().apply {
            whisper = whisperConfig
            tokens = resolution.tokenAssetPath.ifBlank { "sherpa_asr/tokens.txt" }
            modelType = "whisper"
            numThreads = 2
            debug = false
            provider = "cpu"
        }
        return OfflineRecognizerConfig().apply {
            featConfig = FeatureConfig().apply {
                sampleRate = config.sampleRate
                featureDim = 80
                dither = 0f
            }
            this.modelConfig = modelConfig
            hr = HomophoneReplacerConfig()
            decodingMethod = "greedy_search"
            maxActivePaths = maxOf(4, config.beamSize)
        }
    }

    private fun inferDecoderAssetPath(modelAssetPath: String): String {
        if (modelAssetPath.contains("encoder.onnx")) {
            return modelAssetPath.replace("encoder.onnx", "decoder.onnx")
        }
        return "sherpa_asr/decoder.onnx"
    }

    private data class DecodeOutput(
        val text: String,
        val locale: String,
        val message: String,
    )

    private fun decodeFileWithSherpa(file: File, resolution: NovaAsrModelLocator.ModelResolution): DecodeOutput? {
        if (!file.exists() || !file.isFile) return null
        val samples = readWavPcm16Mono(file) ?: return null
        val localRecognizer = synchronized(recognizerLock) {
            recognizer ?: run {
                if (!warmupRecognizer(resolution)) return null
                recognizer
            }
        } ?: return null

        return try {
            val stream = localRecognizer.createStream()
            val chunks = samples.asList().chunked(config.chunkSize)
            var consumed = 0
            for (chunk in chunks) {
                val floatChunk = FloatArray(chunk.size)
                for (i in chunk.indices) {
                    floatChunk[i] = chunk[i]
                }
                stream.acceptWaveform(floatChunk, config.sampleRate)
                consumed += floatChunk.size
                if (floatChunk.isNotEmpty()) {
                    val shorts = ShortArray(min(floatChunk.size, config.chunkSize)) { idx ->
                        (floatChunk[idx] * Short.MAX_VALUE).toInt().coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
                    }
                    ringBuffer.push(shorts)
                }
            }
            localRecognizer.decode(stream)
            val result = localRecognizer.getResult(stream)
            stream.release()
            val locale = result.lang.takeIf { it.isNotBlank() } ?: "tr-TR"
            DecodeOutput(
                text = result.text.trim(),
                locale = locale,
                message = "Sherpa embedded decode tamamlandı (${consumed} örnek).",
            )
        } catch (t: Throwable) {
            lastError = t.message ?: "Sherpa embedded decode başarısız oldu."
            null
        }
    }

    private fun decodeSamplesWithSherpa(samples: ShortArray, resolution: NovaAsrModelLocator.ModelResolution): DecodeOutput? {
        if (samples.isEmpty()) return null
        val localRecognizer = synchronized(recognizerLock) {
            recognizer ?: run {
                if (!warmupRecognizer(resolution)) return null
                recognizer
            }
        } ?: return null

        return try {
            val stream = localRecognizer.createStream()
            val floatChunk = FloatArray(samples.size) { index -> samples[index] / 32768.0f }
            stream.acceptWaveform(floatChunk, config.sampleRate)
            localRecognizer.decode(stream)
            val result = localRecognizer.getResult(stream)
            stream.release()
            val locale = result.lang.takeIf { it.isNotBlank() } ?: "tr-TR"
            DecodeOutput(
                text = result.text.trim(),
                locale = locale,
                message = "Sherpa embedded snapshot decode tamamlandı (${samples.size} örnek).",
            )
        } catch (t: Throwable) {
            lastError = t.message ?: "Sherpa embedded snapshot decode başarısız oldu."
            null
        }
    }

    private fun readWavPcm16Mono(file: File): FloatArray? {
        val bytes = try {
            file.readBytes()
        } catch (_: Throwable) {
            return null
        }
        if (bytes.size < 44) return null
        if (String(bytes, 0, 4) != "RIFF" || String(bytes, 8, 4) != "WAVE") return null

        var offset = 12
        var channels = 1
        var sampleRate = config.sampleRate
        var bitsPerSample = 16
        var dataOffset = -1
        var dataSize = -1

        while (offset + 8 <= bytes.size) {
            val chunkId = String(bytes, offset, 4)
            val chunkSize = littleEndianInt(bytes, offset + 4)
            val chunkStart = offset + 8
            if (chunkStart + chunkSize > bytes.size) return null
            when (chunkId) {
                "fmt " -> {
                    channels = littleEndianShort(bytes, chunkStart + 2).toInt().coerceAtLeast(1)
                    sampleRate = littleEndianInt(bytes, chunkStart + 4)
                    bitsPerSample = littleEndianShort(bytes, chunkStart + 14).toInt()
                }
                "data" -> {
                    dataOffset = chunkStart
                    dataSize = chunkSize
                }
            }
            offset = chunkStart + chunkSize + (chunkSize % 2)
        }

        if (dataOffset < 0 || dataSize <= 0 || bitsPerSample != 16) return null
        val raw = bytes.copyOfRange(dataOffset, dataOffset + dataSize)
        val shortBuffer = ByteBuffer.wrap(raw).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val shortArray = ShortArray(shortBuffer.remaining())
        shortBuffer.get(shortArray)
        if (shortArray.isEmpty()) return null

        val mono = if (channels <= 1) {
            shortArray
        } else {
            val frames = shortArray.size / channels
            ShortArray(frames) { frameIndex ->
                var sum = 0
                for (channel in 0 until channels) {
                    sum += shortArray[frameIndex * channels + channel].toInt()
                }
                (sum / channels).toShort()
            }
        }

        if (sampleRate != config.sampleRate) {
            lastError = "Beklenen örnekleme oranı ${config.sampleRate} yerine $sampleRate geldi; ham decode denendi."
        }

        return FloatArray(mono.size) { index -> mono[index] / 32768.0f }
    }

    private fun littleEndianInt(bytes: ByteArray, offset: Int): Int {
        return (bytes[offset].toInt() and 0xff) or
            ((bytes[offset + 1].toInt() and 0xff) shl 8) or
            ((bytes[offset + 2].toInt() and 0xff) shl 16) or
            ((bytes[offset + 3].toInt() and 0xff) shl 24)
    }

    private fun littleEndianShort(bytes: ByteArray, offset: Int): Short {
        return (((bytes[offset].toInt() and 0xff) or ((bytes[offset + 1].toInt() and 0xff) shl 8))).toShort()
    }
}


data class NovaStreamingAsrDiagnosticSnapshot(
    val sherpaReady: Boolean,
    val lastMode: String,
    val partialCount: Int,
    val finalCount: Int,
    val lastError: String,
    val foregroundServiceRunning: Boolean,
)

fun NovaStreamingAsrEngine.buildDiagnosticSnapshot(): NovaStreamingAsrDiagnosticSnapshot {
    val map = stateMap()
    return NovaStreamingAsrDiagnosticSnapshot(
        sherpaReady = map["embeddedSherpaReady"] as? Boolean ?: false,
        lastMode = map["lastMode"] as? String ?: "unknown",
        partialCount = map["partialCount"] as? Int ?: 0,
        finalCount = map["finalCount"] as? Int ?: 0,
        lastError = map["lastError"] as? String ?: "",
        foregroundServiceRunning = map["foregroundServiceRunning"] as? Boolean ?: false,
    )
}

fun NovaStreamingAsrDiagnosticSnapshot.render(): String {
    return buildString {
        append("STREAMING ASR SNAPSHOT\n")
        append("- sherpaReady=").append(sherpaReady).append('\n')
        append("- mode=").append(lastMode).append('\n')
        append("- partialCount=").append(partialCount).append('\n')
        append("- finalCount=").append(finalCount).append('\n')
        append("- foreground=").append(foregroundServiceRunning).append('\n')
        append("- lastError=").append(lastError.ifBlank { "none" })
    }
}

object NovaStreamingAsrRules {
    fun render(): String {
        return buildString {
            append("STREAMING ASR RULES\n")
            append("- tek otorite embedded streaming zinciri korunmalı\n")
            append("- foreground/mic durumları snapshot ile izlenebilmeli\n")
            append("- partial/final sayaçları regresyon tespiti için tutulmalı\n")
            append("- endpointing ve interruption ayrımı aynı akışta korunmalı")
        }
    }
}


data class NovaStreamingAsrCrowdHint(
    val locale: String,
    val prefersShortBackchannels: Boolean,
    val shouldStayOpenMic: Boolean,
)

object NovaStreamingAsrCrowdHintResolver {
    fun build(locale: String, continuousListeningEnabled: Boolean): NovaStreamingAsrCrowdHint {
        return NovaStreamingAsrCrowdHint(
            locale = locale,
            prefersShortBackchannels = locale.startsWith("tr", ignoreCase = true),
            shouldStayOpenMic = continuousListeningEnabled,
        )
    }
}
