package com.example.nova.asr

import android.app.ActivityManager
import android.content.Context
import android.os.SystemClock
import com.example.nova.NovaStreamingVoiceGate
import com.k2fsa.sherpa.onnx.FeatureConfig
import com.k2fsa.sherpa.onnx.HomophoneReplacerConfig
import com.k2fsa.sherpa.onnx.OfflineModelConfig
import com.k2fsa.sherpa.onnx.OfflineRecognizer
import com.k2fsa.sherpa.onnx.OfflineRecognizerConfig
import com.k2fsa.sherpa.onnx.OfflineWhisperModelConfig
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max

/**
 * Single embedded ASR runtime.
 *
 * Silero VAD owns endpointing. Every completed speech segment is decoded by
 * Whisper exactly once. The exact same PCM segment is persisted as an app-
 * private WAV reference so Flutter can run TitaNet speaker verification before
 * a phone action receives owner authority.
 */
class NovaStreamingAsrEngine(private val context: Context) {
    private val config = NovaStreamingAsrConfig()
    private val modelLocator = NovaAsrModelLocator(context)
    private val stabilizer = NovaPartialTranscriptStabilizer()
    private val session = NovaStreamingAsrSession()
    private val recognizerLock = Any()
    private val decodeLock = Any()
    private val continuousLoopRunning = AtomicBoolean(false)
    private val transcriptionInFlight = AtomicBoolean(false)

    @Volatile private var lastDecodeStartedAt: Long = 0L
    @Volatile private var lastDecodeFinishedAt: Long = 0L
    @Volatile private var lastPartialDecodeAt: Long = 0L
    @Volatile private var lastPartialSampleCount: Int = 0
    @Volatile private var lastDecodeDurationMs: Long = 0L
    @Volatile private var finalDecodeCount: Long = 0L
    @Volatile private var partialDecodeCount: Long = 0L
    @Volatile private var blankSegmentCount: Long = 0L

    @Volatile private var lastPartial: String = ""
    @Volatile private var lastError: String = ""
    @Volatile private var lastMode: String = "idle"
    @Volatile private var finalCount: Int = 0
    @Volatile private var partialCount: Int = 0
    @Volatile private var foregroundServiceRunning: Boolean = false
    @Volatile private var sherpaReady: Boolean = false
    @Volatile private var lastLocale: String = "tr-TR"
    @Volatile private var lastIdentityAudioPath: String = ""

    private var recognizer: OfflineRecognizer? = null
    @Volatile private var eventCallback: ((String, NovaStreamingAsrResult, String) -> Unit)? = null

    fun initialize(): Boolean {
        val resolution = modelLocator.resolve()
        sherpaReady = resolution.modelReady && warmupRecognizer(resolution)
        if (!sherpaReady) {
            lastMode = "embedded_unavailable"
            lastError = resolution.message.ifBlank {
                "Embedded Sherpa Whisper modeli hazır değil."
            }
        } else {
            lastMode = "embedded_whisper_vad_ready"
            lastError = ""
        }
        return sherpaReady
    }

    fun start(onEvent: (String, NovaStreamingAsrResult, String) -> Unit): Boolean {
        eventCallback = onEvent
        if (session.running) {
            if (!continuousLoopRunning.get()) startContinuousLoop(onEvent)
            onEvent(
                "status",
                emptyResult(),
                "Embedded Whisper + Silero VAD tek oturumu zaten çalışıyor.",
            )
            return true
        }
        if (!(sherpaReady || initialize())) {
            onEvent(
                "error",
                emptyResult(),
                lastError.ifBlank { "Embedded Sherpa ASR başlatılamadı." },
            )
            return false
        }
        session.start()
        lastMode = "embedded_whisper_vad"
        onEvent(
            "status",
            emptyResult(),
            "Embedded Whisper + Silero VAD tek ASR otoritesi başlatıldı.",
        )
        startContinuousLoop(onEvent)
        return true
    }

    /** Legacy diagnostic snapshot; normal STT consumes the event stream. */
    fun decodeStreamingSnapshot(
        mode: String,
        maxDurationSeconds: Int,
        callback: (
            success: Boolean,
            text: String,
            locale: String,
            message: String,
            usedEmbedded: Boolean,
        ) -> Unit,
    ) {
        Thread {
            val resolution = modelLocator.resolve()
            if (!(sherpaReady || warmupRecognizer(resolution))) {
                sherpaReady = false
                lastMode = "embedded_unavailable"
                callback(
                    false,
                    "",
                    "tr-TR",
                    resolution.message.ifBlank { "Embedded Sherpa ASR hazır değil." },
                    true,
                )
                return@Thread
            }
            sherpaReady = true
            val samples = NovaStreamingVoiceGate.snapshotRecentPcm(maxDurationSeconds)
            if (samples.isEmpty()) {
                callback(
                    false,
                    "",
                    "tr-TR",
                    "Silero VAD kapısında çözülecek konuşma bulunamadı.",
                    true,
                )
                return@Thread
            }
            val transcript = decodeSamplesWithSherpa(samples, resolution)
            if (transcript == null || transcript.text.isBlank()) {
                callback(
                    false,
                    "",
                    "tr-TR",
                    lastError.ifBlank { "Embedded Whisper decode boş döndü." },
                    true,
                )
                return@Thread
            }
            callback(
                true,
                transcript.text,
                transcript.locale,
                transcript.message,
                true,
            )
        }.apply {
            name = "NovaAsrDiagnosticSnapshot"
            isDaemon = true
            start()
        }
    }

