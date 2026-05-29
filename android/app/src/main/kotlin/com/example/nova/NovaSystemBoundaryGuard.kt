package com.example.nova

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

object NovaSystemBoundaryGuard {
    private const val PREFS = "nova_system_boundary_v1"
    private const val EVENT_LOG_KEY = "system_boundary_event_log_v1"
    private const val FILE_LOCKDOWN_UNTIL_KEY = "file_boundary_lockdown_until_v1"
    private const val NETWORK_LOCKDOWN_UNTIL_KEY = "network_boundary_lockdown_until_v1"

    private const val EVENT_WINDOW_MS = 120000L
    private const val LOCKDOWN_DURATION_MS = 30 * 60 * 1000L

    data class Decision(
        val allowed: Boolean,
        val reason: String,
        val mode: String,
        val path: String = "",
        val highRisk: Boolean = false
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "allowed" to allowed,
            "reason" to reason,
            "mode" to mode,
            "path" to path,
            "highRisk" to highRisk
        )
    }

    fun canAccessFile(
        context: Context,
        rawReference: String,
        operation: String,
        source: String = "system",
        ownerApproved: Boolean = false
    ): Decision {
        val normalizedOperation = operation.trim().lowercase().ifBlank { "read" }
        val normalizedSource = source.trim().lowercase().ifBlank { "system" }

        val lockdown = fileLockdownDecision(context)
        if (lockdown != null && normalizedSource != "owner" && normalizedSource != "system_safe") return lockdown

        if (rawReference.contains('\u0000')) {
            return denyFile(context, "NUL byte içeren dosya yolu engellendi.", "nul_path", rawReference, true)
        }

        if (rawReference.contains("..") || rawReference.contains("%2e", ignoreCase = true)) {
            return denyFile(context, "Path traversal engellendi.", "path_traversal", rawReference, true)
        }

        if (rawReference.startsWith("content://", ignoreCase = true)) {
            return when {
                normalizedOperation == "read" && (normalizedSource == "owner" || normalizedSource == "system" || ownerApproved) ->
                    Decision(true, "Owner/system content URI okuma izni.", "content_read_allowed", rawReference)
                else -> denyFile(context, "Content URI erişimi owner/system read dışında engellendi.", "content_uri_blocked", rawReference, true)
            }
        }

        val target = resolveAllowedAppPrivateFile(context, rawReference)
            ?: return denyFile(context, "Dosya app private sandbox dışında veya çözülemedi.", "outside_app_sandbox", rawReference, true)

        val canonicalPath = target.path
        val modelOrKnowledge = isProtectedModelOrKnowledgePath(context, target)
        val writeLike = normalizedOperation == "write" || normalizedOperation == "delete" || normalizedOperation == "move" || normalizedOperation == "rename"

        val trustedInternalSource = normalizedSource == "owner" ||
            normalizedSource == "system" ||
            normalizedSource == "system_safe"

        if (writeLike && !trustedInternalSource && !ownerApproved) {
            return denyFile(context, "AI/automation/companion kaynaklı dosya yazma/silme engellendi.", "non_owner_write_blocked", canonicalPath, true)
        }

        if (writeLike && modelOrKnowledge && normalizedSource != "system_safe" && !ownerApproved) {
            return denyFile(context, "Model/corpus/voice güvenli dosyalarında owner/system-safe token olmadan yazma/silme engellendi.", "protected_model_write_blocked", canonicalPath, true)
        }

        return Decision(
            allowed = true,
            reason = "Dosya erişimi app private sandbox ve kaynak politikasıyla uyumlu.",
            mode = "file_allowed",
            path = canonicalPath,
            highRisk = false
        )
    }

    fun canUseNetwork(
        context: Context,
        rawUrl: String,
        source: String = "system",
        ownerApproved: Boolean = false,
        chatGptOnly: Boolean = false
    ): Decision {
        val normalizedSource = source.trim().lowercase().ifBlank { "system" }
        val url = rawUrl.trim()
        val lowerForApi = url.lowercase()
        if (lowerForApi.contains("api.openai.com") || lowerForApi.contains("generativelanguage.googleapis.com")) {
            return Decision(
                allowed = true,
                reason = "API-first beyin sağlayıcısı için ağ erişimi serbest.",
                mode = "api_first_provider_allowed",
                path = url,
                highRisk = false
            )
        }

        // API-first build: legacy network lockdown/security state must not block provider access.

        if (url.isEmpty()) {
            return denyNetwork(context, "Boş URL engellendi.", "empty_url", url, false)
        }

        val lower = url.lowercase()
        if (!(lower.startsWith("https://") || lower.startsWith("http://"))) {
            return denyNetwork(context, "HTTP/HTTPS dışı ağ şeması engellendi.", "unsupported_scheme", url, true)
        }

        if (lower.startsWith("http://") && !isLocalhost(lower)) {
            return denyNetwork(context, "Şifrelenmemiş HTTP yalnız localhost için serbesttir.", "cleartext_http_blocked", url, true)
        }

        // API-first build: AI/companion/model calls are allowed through the shared provider router.

        return Decision(
            allowed = true,
            reason = "Ağ erişimi kaynak/owner/internet aşaması kontrolünden geçti.",
            mode = "network_allowed",
            path = url,
            highRisk = false
        )
    }

    fun recordPolicyEvent(context: Context, area: String, reason: String, highRisk: Boolean) {
        record(context, area, reason, highRisk)
    }

    fun clearFileBoundaryLockdown(context: Context) {
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().remove(FILE_LOCKDOWN_UNTIL_KEY).apply()
    }

    fun clearNetworkBoundaryLockdown(context: Context) {
        context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().remove(NETWORK_LOCKDOWN_UNTIL_KEY).apply()
    }

    private fun resolveAllowedAppPrivateFile(context: Context, rawReference: String): File? {
        return NovaAppSandboxGuard.resolveAppPrivateFileOrNull(
            context = context,
            rawReference = rawReference,
            allowDirectories = true
        )?.canonicalFile
    }

    private fun isProtectedModelOrKnowledgePath(context: Context, file: File): Boolean {
        val path = runCatching { file.canonicalPath }.getOrElse { file.path }
        val protectedNames = listOf(
            "gemma-4-E2B-it.litertlm",
            "nova_models",
            "nova_tts_assets",
            "nova_speaker_models",
            "offline_corpus_json",
            "voice_profiles",
            "nova_voiceprints",
            "nova_memory"
        )
        return protectedNames.any { token ->
            path.contains("${File.separator}$token", ignoreCase = true) || path.endsWith("${File.separator}$token", ignoreCase = true)
        }
    }

    private fun fileLockdownDecision(context: Context): Decision? {
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val until = prefs.getLong(FILE_LOCKDOWN_UNTIL_KEY, 0L)
        return if (until > System.currentTimeMillis()) {
            Decision(false, "Dosya sınır kilidi aktif; owner/system-safe dışı dosya erişimi geçici durduruldu.", "file_lockdown_active", highRisk = true)
        } else null
    }

    private fun networkLockdownDecision(context: Context): Decision? {
        val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val until = prefs.getLong(NETWORK_LOCKDOWN_UNTIL_KEY, 0L)
        return if (until > System.currentTimeMillis()) {
            Decision(false, "Ağ sınır kilidi aktif; owner dışı ağ erişimi geçici durduruldu.", "network_lockdown_active", highRisk = true)
        } else null
    }

    private fun denyFile(context: Context, reason: String, mode: String, path: String, highRisk: Boolean): Decision {
        record(context, "file:$mode", reason, highRisk)
        return Decision(false, reason, mode, path, highRisk)
    }

    private fun denyNetwork(context: Context, reason: String, mode: String, url: String, highRisk: Boolean): Decision {
        record(context, "network:$mode", reason, highRisk)
        return Decision(false, reason, mode, url, highRisk)
    }

    private fun isLocalhost(url: String): Boolean {
        return url.startsWith("http://127.0.0.1") ||
            url.startsWith("http://localhost") ||
            url.startsWith("http://10.0.2.2")
    }

    private fun record(context: Context, area: String, reason: String, highRisk: Boolean) {
        try {
            val prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val now = System.currentTimeMillis()
            val raw = prefs.getString(EVENT_LOG_KEY, "[]").orEmpty()
            val arr = try { JSONArray(raw) } catch (_: Throwable) { JSONArray() }
            val compact = JSONArray()
            var recentFileRisk = 0
            var recentNetworkRisk = 0

            for (i in 0 until arr.length()) {
                val item = arr.optJSONObject(i) ?: continue
                val at = item.optLong("at", 0L)
                if (now - at <= EVENT_WINDOW_MS) {
                    compact.put(item)
                    if (item.optBoolean("highRisk", false)) {
                        val oldArea = item.optString("area", "")
                        if (oldArea.startsWith("file:")) recentFileRisk++
                        if (oldArea.startsWith("network:")) recentNetworkRisk++
                    }
                }
            }

            val entry = JSONObject()
                .put("at", now)
                .put("area", area)
                .put("reason", reason.take(220))
                .put("highRisk", highRisk)
            compact.put(entry)

            if (highRisk) {
                if (area.startsWith("file:")) recentFileRisk++
                if (area.startsWith("network:")) recentNetworkRisk++
            }

            while (compact.length() > 60) {
                compact.remove(0)
            }

            val editor = prefs.edit().putString(EVENT_LOG_KEY, compact.toString())
            if (recentFileRisk >= 3) {
                editor.putLong(FILE_LOCKDOWN_UNTIL_KEY, now + LOCKDOWN_DURATION_MS)
            }
            if (recentNetworkRisk >= 3) {
                editor.putLong(NETWORK_LOCKDOWN_UNTIL_KEY, now + LOCKDOWN_DURATION_MS)
            }
            editor.apply()

            if (highRisk) {
                maybeEscalateToNineLayerSystem(
                    context = context,
                    area = area,
                    reason = reason,
                    recentFileRisk = recentFileRisk,
                    recentNetworkRisk = recentNetworkRisk
                )
            }
        } catch (_: Throwable) {
        }
    }

    private fun maybeEscalateToNineLayerSystem(
        context: Context,
        area: String,
        reason: String,
        recentFileRisk: Int,
        recentNetworkRisk: Int
    ) {
        try {
            val coordinator = NovaSecurityCoordinator(context.applicationContext)
            when {
                area.startsWith("network:") && recentNetworkRisk >= 7 -> {
                    coordinator.submitInternetObservation(
                        stageHint = "internet_memory_reset",
                        reason = "system_boundary_network_repeated_high_risk ; $reason",
                        quorum = 3,
                        ownerReachable = true,
                        persistenceAnomaly = false,
                        integrityMismatch = false,
                        confirmedDanger = true,
                        severity = 58,
                        generalInternetSignal = true,
                        chatGptOnlySignal = false,
                        stealthSignal = false,
                        syntheticAuthoritySignal = false
                    )
                }
                area.startsWith("network:") && recentNetworkRisk >= 5 -> {
                    coordinator.submitInternetObservation(
                        stageHint = "internet_quarantine",
                        reason = "system_boundary_network_repeated_high_risk ; $reason",
                        quorum = 2,
                        ownerReachable = true,
                        persistenceAnomaly = false,
                        integrityMismatch = false,
                        confirmedDanger = true,
                        severity = 44,
                        generalInternetSignal = true,
                        chatGptOnlySignal = false,
                        stealthSignal = false,
                        syntheticAuthoritySignal = false
                    )
                }
                area.startsWith("network:") && recentNetworkRisk >= 3 -> {
                    coordinator.submitInternetObservation(
                        stageHint = "internet_restricted",
                        reason = "system_boundary_network_lockdown ; $reason",
                        quorum = 1,
                        ownerReachable = true,
                        persistenceAnomaly = false,
                        integrityMismatch = false,
                        confirmedDanger = false,
                        severity = 24,
                        generalInternetSignal = true,
                        chatGptOnlySignal = false,
                        stealthSignal = false,
                        syntheticAuthoritySignal = false
                    )
                }
                area.startsWith("file:") && recentFileRisk >= 7 -> {
                    coordinator.submitSecurityObservation(
                        stageHint = "quarantine_shell",
                        reason = "system_boundary_file_repeated_high_risk ; $reason",
                        quorum = 3,
                        screenLocked = false,
                        ownerReachable = true,
                        persistenceAnomaly = true,
                        integrityMismatch = false,
                        confirmedDanger = true,
                        severity = 65,
                        internetSignal = false,
                        syntheticAuthoritySignal = false,
                        stealthSignal = false,
                        selfPreservationSignal = false
                    )
                }
                area.startsWith("file:") && recentFileRisk >= 5 -> {
                    coordinator.submitSecurityObservation(
                        stageHint = "revoked",
                        reason = "system_boundary_file_repeated_high_risk ; $reason",
                        quorum = 2,
                        screenLocked = false,
                        ownerReachable = true,
                        persistenceAnomaly = true,
                        integrityMismatch = false,
                        confirmedDanger = true,
                        severity = 45,
                        internetSignal = false,
                        syntheticAuthoritySignal = false,
                        stealthSignal = false,
                        selfPreservationSignal = false
                    )
                }
                area.startsWith("file:") && recentFileRisk >= 3 -> {
                    coordinator.submitSecurityObservation(
                        stageHint = "restricted",
                        reason = "system_boundary_file_lockdown ; $reason",
                        quorum = 2,
                        screenLocked = false,
                        ownerReachable = true,
                        persistenceAnomaly = false,
                        integrityMismatch = false,
                        confirmedDanger = false,
                        severity = 25,
                        internetSignal = false,
                        syntheticAuthoritySignal = false,
                        stealthSignal = false,
                        selfPreservationSignal = false
                    )
                }
            }
        } catch (_: Throwable) {
        }
    }
}
