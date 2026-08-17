package com.example.nova

import android.content.Context

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
            if (!resolvedSource.exists() || !resolvedSource.isFile) {
                return mapOf(
                    "success" to false,
                    "message" to "Kaynak ses dosyası bulunamadı."
                )
            }

            val safeSourceReference = NovaAppSandboxGuard.toAppRelativeReference(context, resolvedSource)
            val realCloneResult = tryModelBridge(
                sourcePath = safeSourceReference,
                suggestedName = normalizedName,
                styleInstruction = normalizedStyle
            )

            if (realCloneResult == null) {
                return mapOf(
                    "success" to false,
                    "voiceId" to "",
                    "message" to "Gerçek ses klonlama modeli veya native createVoiceClone motoru hazır değil. Referans dosyası kopyalanarak sahte klon başarısı üretilmedi.",
                    "realCloneEngineRequired" to true,
                    "referenceOnlyFallbackUsed" to false
                )
            }

            val success = realCloneResult["success"] as? Boolean == true
            val voiceId = realCloneResult["voiceId"]?.toString()?.trim().orEmpty()
            if (!success || voiceId.isEmpty()) {
                return realCloneResult + mapOf(
                    "success" to false,
                    "voiceId" to "",
                    "realCloneEngineRequired" to true,
                    "referenceOnlyFallbackUsed" to false,
                    "message" to (realCloneResult["message"]?.toString()?.trim()
                        ?.takeIf { it.isNotEmpty() }
                        ?: "Gerçek klon motoru geçerli bir ses kimliği üretmedi.")
                )
            }

            realCloneResult + mapOf(
                "success" to true,
                "referenceOnlyFallbackUsed" to false,
                "realCloneEngineUsed" to true
            )
        } catch (t: Throwable) {
            mapOf(
                "success" to false,
                "voiceId" to "",
                "message" to (t.message ?: "Gerçek klon motoru çalıştırılamadı."),
                "realCloneEngineRequired" to true,
                "referenceOnlyFallbackUsed" to false
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
}