    fun pause(): Boolean {
        session.pause()
        return true
    }

    fun resume(): Boolean {
        session.resume()
        val callback = eventCallback
        if (session.running && callback != null && !continuousLoopRunning.get()) {
            startContinuousLoop(callback)
        }
        return true
    }

    fun stop(): Boolean {
        session.stop()
        continuousLoopRunning.set(false)
        transcriptionInFlight.set(false)
        resetTurnState()
        NovaStreamingVoiceGate.clearBuffer()
        eventCallback = null
        return true
    }

    fun flush(): Boolean {
        val completed = NovaStreamingVoiceGate.takeCompletedSpeechPcm(28)
        if (completed.isNotEmpty()) {
            eventCallback?.let { callback -> decodeFinalSegment(completed, callback) }
        }
        return true
    }

    fun clearBuffer(): Boolean {
        transcriptionInFlight.set(false)
        resetTurnState()
        NovaStreamingVoiceGate.clearBuffer()
        return true
    }

    fun setForegroundServiceRunning(value: Boolean) {
        foregroundServiceRunning = value
    }

    fun stateMap(): Map<String, Any> {
        val resolution = modelLocator.resolve()
        val gate = NovaStreamingVoiceGate.stateMap()
        return mapOf(
            "initialized" to true,
            "running" to session.running,
            "paused" to session.paused,
            "foregroundServiceRunning" to foregroundServiceRunning,
            "modelReady" to resolution.modelReady,
            "singleAuthorityConfirmed" to true,
            "embeddedSherpaReady" to sherpaReady,
            "message" to if (lastError.isNotBlank()) lastError else resolution.message,
            "partialCount" to partialCount,
            "finalCount" to finalCount,
            "droppedFrames" to (gate["droppedFrames"] as? Number)?.toLong().orZero(),
            "modelChecksum" to resolution.checksum,
            "lastPartial" to lastPartial,
            "lastLocale" to lastLocale,
            "lastMode" to lastMode,
            "modelAssetPath" to resolution.modelAssetPath,
            "decoderAssetPath" to resolution.decoderAssetPath,
            "tokenAssetPath" to resolution.tokenAssetPath,
            "configAssetPath" to resolution.configAssetPath,
            "vadEngine" to (gate["vadEngine"] ?: "unknown"),
            "vadReady" to (gate["vadReady"] ?: false),
            "vadQueuedSpeechSegments" to (gate["queuedSpeechSegments"] ?: 0),
            "lastDecodeDurationMs" to lastDecodeDurationMs,
            "lastDecodeStartedAt" to lastDecodeStartedAt,
            "lastDecodeFinishedAt" to lastDecodeFinishedAt,
            "partialDecodeCount" to partialDecodeCount,
            "finalDecodeCount" to finalDecodeCount,
            "blankSegmentCount" to blankSegmentCount,
            "recognizerThreads" to resolveRecognizerThreadCount(),
            "decodePolicy" to "silero_segment_once_partial_throttled",
            "identityEvidencePolicy" to "same_vad_segment_private_wav",
            "lastIdentityAudioPath" to lastIdentityAudioPath,
        )
    }

    private fun startContinuousLoop(
        onEvent: (String, NovaStreamingAsrResult, String) -> Unit,
    ) {
        if (!continuousLoopRunning.compareAndSet(false, true)) return
        Thread {
            try {
                while (session.running) {
                    if (session.paused) {
                        Thread.sleep(80L)
                        continue
                    }
                    val completed = NovaStreamingVoiceGate.takeCompletedSpeechPcm(28)
                    if (completed.isNotEmpty()) {
                        decodeFinalSegment(completed, onEvent)
                        continue
                    }
                    maybeDecodePartial(onEvent)
                    Thread.sleep(55L)
                }
            } catch (t: InterruptedException) {
                Thread.currentThread().interrupt()
            } catch (t: Throwable) {
                lastError = t.message ?: "Whisper + Silero sürekli ASR döngüsü durdu."
                onEvent("error", emptyResult(), lastError)
            } finally {
                continuousLoopRunning.set(false)
            }
        }.apply {
            name = "NovaWhisperVadLoop"
            isDaemon = true
            start()
        }
    }

