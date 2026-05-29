package com.example.nova.asr

import android.content.Context
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.security.MessageDigest

class NovaAsrModelLocator(private val context: Context) {
    data class ModelResolution(
        val modelFile: File?,
        val configFile: File?,
        val tokenFile: File?,
        val decoderFile: File?,
        val checksum: String,
        val modelReady: Boolean,
        val singleAuthorityConfirmed: Boolean,
        val message: String,
        val modelAssetPath: String,
        val decoderAssetPath: String,
        val tokenAssetPath: String,
        val configAssetPath: String,
    )

    private data class AssetSpec(
        val assetPath: String,
        val targetFileName: String,
    )

    fun resolve(): ModelResolution {
        val root = File(context.filesDir, "nova_models/asr")
        if (!root.exists()) root.mkdirs()

        val configAssetPath = findFirstExistingAsset(
            listOf(
                "sherpa_asr/config.json",
                "sherpa_asr/config",
                "sherpa_asr/CONFIG",
                "sherpa_asr/CONFIG.json",
                "nova_asr/config.json",
                "nova_asr/config",
                "nova_asr/CONFIG",
                "models/asr/config.json",
                "models/asr/config",
                "models/asr/CONFIG",
                "flutter_assets/assets/models/asr/config.json",
                "flutter_assets/assets/models/asr/config",
                "flutter_assets/assets/models/asr/CONFIG",
            )
        )
        val tokenAssetPath = findFirstExistingAsset(
            listOf(
                "sherpa_asr/tokens.txt",
                "sherpa_asr/tokens",
                "sherpa_asr/TOKEN",
                "sherpa_asr/TOKENS",
                "sherpa_asr/token.txt",
                "nova_asr/tokens.txt",
                "nova_asr/tokens",
                "nova_asr/TOKEN",
                "models/asr/tokens.txt",
                "models/asr/tokens",
                "models/asr/TOKEN",
                "flutter_assets/assets/models/asr/tokens.txt",
                "flutter_assets/assets/models/asr/tokens",
                "flutter_assets/assets/models/asr/TOKEN",
            )
        )

        val config = configAssetPath?.let {
            ensureAsset(it, File(root, "config.json"))
        }
        val tokens = tokenAssetPath?.let {
            ensureAsset(it, File(root, "tokens.txt"))
        }

        val configuredModelSpecs = readConfiguredModelSpecs(configAssetPath)
        val modelSpec = findFirstExistingSpec(
            configuredModelSpecs.ifEmpty { defaultModelSpecs() }
        )
        val model = modelSpec?.let {
            ensureAsset(it.assetPath, File(root, it.targetFileName))
        }
        val decoderSpec = configuredModelSpecs
            .firstOrNull { it.assetPath.substringAfterLast('/').contains("decoder", ignoreCase = true) }
            ?: findFirstExistingSpec(
                listOf(
                    AssetSpec("sherpa_asr/decoder.onnx", "decoder.onnx"),
                    AssetSpec("sherpa_asr/DECODER.onnx", "decoder.onnx"),
                    AssetSpec("nova_asr/decoder.onnx", "decoder.onnx"),
                    AssetSpec("nova_asr/DECODER.onnx", "decoder.onnx"),
                    AssetSpec("models/asr/decoder.onnx", "decoder.onnx"),
                    AssetSpec("models/asr/DECODER.onnx", "decoder.onnx"),
                    AssetSpec("flutter_assets/assets/models/asr/decoder.onnx", "decoder.onnx"),
                    AssetSpec("flutter_assets/assets/models/asr/DECODER.onnx", "decoder.onnx"),
                )
            )
        val decoder = decoderSpec?.let {
            ensureAsset(it.assetPath, File(root, it.targetFileName))
        }

        val checksum = if (model?.exists() == true) digest(model) else ""
        val configJson = config?.takeIf { it.exists() }?.readText().orEmpty().lowercase()
        val modelType = if (configJson.contains("\"model_type\": \"whisper\"")) "whisper" else "generic"
        val whisperReady = modelType != "whisper" || (
            config?.exists() == true &&
                tokens?.exists() == true &&
                model?.exists() == true &&
                decoder?.exists() == true
        )
        val ready = model?.exists() == true && config?.exists() == true && tokens?.exists() == true && whisperReady
        val singleAuthorityConfirmed = true
        val sourceLabel = when {
            modelSpec?.assetPath?.startsWith("sherpa_asr/") == true -> "native sherpa_asr"
            modelSpec?.assetPath?.startsWith("nova_asr/") == true -> "native nova_asr"
            modelSpec?.assetPath?.startsWith("models/asr/") == true -> "native models/asr"
            modelSpec?.assetPath?.startsWith("flutter_assets/") == true -> "flutter_assets"
            else -> "missing"
        }

        return ModelResolution(
            modelFile = model,
            configFile = config,
            tokenFile = tokens,
            decoderFile = decoder,
            checksum = checksum,
            modelReady = ready,
            singleAuthorityConfirmed = singleAuthorityConfirmed,
            message = if (ready) {
                "Embedded ASR modeli bulundu ($sourceLabel, modelType=$modelType, decoder=${decoderSpec?.assetPath.orEmpty()})."
            } else {
                "Embedded ASR modeli eksik ya da eksik dosyalı; tek otorite streaming zinciri için whisper encoder+decoder+config+token dörtlüsü tamamlanmalı."
            },
            modelAssetPath = modelSpec?.assetPath.orEmpty(),
            decoderAssetPath = decoderSpec?.assetPath.orEmpty(),
            tokenAssetPath = tokenAssetPath.orEmpty(),
            configAssetPath = configAssetPath.orEmpty(),
        )
    }

