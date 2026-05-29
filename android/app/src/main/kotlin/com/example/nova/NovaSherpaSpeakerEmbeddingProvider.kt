package com.example.nova

import android.content.Context
import com.k2fsa.sherpa.onnx.SpeakerEmbeddingExtractor
import com.k2fsa.sherpa.onnx.SpeakerEmbeddingExtractorConfig
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder

class NovaSherpaSpeakerEmbeddingProvider(
    private val context: Context,
    private val modelPath: String,
    private val assetModelPath: String = "",
) : NovaSpeakerRecognitionEngine.EmbeddingProvider {

    @Volatile
    private var extractor: SpeakerEmbeddingExtractor? = null

    private val lock = Any()

    override fun isReady(): Boolean {
        return extractor != null
    }

    override fun warmup(): Boolean {
        synchronized(lock) {
            if (extractor != null) {
                return true
            }

            val normalizedAssetPath = assetModelPath.trim()
            val file = File(modelPath)

            val assetReady = normalizedAssetPath.isNotEmpty() && hasAsset(normalizedAssetPath)
            val fileReady = file.exists() && file.isFile
            if (!assetReady && !fileReady) {
                return false
            }

            return try {
                val preferredModel = if (assetReady) {
                    normalizedAssetPath
                } else {
                    modelPath
                }

                val config = SpeakerEmbeddingExtractorConfig(
                    model = preferredModel,
                    numThreads = 2,
                    debug = false,
                    provider = "cpu",
                )

                extractor = SpeakerEmbeddingExtractor(
                    context.assets,
                    config,
                )
                true
            } catch (_: Throwable) {
                if (!fileReady || assetReady) {
                    extractor = null
                    false
                } else {
                    try {
                        val config = SpeakerEmbeddingExtractorConfig(
                            model = modelPath,
                            numThreads = 2,
                            debug = false,
                            provider = "cpu",
                        )
                        extractor = SpeakerEmbeddingExtractor(
                            context.assets,
                            config,
                        )
                        true
                    } catch (_: Throwable) {
                        extractor = null
                        false
                    }
                }
            }
        }
    }

    override fun extractEmbeddingFromFile(audioPath: String): FloatArray? {
        val normalized = audioPath.trim()
        if (normalized.isEmpty()) return null

        val file = NovaAppSandboxGuard.resolveAppPrivateFileOrNull(context, normalized)
            ?: return null
        if (!file.exists() || !file.isFile) return null

        return try {
            val wav = readWavPcm16(file) ?: return null
            extractEmbeddingFromBytes(
                audioBytes = wav.pcmBytes,
                sampleRate = wav.sampleRate,
            )
        } catch (_: Throwable) {
            null
        }
    }

    override fun extractEmbeddingFromBytes(
        audioBytes: ByteArray,
        sampleRate: Int,
    ): FloatArray? {
        if (audioBytes.isEmpty()) return null
        if (sampleRate <= 0) return null

        if (!isReady()) {
          val ok = warmup()
          if (!ok) return null
        }

        val localExtractor = extractor ?: return null

        return try {
            val samples = pcm16LeMonoToFloatArray(audioBytes)
            if (samples.isEmpty()) return null

            val stream = localExtractor.createStream()
            stream.acceptWaveform(
                samples,
                sampleRate,
            )

            if (!localExtractor.isReady(stream)) {
                return null
            }

            localExtractor.compute(stream)
        } catch (_: Throwable) {
            null
        }
    }

    fun release() {
        synchronized(lock) {
            try {
                extractor?.release()
            } catch (_: Throwable) {
            } finally {
                extractor = null
            }
        }
    }

    private data class WavPcmData(
        val pcmBytes: ByteArray,
        val sampleRate: Int,
    )

    private fun hasAsset(assetPath: String): Boolean {
        return try {
            context.assets.open(assetPath).close()
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun readWavPcm16(file: File): WavPcmData? {
        val bytes = file.readBytes()
        if (bytes.size < 44) return null

        val header = String(bytes, 0, 4)
        val wave = String(bytes, 8, 4)
        if (header != "RIFF" || wave != "WAVE") {
            return null
        }

        var offset = 12
        var audioFormat = -1
        var channels = -1
        var sampleRate = -1
        var bitsPerSample = -1
        var dataOffset = -1
        var dataSize = -1

        while (offset + 8 <= bytes.size) {
            val chunkId = String(bytes, offset, 4)
            val chunkSize = littleEndianInt(bytes, offset + 4)
            val chunkDataStart = offset + 8

            if (chunkDataStart + chunkSize > bytes.size) {
                return null
            }

            when (chunkId) {
                "fmt " -> {
                    if (chunkSize < 16) return null
                    audioFormat = littleEndianShort(bytes, chunkDataStart).toInt()
                    channels = littleEndianShort(bytes, chunkDataStart + 2).toInt()
                    sampleRate = littleEndianInt(bytes, chunkDataStart + 4)
                    bitsPerSample = littleEndianShort(bytes, chunkDataStart + 14).toInt()
                }
                "data" -> {
                    dataOffset = chunkDataStart
                    dataSize = chunkSize
                }
            }

            offset = chunkDataStart + chunkSize + (chunkSize % 2)
        }

        if (audioFormat != 1) return null
        if (channels <= 0) return null
        if (sampleRate <= 0) return null
        if (bitsPerSample != 16) return null
        if (dataOffset < 0 || dataSize <= 0) return null
        if (dataOffset + dataSize > bytes.size) return null

        val rawPcm = bytes.copyOfRange(dataOffset, dataOffset + dataSize)
        val monoPcm = if (channels == 1) {
            rawPcm
        } else {
            downmixPcm16ToMono(rawPcm, channels)
        }

        return WavPcmData(
            pcmBytes = monoPcm,
            sampleRate = sampleRate,
        )
    }

    private fun downmixPcm16ToMono(bytes: ByteArray, channels: Int): ByteArray {
        if (channels <= 1) return bytes
        val frameSize = channels * 2
        val frameCount = bytes.size / frameSize
        val out = ByteArray(frameCount * 2)

        var inOffset = 0
        var outOffset = 0

        repeat(frameCount) {
            var sum = 0
            repeat(channels) { channelIndex ->
                val sampleOffset = inOffset + (channelIndex * 2)
                sum += littleEndianShort(bytes, sampleOffset).toInt()
            }
            val averaged = (sum / channels).coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
            out[outOffset] = (averaged.toInt() and 0xff).toByte()
            out[outOffset + 1] = ((averaged.toInt() shr 8) and 0xff).toByte()

            inOffset += frameSize
            outOffset += 2
        }

        return out
    }

    private fun pcm16LeMonoToFloatArray(bytes: ByteArray): FloatArray {
        if (bytes.size < 2) return FloatArray(0)

        val size = bytes.size / 2
        val output = FloatArray(size)

        var outIndex = 0
        var i = 0
        while (i + 1 < bytes.size) {
            val sample = littleEndianShort(bytes, i)
            output[outIndex] = (sample / 32768.0f).coerceIn(-1.0f, 1.0f)
            outIndex++
            i += 2
        }

        return output
    }

    private fun littleEndianInt(bytes: ByteArray, offset: Int): Int {
        return ByteBuffer.wrap(bytes, offset, 4)
            .order(ByteOrder.LITTLE_ENDIAN)
            .int
    }

    private fun littleEndianShort(bytes: ByteArray, offset: Int): Short {
        return ByteBuffer.wrap(bytes, offset, 2)
            .order(ByteOrder.LITTLE_ENDIAN)
            .short
    }
}