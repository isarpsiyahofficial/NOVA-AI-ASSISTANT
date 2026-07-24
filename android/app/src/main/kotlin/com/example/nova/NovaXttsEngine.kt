package com.example.nova

import android.app.ActivityManager
import android.content.Context
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import com.k2fsa.sherpa.onnx.OfflineTts
import com.k2fsa.sherpa.onnx.OfflineTtsConfig
import com.k2fsa.sherpa.onnx.OfflineTtsModelConfig
import com.k2fsa.sherpa.onnx.OfflineTtsVitsModelConfig
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.max
import kotlin.math.min

/**
 * Deterministic offline Turkish mouth for Nova.
 *
 * Despite the historical class/channel name, this is no longer an XTTS or
 * Android TextToSpeech wrapper. It owns one sherpa-onnx OfflineTts instance and
 * plays generated PCM directly through AudioTrack. Android platform TTS remains
 * an explicit bridge-level fallback only.
 */
class NovaXttsEngine(
    private val context: Context
) {
    private val engineLock = Any()
    private val playbackLock = Any()
    private val stopRequested = AtomicBoolean(false)

    @Volatile private var engine: OfflineTts? = null
    @Volatile private var activeTrack: AudioTrack? = null
    @Volatile private var warmedUp: Boolean = false
    @Volatile private var lastMessage: String = "Sherpa offline Türkçe TTS henüz hazırlanmadı."
    @Volatile private var lastSampleRate: Int = 0
    @Volatile private var lastGeneratedSamples: Int = 0
    @Volatile private var lastRealTimeFactor: Double = 0.0

    private val modelPath = "sherpa_tts/model.onnx"
    private val tokensPath = "sherpa_tts/tokens.txt"
    private val dataDir = "sherpa_tts/espeak-ng-data"

    fun isReady(): Boolean = warmedUp && engine != null

    fun getCapabilities(): Map<String, Any> {
        val assetsReady = requiredAssetsReady()
        return mapOf(
            "ready" to isReady(),
            "assetReady" to assetsReady,
            "currentModelKey" to "sherpa_piper_tr_offline",
            "assetDir" to "sherpa_tts",
            "modelFileName" to "model.onnx",
            "tokensFileName" to "tokens.txt",
            "supportsSpeakerId" to false,
            "supportsReferenceAudio" to false,
            "availableModels" to if (assetsReady) {
                listOf("sherpa_piper_tr_offline")
            } else {
                emptyList<String>()
            },
            "engine" to "sherpa_onnx_offline_tts",
            "sampleRate" to lastSampleRate,
            "lastGeneratedSamples" to lastGeneratedSamples,
            "lastRealTimeFactor" to lastRealTimeFactor,
            "message" to lastMessage,
        )
    }

    fun warmup(preferredModelKey: String = "sherpa_piper_tr_offline"): Boolean {
        if (isReady()) return true
        synchronized(engineLock) {
            if (isReady()) return true
            if (!requiredAssetsReady()) {
                warmedUp = false
                lastMessage = "Sherpa Türkçe TTS asset seti eksik: model, tokens veya espeak-ng-data bulunamadı."
                return false
            }

            return try {
                val vits = OfflineTtsVitsModelConfig().apply {
                    model = modelPath
                    lexicon = ""
                    tokens = tokensPath
                    dataDir = this@NovaXttsEngine.dataDir
                    dictDir = ""
                    noiseScale = 0.667f
                    noiseScaleW = 0.8f
                    lengthScale = 1.0f
                }
                val modelConfig = OfflineTtsModelConfig().apply {
                    this.vits = vits
                    numThreads = resolveThreadCount()
                    debug = false
                    provider = "cpu"
                }
                val config = OfflineTtsConfig().apply {
                    model = modelConfig
                    ruleFsts = ""
                    ruleFars = ""
                    maxNumSentences = 1
                    silenceScale = 0.18f
                }

                engine?.release()
                engine = OfflineTts(context.assets, config)
                lastSampleRate = engine?.sampleRate() ?: 0
                warmedUp = lastSampleRate > 0
                lastMessage = if (warmedUp) {
                    "Sherpa offline Türkçe TTS hazır. model=$preferredModelKey threads=${resolveThreadCount()} sampleRate=$lastSampleRate"
                } else {
                    "Sherpa offline Türkçe TTS örnekleme hızını açamadı."
                }
                warmedUp
            } catch (t: Throwable) {
                try {
                    engine?.release()
                } catch (_: Throwable) {
                }
                engine = null
                warmedUp = false
                lastMessage = "Sherpa offline Türkçe TTS warmup hatası: ${t.message ?: t.javaClass.simpleName}"
                false
            }
        }
    }

    fun speak(
        text: String,
        language: String = "tr",
        speakerPath: String = "",
        speed: Float = 1.0f,
    ): Boolean {
        val prepared = text.replace(Regex("\\s+"), " ").trim()
        if (prepared.isEmpty()) {
            lastMessage = "Boş metin konuşulmadı."
            return false
        }
        if (!language.lowercase().startsWith("tr")) {
            lastMessage = "Paketli offline ses yalnız Türkçe için yapılandırıldı."
            return false
        }
        if (speakerPath.isNotBlank()) {
            // Piper/VITS tek konuşmacılıdır. Bir referans dosyasını klon sesi gibi
            // kabul etmek yerine açıkça desteklenmediğini bildiriyoruz.
            lastMessage = "Piper Türkçe TTS referans ses klonlamayı desteklemiyor."
            return false
        }
        if (!warmup()) return false

        val activeEngine = engine ?: return false
        stopRequested.set(false)
        return synchronized(playbackLock) {
            val generationStarted = System.nanoTime()
            try {
                val generated = activeEngine.generate(
                    prepared,
                    0,
                    speed.coerceIn(0.86f, 1.14f),
                )
                val samples = generated.samples
                val sampleRate = generated.sampleRate
                lastSampleRate = sampleRate
                lastGeneratedSamples = samples.size
                if (samples.isEmpty() || sampleRate <= 0) {
                    lastMessage = "Sherpa TTS boş ses üretti."
                    return@synchronized false
                }

                val generationSeconds = (System.nanoTime() - generationStarted) / 1_000_000_000.0
                val audioSeconds = samples.size.toDouble() / sampleRate.toDouble()
                lastRealTimeFactor = if (audioSeconds > 0.0) generationSeconds / audioSeconds else 0.0

                val played = playFloatPcm(samples, sampleRate)
                lastMessage = if (played) {
                    "Sherpa offline Türkçe TTS konuşmayı tamamladı. rtf=${"%.3f".format(lastRealTimeFactor)}"
                } else if (stopRequested.get()) {
                    "Sherpa offline Türkçe TTS kullanıcı kesmesiyle durdu."
                } else {
                    "Sherpa offline Türkçe TTS PCM oynatmayı tamamlayamadı."
                }
                played
            } catch (t: Throwable) {
                lastMessage = "Sherpa offline Türkçe TTS üretim hatası: ${t.message ?: t.javaClass.simpleName}"
                false
            } finally {
                releaseActiveTrack()
            }
        }
    }

    fun stop() {
        stopRequested.set(true)
        releaseActiveTrack()
    }

    fun release() {
        stop()
        synchronized(engineLock) {
            try {
                engine?.release()
            } catch (_: Throwable) {
            }
            engine = null
            warmedUp = false
            lastMessage = "Sherpa offline Türkçe TTS serbest bırakıldı."
        }
    }

    private fun playFloatPcm(samples: FloatArray, sampleRate: Int): Boolean {
        val minBufferBytes = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_FLOAT,
        )
        if (minBufferBytes <= 0) {
            lastMessage = "AudioTrack geçerli PCM buffer boyutu üretmedi: $minBufferBytes"
            return false
        }

        val track = AudioTrack.Builder()
            .setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ASSISTANCE_ACCESSIBILITY)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
            )
            .setAudioFormat(
                AudioFormat.Builder()
                    .setEncoding(AudioFormat.ENCODING_PCM_FLOAT)
                    .setSampleRate(sampleRate)
                    .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                    .build()
            )
            .setTransferMode(AudioTrack.MODE_STREAM)
            .setBufferSizeInBytes(max(minBufferBytes, 16 * 1024))
            .build()

        activeTrack = track
        track.play()
        var offset = 0
        val chunkSamples = max(1024, min(samples.size, 8192))
        while (offset < samples.size && !stopRequested.get()) {
            val count = min(chunkSamples, samples.size - offset)
            val written = track.write(
                samples,
                offset,
                count,
                AudioTrack.WRITE_BLOCKING,
            )
            if (written <= 0) {
                lastMessage = "AudioTrack PCM write başarısız: $written"
                return false
            }
            offset += written
        }
        return offset >= samples.size && !stopRequested.get()
    }

    private fun releaseActiveTrack() {
        val track = activeTrack
        activeTrack = null
        if (track != null) {
            try {
                track.pause()
            } catch (_: Throwable) {
            }
            try {
                track.flush()
            } catch (_: Throwable) {
            }
            try {
                track.stop()
            } catch (_: Throwable) {
            }
            try {
                track.release()
            } catch (_: Throwable) {
            }
        }
    }

    private fun requiredAssetsReady(): Boolean {
        return assetExists(modelPath) &&
            assetExists(tokensPath) &&
            assetExists("$dataDir/phontab")
    }

    private fun assetExists(path: String): Boolean {
        return try {
            context.assets.open(path).use { input ->
                input.read() >= 0
            }
        } catch (_: Throwable) {
            false
        }
    }

    private fun resolveThreadCount(): Int {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
        val memoryClassMb = activityManager?.memoryClass ?: 256
        val cores = Runtime.getRuntime().availableProcessors().coerceAtLeast(1)
        return when {
            memoryClassMb >= 384 && cores >= 6 -> 2
            else -> 1
        }
    }
}