    private fun maybeDecodePartial(
        onEvent: (String, NovaStreamingAsrResult, String) -> Unit,
    ) {
        val gate = NovaStreamingVoiceGate.stateMap()
        if (gate["speechActive"] != true || transcriptionInFlight.get()) return
        val sampleCount = (gate["bufferedPcmSamples"] as? Number)?.toInt() ?: 0
        if (sampleCount < config.sampleRate) return
        val now = SystemClock.elapsedRealtime()
        if (now - lastPartialDecodeAt < PARTIAL_DECODE_INTERVAL_MS) return
        if (sampleCount - lastPartialSampleCount < config.sampleRate / 2) return
        val samples = NovaStreamingVoiceGate.snapshotRecentPcm(PARTIAL_WINDOW_SECONDS)
        if (samples.size < config.sampleRate) return
        if (!transcriptionInFlight.compareAndSet(false, true)) return

        lastPartialDecodeAt = now
        lastPartialSampleCount = sampleCount
        partialDecodeCount += 1
        try {
            val transcript = decodeSamplesWithSherpa(samples, modelLocator.resolve())
            val stabilized = stabilizer.stabilize(transcript?.text.orEmpty()).trim()
            if (stabilized.isBlank() || stabilized == lastPartial) return
            lastPartial = stabilized
            lastLocale = transcript?.locale?.ifBlank { "tr-TR" } ?: "tr-TR"
            partialCount += 1
            lastMode = "embedded_whisper_partial"
            onEvent(
                "partial",
                NovaStreamingAsrResult(
                    text = stabilized,
                    isFinal = false,
                    confidence = 0.78f,
                    segmentId = session.segmentId,
                    startMs = 0,
                    endMs = samplesToMs(samples.size),
                    locale = lastLocale,
                    identityAudioPath = "",
                ),
                "Silero aktif konuşma penceresinden throttled Whisper partial hazır.",
            )
        } finally {
            transcriptionInFlight.set(false)
        }
    }

    private fun decodeFinalSegment(
        samples: ShortArray,
        onEvent: (String, NovaStreamingAsrResult, String) -> Unit,
    ) {
        if (samples.size < config.sampleRate / 12) return
        if (!transcriptionInFlight.compareAndSet(false, true)) return
        val segmentId = session.segmentId
        finalDecodeCount += 1
        try {
            val transcript = decodeSamplesWithSherpa(samples, modelLocator.resolve())
            val finalText = transcript?.text.orEmpty().trim()
            if (finalText.isBlank()) {
                blankSegmentCount += 1
                lastMode = "embedded_whisper_blank_segment"
                return
            }
            val identityAudioPath = NovaAsrSegmentWavStore.write(
                context = context,
                samples = samples,
                segmentId = segmentId,
            )
            lastIdentityAudioPath = identityAudioPath
            lastPartial = finalText
            lastLocale = transcript?.locale?.ifBlank { "tr-TR" } ?: "tr-TR"
            finalCount += 1
            lastMode = "embedded_whisper_vad_final"
            lastError = ""
            onEvent(
                "final",
                NovaStreamingAsrResult(
                    text = finalText,
                    isFinal = true,
                    confidence = 0.91f,
                    segmentId = segmentId,
                    startMs = 0,
                    endMs = samplesToMs(samples.size),
                    locale = lastLocale,
                    identityAudioPath = identityAudioPath,
                ),
                if (identityAudioPath.isNotEmpty()) {
                    "Silero segmenti Whisper ile bir kez çözüldü; aynı PCM TitaNet kanıtına bağlandı."
                } else {
                    "Silero segmenti çözüldü fakat TitaNet ses kanıtı dosyası oluşturulamadı."
                },
            )
            session.finalizeSegment()
        } finally {
            stabilizer.reset()
            lastPartial = ""
            lastPartialDecodeAt = 0L
            lastPartialSampleCount = 0
            transcriptionInFlight.set(false)
        }
    }

    private fun warmupRecognizer(
        resolution: NovaAsrModelLocator.ModelResolution,
    ): Boolean {
        synchronized(recognizerLock) {
            if (recognizer != null) return true
            if (!resolution.modelReady) return false
            return try {
                recognizer = OfflineRecognizer(
                    context.assets,
                    buildRecognizerConfig(resolution),
                )
                true
            } catch (t: Throwable) {
                recognizer = null
                lastError = "Whisper recognizer warmup hatası: ${t.message ?: t.javaClass.simpleName}"
                false
            }
        }
    }

