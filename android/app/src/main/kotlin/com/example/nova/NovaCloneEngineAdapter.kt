package com.example.nova

import android.content.Context
import java.io.File
import org.json.JSONObject

class NovaCloneEngineAdapter(
    private val context: Context
) {

    fun createClone(
        sourcePath: String,
        suggestedName: String,
        styleInstruction: String
    ): Map<String, Any?> {
        return try {
            val normalizedSource = sourcePath.trim()
            val normalizedName = suggestedName.trim().ifBlank { "Klon Ses" }
            val normalizedStyle = styleInstruction.trim()

            if (normalizedSource.isEmpty()) {
                return mapOf(
                    "success" to false,
                    "message" to "Kaynak ses yolu boş olamaz."
                )
            }

            val sourceDecision = NovaSystemBoundaryGuard.canAccessFile(
                context = context,
                rawReference = normalizedSource,
                operation = "read",
                source = "system_safe",
                ownerApproved = false
            )
            if (!sourceDecision.allowed) {
                return mapOf(
                    "success" to false,
                    "message" to sourceDecision.reason
                )
            }

            val resolvedSource = NovaAppSandboxGuard.resolveAppPrivateFileOrNull(context, normalizedSource)
                ?: return mapOf(
                    "success" to false,
                    "message" to "Kaynak ses referansı uygulama alanı dışında olamaz."
                )
            val safeSourceReference = NovaAppSandboxGuard.toAppRelativeReference(context, resolvedSource)

            val maybeModelBridgeResult = tryModelBridge(
                sourcePath = safeSourceReference,
                suggestedName = normalizedName,
                styleInstruction = normalizedStyle
            )

            if (maybeModelBridgeResult != null) {
                maybeModelBridgeResult
            } else {
                createReferenceFallback(
                    sourcePath = safeSourceReference,
                    suggestedName = normalizedName,
                    styleInstruction = normalizedStyle
                )
            }
        } catch (_: Throwable) {
            mapOf(
                "success" to false,
                "message" to "Klon motoru çalıştırılamadı."
            )
        }
    }

    private fun tryModelBridge(
        sourcePath: String,
        suggestedName: String,
        styleInstruction: String
    ): Map<String, Any?>? {
        return try {
            val clazz = Class.forName("com.example.nova.ModelBridge")
            val method =
                clazz.methods.firstOrNull { it.name == "createVoiceClone" } ?: return null

            val result = method.invoke(
                null,
                context,
                sourcePath,
                suggestedName,
                styleInstruction
            )

            @Suppress("UNCHECKED_CAST")
            result as? Map<String, Any?>
        } catch (_: Throwable) {
            null
        }
    }

    private fun createReferenceFallback(
        sourcePath: String,
        suggestedName: String,
        styleInstruction: String
    ): Map<String, Any?> {
        val fallbackDecision = NovaSystemBoundaryGuard.canAccessFile(
            context = context,
            rawReference = sourcePath,
            operation = "read",
            source = "system_safe",
            ownerApproved = false
        )
        if (!fallbackDecision.allowed) {
            return mapOf(
                "success" to false,
                "message" to fallbackDecision.reason
            )
        }

        val source = NovaAppSandboxGuard.resolveAppPrivateFileOrNull(context, sourcePath)
            ?: return mapOf(
                "success" to false,
                "message" to "Kaynak ses dosyası uygulama alanı dışında olamaz."
            )
        if (!source.exists() || !source.isFile) {
            return mapOf(
                "success" to false,
                "message" to "Kaynak ses dosyası bulunamadı."
            )
        }

        val dir = File(context.filesDir, "nova_cloned_voice_refs")
        if (!dir.exists()) {
            dir.mkdirs()
        }

        val safeName = NovaAppSandboxGuard.sanitizeOutputName(suggestedName, "Klon_Ses")

        val voiceId = "${safeName}_${System.currentTimeMillis()}"
        val extension = source.extension.trim().ifBlank {
            if (source.name.lowercase().endsWith(".wav")) "wav" else "m4a"
        }

        val copiedAudio = File(dir, "$voiceId.$extension")
        val writeDecision = NovaSystemBoundaryGuard.canAccessFile(
            context = context,
            rawReference = NovaAppSandboxGuard.toAppRelativeReference(context, copiedAudio),
            operation = "write",
            source = "system_safe",
            ownerApproved = false
        )
        if (!writeDecision.allowed) {
            return mapOf(
                "success" to false,
                "message" to writeDecision.reason
            )
        }
        source.copyTo(copiedAudio, overwrite = true)

        val meta = File(dir, "$voiceId.json")
        meta.writeText(
            JSONObject(
                mapOf(
                    "voiceId" to voiceId,
                    "voiceName" to suggestedName,
                    "styleInstruction" to styleInstruction,
                    "referenceAudio" to NovaAppSandboxGuard.toAppRelativeReference(context, copiedAudio),
                    "sourceReference" to NovaAppSandboxGuard.toAppRelativeReference(context, copiedAudio)
                )
            ).toString()
        )

        return mapOf(
            "success" to true,
            "voiceId" to voiceId,
            "voiceName" to suggestedName,
            "styleInstruction" to styleInstruction,
            "referenceAudio" to NovaAppSandboxGuard.toAppRelativeReference(context, copiedAudio),
            "sourceReference" to NovaAppSandboxGuard.toAppRelativeReference(context, copiedAudio),
            "message" to "Referans ses profili oluşturuldu."
        )
    }
}