    private fun defaultModelSpecs(): List<AssetSpec> {
        val paths = listOf(
            "sherpa_asr/model.onnx",
            "sherpa_asr/model.int8.onnx",
            "sherpa_asr/encoder.onnx",
            "sherpa_asr/ENCODER.onnx",
            "sherpa_asr/decoder.onnx",
            "sherpa_asr/DECODER.onnx",
            "sherpa_asr/joiner.onnx",
            "sherpa_asr/JOINER.onnx",
            "nova_asr/model.onnx",
            "nova_asr/model.int8.onnx",
            "nova_asr/encoder.onnx",
            "nova_asr/ENCODER.onnx",
            "nova_asr/decoder.onnx",
            "nova_asr/DECODER.onnx",
            "nova_asr/joiner.onnx",
            "nova_asr/JOINER.onnx",
            "models/asr/model.onnx",
            "models/asr/model.int8.onnx",
            "models/asr/model.tflite",
            "models/asr/model.bin",
            "flutter_assets/assets/models/asr/model.onnx",
            "flutter_assets/assets/models/asr/model.tflite",
            "flutter_assets/assets/models/asr/model.bin",
        )
        return paths.map { AssetSpec(assetPath = it, targetFileName = it.substringAfterLast('/')) }
    }

    private fun readConfiguredModelSpecs(configAssetPath: String?): List<AssetSpec> {
        if (configAssetPath.isNullOrBlank()) return emptyList()
        return try {
            val jsonText = context.assets.open(configAssetPath).bufferedReader().use { it.readText() }
            val json = JSONObject(jsonText)
            val specs = mutableListOf<AssetSpec>()
            val configBaseDir = configAssetPath.substringBeforeLast('/', "")

            val directFields = listOf(
                "model",
                "model_path",
                "encoder",
                "decoder",
                "joiner",
            )
            for (field in directFields) {
                val value = json.optString(field).trim()
                if (value.isNotEmpty()) {
                    specs += normalizeAssetSpec(value, configBaseDir)
                }
            }

            val arrayFields = listOf("asset_candidates", "model_candidates")
            for (field in arrayFields) {
                val array = json.optJSONArray(field) ?: continue
                for (i in 0 until array.length()) {
                    val value = array.optString(i).trim()
                    if (value.isNotEmpty()) {
                        specs += normalizeAssetSpec(value, configBaseDir)
                    }
                }
            }
            specs.distinctBy { it.assetPath }
        } catch (_: Throwable) {
            emptyList()
        }
    }

    private fun normalizeAssetSpec(rawPath: String, configBaseDir: String = ""): AssetSpec {
        val clean = rawPath.removePrefix("assets/").removePrefix("/")
        val baseDir = configBaseDir.removePrefix("assets/").removePrefix("/").trim('/')
        val candidatePaths = when {
            clean.startsWith("flutter_assets/") -> listOf(clean)
            clean.startsWith("sherpa_asr/") || clean.startsWith("nova_asr/") || clean.startsWith("models/asr/") -> listOf(clean)
            else -> {
                val candidates = mutableListOf<String>()
                if (baseDir.isNotEmpty()) candidates += "$baseDir/$clean"
                candidates += clean
                candidates += "sherpa_asr/$clean"
                candidates += "nova_asr/$clean"
                candidates += "models/asr/$clean"
                candidates += "flutter_assets/assets/models/asr/$clean"
                candidates
            }
        }
        val first = candidatePaths.first()
        return AssetSpec(assetPath = first, targetFileName = first.substringAfterLast('/'))
    }

    private fun findFirstExistingSpec(specs: List<AssetSpec>): AssetSpec? {
        for (spec in specs) {
            val existingPath = findFirstExistingAsset(listOf(spec.assetPath))
            if (!existingPath.isNullOrBlank()) {
                return spec.copy(assetPath = existingPath)
            }
        }
        return null
    }

    private fun findFirstExistingAsset(paths: List<String>): String? {
        for (path in paths) {
            try {
                context.assets.open(path).close()
                return path
            } catch (_: Throwable) {
            }
        }
        return null
    }

    private fun ensureAsset(assetPath: String, target: File): File? {
        return try {
            if (target.exists() && target.length() > 0L) return target
            target.parentFile?.mkdirs()
            context.assets.open(assetPath).use { input ->
                FileOutputStream(target).use { output -> input.copyTo(output) }
            }
            target
        } catch (_: Throwable) {
            if (target.exists()) target else null
        }
    }

    private fun digest(file: File): String {
        val md = MessageDigest.getInstance("SHA-256")
        file.inputStream().use { input ->
            val buffer = ByteArray(8192)
            while (true) {
                val read = input.read(buffer)
                if (read <= 0) break
                md.update(buffer, 0, read)
            }
        }
        return md.digest().joinToString("") { "%02x".format(it) }
    }
}