    private fun buildRecognizerConfig(
        resolution: NovaAsrModelLocator.ModelResolution,
    ): OfflineRecognizerConfig {
        val whisperConfig = OfflineWhisperModelConfig().apply {
            encoder = resolution.modelAssetPath.ifBlank { "sherpa_asr/encoder.onnx" }
            decoder = resolution.decoderAssetPath.ifBlank {
                inferDecoderAssetPath(resolution.modelAssetPath)
            }
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
            numThreads = resolveRecognizerThreadCount()
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
            maxActivePaths = max(2, config.beamSize)
        }
    }

    private fun decodeSamplesWithSherpa(
        samples: ShortArray,
        resolution: NovaAsrModelLocator.ModelResolution,
    ): DecodeOutput? {
        if (samples.isEmpty()) return null
        val localRecognizer = synchronized(recognizerLock) {
            if (recognizer == null && !warmupRecognizer(resolution)) return null
            recognizer
        } ?: return null
        return synchronized(decodeLock) {
            val startedAt = SystemClock.elapsedRealtime()
            lastDecodeStartedAt = startedAt
            try {
                val stream = localRecognizer.createStream()
                try {
                    val floatSamples = FloatArray(samples.size) { index ->
                        samples[index] / 32768.0f
                    }
                    stream.acceptWaveform(floatSamples, config.sampleRate)
                    localRecognizer.decode(stream)
                    val result = localRecognizer.getResult(stream)
                    val locale = result.lang.takeIf { it.isNotBlank() } ?: "tr-TR"
                    DecodeOutput(
                        text = result.text.trim(),
                        locale = locale,
                        message = "Embedded Whisper ${samples.size} örneği çözdü.",
                    )
                } finally {
                    stream.release()
                }
            } catch (t: Throwable) {
                lastError = "Embedded Whisper decode hatası: ${t.message ?: t.javaClass.simpleName}"
                null
            } finally {
                lastDecodeFinishedAt = SystemClock.elapsedRealtime()
                lastDecodeDurationMs = lastDecodeFinishedAt - startedAt
            }
        }
    }

    private fun inferDecoderAssetPath(modelAssetPath: String): String {
        return if (modelAssetPath.contains("encoder.onnx")) {
            modelAssetPath.replace("encoder.onnx", "decoder.onnx")
        } else {
            "sherpa_asr/decoder.onnx"
        }
    }

    private fun resolveRecognizerThreadCount(): Int {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        val memoryClassMb = manager?.memoryClass ?: 256
        val cores = Runtime.getRuntime().availableProcessors().coerceAtLeast(1)
        return if (memoryClassMb >= 256 && cores >= 6) 2 else 1
    }

    private fun resetTurnState() {
        stabilizer.reset()
        lastPartial = ""
        lastPartialDecodeAt = 0L
        lastPartialSampleCount = 0
        lastDecodeStartedAt = 0L
        lastDecodeFinishedAt = 0L
        lastDecodeDurationMs = 0L
        lastIdentityAudioPath = ""
    }

    private fun emptyResult(): NovaStreamingAsrResult {
        return NovaStreamingAsrResult(
            text = "",
            isFinal = false,
            confidence = 0f,
            segmentId = session.segmentId,
            startMs = 0,
            endMs = 0,
            locale = lastLocale,
            identityAudioPath = "",
        )
    }

    private fun samplesToMs(sampleCount: Int): Int {
        return ((sampleCount.toLong() * 1000L) / config.sampleRate)
            .coerceAtMost(Int.MAX_VALUE.toLong())
            .toInt()
    }

    private fun Number?.orZero(): Long = this?.toLong() ?: 0L

    private data class DecodeOutput(
        val text: String,
        val locale: String,
        val message: String,
    )

    companion object {
        private const val PARTIAL_DECODE_INTERVAL_MS = 2_800L
        private const val PARTIAL_WINDOW_SECONDS = 6
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
        lastError = map["message"] as? String ?: "",
        foregroundServiceRunning = map["foregroundServiceRunning"] as? Boolean
            ?: false,
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
            append("- tek mikrofon sahibi ve tek embedded ASR otoritesi\n")
            append("- Silero VAD sessizlikte Whisper decode başlatmaz\n")
            append("- tamamlanan konuşma segmenti yalnız bir kez final decode edilir\n")
            append("- final transcript ve TitaNet aynı PCM segmentini kullanır\n")
            append("- partial decode cihaz yükünü korumak için throttled çalışır")
        }
    }
}

data class NovaStreamingAsrCrowdHint(
    val locale: String,
    val prefersShortBackchannels: Boolean,
    val shouldStayOpenMic: Boolean,
)

object NovaStreamingAsrCrowdHintResolver {
    fun build(
        locale: String,
        continuousListeningEnabled: Boolean,
    ): NovaStreamingAsrCrowdHint {
        return NovaStreamingAsrCrowdHint(
            locale = locale,
            prefersShortBackchannels = locale.startsWith("tr", ignoreCase = true),
            shouldStayOpenMic = continuousListeningEnabled,
        )
    }
}
