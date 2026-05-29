package com.example.nova

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

class NovaVoiceIdentityBridgePlugin(
    private val context: Context,
) : MethodChannel.MethodCallHandler {

    @Volatile
    private var engine: NovaSpeakerRecognitionEngine? = null

    companion object {
        private const val CHANNEL = "nova/voice_identity_bridge"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context,
        ) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            channel.setMethodCallHandler(
                NovaVoiceIdentityBridgePlugin(context)
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "warmupVoiceIdentity" -> {
                    val ok = preflightWarmup()
                    result.success(
                        mapOf(
                            "success" to ok,
                            "message" to if (ok) {
                                "Ses kimliği motoru hazır."
                            } else {
                                "Ses kimliği motoru hazırlanamadı."
                            }
                        )
                    )
                }

                "enrollVoiceprintFromFile" -> {
                    val voiceId = call.argument<String>("voiceId").orEmpty()
                    val displayName = call.argument<String>("displayName").orEmpty()
                    val audioPath = call.argument<String>("audioPath").orEmpty()

                    val enrollResult = getOrCreateEngine().enrollFromFile(
                        voiceId = voiceId,
                        displayName = displayName,
                        audioPath = audioPath,
                    )

                    result.success(
                        mapOf(
                            "success" to enrollResult.success,
                            "voiceId" to enrollResult.voiceId,
                            "displayName" to enrollResult.displayName,
                            "message" to enrollResult.message,
                            "embeddingSize" to enrollResult.embeddingSize,
                        )
                    )
                }

                "identifyVoiceFromFile" -> {
                    val audioPath = call.argument<String>("audioPath").orEmpty()
                    val minSimilarity =
                        (call.argument<Double>("minSimilarity") ?: 0.64).toFloat()

                    val identifyResult = getOrCreateEngine().identifyFromFile(
                        audioPath = audioPath,
                        minSimilarity = minSimilarity,
                    )

                    result.success(
                        mapOf(
                            "success" to identifyResult.success,
                            "matched" to identifyResult.matched,
                            "voiceId" to identifyResult.voiceId,
                            "displayName" to identifyResult.displayName,
                            "similarity" to identifyResult.similarity.toDouble(),
                            "message" to identifyResult.message,
                            "embeddingSize" to identifyResult.embeddingSize,
                        )
                    )
                }

                "removeVoiceprint" -> {
                    val voiceId = call.argument<String>("voiceId").orEmpty()
                    val removed = getOrCreateEngine().removeVoiceprint(voiceId)

                    result.success(
                        mapOf(
                            "success" to removed,
                            "message" to if (removed) {
                                "Voiceprint silindi."
                            } else {
                                "Voiceprint silinemedi."
                            }
                        )
                    )
                }

                "clearAllVoiceprints" -> {
                    val cleared = getOrCreateEngine().clearAllVoiceprints()

                    result.success(
                        mapOf(
                            "success" to cleared,
                            "message" to if (cleared) {
                                "Tüm voiceprint kayıtları temizlendi."
                            } else {
                                "Voiceprint kayıtları temizlenemedi."
                            }
                        )
                    )
                }

                "getRegisteredVoiceCount" -> {
                    val count = getOrCreateEngine().getRegisteredVoiceCount()
                    result.success(
                        mapOf(
                            "success" to true,
                            "count" to count,
                            "message" to "Kayıtlı ses sayısı alındı."
                        )
                    )
                }

                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.success(
                mapOf(
                    "success" to false,
                    "message" to "Voice identity bridge hatası: ${t.message ?: "unknown"}"
                )
            )
        }
    }


    private fun preflightWarmup(): Boolean {
        return try {
            ensureSpeakerModelFile()
            getOrCreateEngine()
            true
        } catch (_: Throwable) {
            false
        }
    }

    private fun getOrCreateEngine(): NovaSpeakerRecognitionEngine {
        val existing = engine
        if (existing != null) {
            return existing
        }

        synchronized(this) {
            val second = engine
            if (second != null) {
                return second
            }

            val modelFile = ensureSpeakerModelFile()
            val assetModelPath = resolveSpeakerModelAssetPath()
            val provider = NovaSherpaSpeakerEmbeddingProvider(
                context = context,
                modelPath = modelFile.absolutePath,
                assetModelPath = assetModelPath,
            )
            val store = NovaVoiceprintStore(context)

            val created = NovaSpeakerRecognitionEngine(
                voiceprintStore = store,
                embeddingProvider = provider,
            )

            engine = created
            return created
        }
    }

    private fun resolveSpeakerModelAssetPath(): String {
        val assetCandidates = listOf(
            "speaker_id/nemo_en_titanet_small.onnx",
            "speaker_id/nemo_titanet_small/nemo_en_titanet_small.onnx",
            "models/speaker_id/nemo_en_titanet_small.onnx",
            "models/voice_id/nemo_en_titanet_small.onnx",
            "voice_id/nemo_en_titanet_small.onnx",
            "nemo_en_titanet_small.onnx",
        )
        for (assetPath in assetCandidates) {
            try {
                context.assets.open(assetPath).close()
                return assetPath
            } catch (_: Throwable) {
            }
        }
        return ""
    }

    private fun ensureSpeakerModelFile(): File {
        val outDir = File(context.filesDir, "nova_speaker_models").apply {
            if (!exists()) {
                mkdirs()
            }
        }

        val outFile = File(outDir, "nemo_en_titanet_small.onnx")
        if (outFile.exists() && outFile.length() > 1024L) {
            return outFile
        }

        if (outFile.exists()) {
            outFile.delete()
        }

        val assetCandidates = listOf(
            "speaker_id/nemo_en_titanet_small.onnx",
            "speaker_id/nemo_titanet_small/nemo_en_titanet_small.onnx",
            "models/speaker_id/nemo_en_titanet_small.onnx",
            "models/voice_id/nemo_en_titanet_small.onnx",
            "voice_id/nemo_en_titanet_small.onnx",
            "nemo_en_titanet_small.onnx",
        )

        var copied = false
        var lastError: Throwable? = null
        for (assetPath in assetCandidates) {
            try {
                context.assets.open(assetPath).use { input ->
                    outFile.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
                copied = outFile.exists() && outFile.length() > 1024L
                if (copied) {
                    break
                }
            } catch (t: Throwable) {
                lastError = t
            }
        }

        if (!copied) {
            throw IllegalStateException(lastError?.message ?: "Speaker model asset bulunamadı.")
        }

        return outFile
    }
}