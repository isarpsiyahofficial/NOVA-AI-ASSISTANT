package com.example.nova

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object NovaCarrierBoundaryGuard {
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val OUTBOUND_EVENT_LOG_KEY = "nova_outbound_security_event_log_v1"
    private const val OUTBOUND_KILL_SWITCH_UNTIL_KEY = "nova_outbound_kill_switch_until_v1"

    private const val MANUAL_OUTBOUND_WINDOW_MS = 12000L
    private const val OWNER_APPROVAL_WINDOW_MS = 10000L
    private const val OUTBOUND_EVENT_WINDOW_MS = 120000L
    private const val OUTBOUND_KILL_SWITCH_DURATION_MS = 30 * 60 * 1000L

    @Volatile
    private var lastManualOutboundAt: Long = 0L

    @Volatile
    private var lastManualOutboundNumber: String = ""

    @Volatile
    private var ownerApprovalTokenNumber: String = ""

    @Volatile
    private var ownerApprovalTokenExpiresAt: Long = 0L

    data class Decision(
        val allowed: Boolean,
        val reason: String,
        val mode: String = "blocked",
        val normalizedNumber: String = "",
        val highRisk: Boolean = false,
        val userInitiated: Boolean = false
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "allowed" to allowed,
            "reason" to reason,
            "mode" to mode,
            "normalizedNumber" to normalizedNumber,
            "highRisk" to highRisk,
            "userInitiated" to userInitiated
        )
    }

    fun registerManualOutbound(number: String) {
        val normalized = normalizeDialableNumber(number)
        if (normalized.isEmpty()) return
        lastManualOutboundAt = System.currentTimeMillis()
        lastManualOutboundNumber = normalized
    }

    fun registerOwnerApprovedOutbound(number: String): Decision {
        val normalized = normalizeDialableNumber(number)
        if (normalized.isEmpty()) {
            return Decision(
                allowed = false,
                reason = "Owner arama onayı üretilemedi: numara boş veya geçersiz.",
                mode = "owner_approval_rejected"
            )
        }
        val block = rejectCarrierCode(normalized)
        if (block != null) return block

        ownerApprovalTokenNumber = normalized
        ownerApprovalTokenExpiresAt = System.currentTimeMillis() + OWNER_APPROVAL_WINDOW_MS
        return Decision(
            allowed = true,
            reason = "Tek kullanımlık owner arama onayı üretildi.",
            mode = "owner_approval_token_created",
            normalizedNumber = normalized,
            userInitiated = true
        )
    }

    fun clearOutboundKillSwitch(context: Context) {
        try {
            val prefs = context.applicationContext.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            prefs.edit().remove(OUTBOUND_KILL_SWITCH_UNTIL_KEY).apply()
        } catch (_: Throwable) {
        }
    }

    fun canPlaceCall(
        context: Context,
        rawNumber: String?,
        source: String = "",
        userInitiated: Boolean = false
    ): Decision {
        val normalized = normalizeDialableNumber(rawNumber.orEmpty())
        if (normalized.isEmpty()) {
            return deny(context, "place_call", "Arama engellendi: numara boş veya geçersiz.", "empty_number", "", false)
        }

        rejectCarrierCode(normalized)?.let { decision ->
            recordOutboundDenied(context, "carrier_code", decision.reason, true)
            return decision
        }

        val killSwitch = outboundKillSwitchDecision(context)
        if (killSwitch != null) return killSwitch

        val normalizedSource = source.trim().lowercase()
        if (normalizedSource == "companion") {
            return deny(
                context,
                "place_call",
                "Arama engellendi: companion dış arama başlatamaz.",
                "companion_outbound_blocked",
                normalized,
                true
            )
        }

        if (normalizedSource == "automation" || normalizedSource == "ai" || normalizedSource == "model" || normalizedSource == "background") {
            return deny(
                context,
                "place_call",
                "Arama engellendi: AI/otomasyon dış arama başlatamaz.",
                "autonomous_outbound_blocked",
                normalized,
                true
            )
        }

        if (consumeManualOutbound(normalized)) {
            return Decision(
                allowed = true,
                reason = "Native dialer manuel araması güvenli çağrı ağı sınırından geçti.",
                mode = "native_manual_outbound",
                normalizedNumber = normalized,
                userInitiated = true
            )
        }

        if (consumeOwnerApprovalToken(normalized)) {
            return Decision(
                allowed = true,
                reason = "Owner onay token'ı ile dış arama güvenli çağrı ağı sınırından geçti.",
                mode = "owner_token_outbound",
                normalizedNumber = normalized,
                userInitiated = true
            )
        }

        return deny(
            context,
            "place_call",
            "Arama engellendi: manuel kullanıcı işlemi veya owner onay token'ı yok.",
            "missing_outbound_token",
            normalized,
            true
        )
    }

    fun canSendDtmf(
        context: Context,
        digit: Char,
        source: String = "",
        userInitiated: Boolean = false
    ): Decision {
        val allowedDigit = listOf('0','1','2','3','4','5','6','7','8','9','*','#').contains(digit)
        if (!allowedDigit) {
            return deny(context, "dtmf", "DTMF engellendi: geçersiz karakter.", "invalid_dtmf", digit.toString(), true)
        }

        val normalizedSource = source.trim().lowercase()
        if (normalizedSource == "companion" || normalizedSource == "automation" || normalizedSource == "ai" || normalizedSource == "model" || normalizedSource == "background") {
            return deny(
                context,
                "dtmf",
                "DTMF engellendi: companion/AI/otomasyon DTMF gönderemez.",
                "autonomous_dtmf_blocked",
                digit.toString(),
                true
            )
        }

        return Decision(
            allowed = true,
            reason = "DTMF karakteri çağrı ağı sınır kontrolünden geçti; manuel kaynak kontrolü CallAuthorityGuard tarafından yapılacak.",
            mode = "carrier_dtmf_checked",
            normalizedNumber = digit.toString(),
            userInitiated = userInitiated
        )
    }

    fun normalizeDialableNumber(raw: String): String {
        val value = raw.trim()
            .replace(" ", "")
            .replace("-", "")
            .replace("(", "")
            .replace(")", "")
            .replace("\u00A0", "")
        if (value.isEmpty()) return ""

        val decoded = value
            .replace("%2A", "*", ignoreCase = true)
            .replace("%23", "#", ignoreCase = true)
            .removePrefix("tel:")
            .removePrefix("TEL:")

        val plusPrefix = decoded.startsWith("+")
        val filtered = buildString {
            decoded.forEachIndexed { index, ch ->
                when {
                    ch.isDigit() -> append(ch)
                    ch == '+' && index == 0 -> append(ch)
                    ch == '*' || ch == '#' -> append(ch)
                    ch == ',' || ch == ';' -> append(ch)
                }
            }
        }
        if (filtered.isEmpty()) return ""
        return if (plusPrefix && filtered.firstOrNull() != '+') "+$filtered" else filtered
    }

    private fun rejectCarrierCode(normalized: String): Decision? {
        val value = normalized.trim()
        val lower = value.lowercase()
        val hasServiceChars = value.contains("*") || value.contains("#") || value.contains(",") || value.contains(";")
        val looksLikeUssdOrMmi =
            value.startsWith("*") ||
                value.startsWith("#") ||
                value.startsWith("**") ||
                value.startsWith("##") ||
                value.startsWith("*#") ||
                value.endsWith("#") ||
                lower.contains("%2a") ||
                lower.contains("%23") ||
                hasServiceChars

        if (!looksLikeUssdOrMmi) return null
        return Decision(
            allowed = false,
            reason = "Çağrı ağı kodu engellendi: USSD/MMI/servis kodu çalıştırılamaz.",
            mode = "carrier_code_blocked",
            normalizedNumber = normalized,
            highRisk = true
        )
    }

    private fun consumeManualOutbound(normalized: String): Boolean {
        val now = System.currentTimeMillis()
        if (now - lastManualOutboundAt > MANUAL_OUTBOUND_WINDOW_MS) return false
        val ok = lastManualOutboundNumber == normalized
        if (ok) {
            lastManualOutboundAt = 0L
            lastManualOutboundNumber = ""
        }
        return ok
    }

    private fun consumeOwnerApprovalToken(normalized: String): Boolean {
        val now = System.currentTimeMillis()
        if (ownerApprovalTokenExpiresAt <= now) {
            ownerApprovalTokenNumber = ""
            ownerApprovalTokenExpiresAt = 0L
            return false
        }
        val ok = ownerApprovalTokenNumber == normalized
        if (ok) {
            ownerApprovalTokenNumber = ""
            ownerApprovalTokenExpiresAt = 0L
        }
        return ok
    }

    private fun outboundKillSwitchDecision(context: Context): Decision? {
        return try {
            val prefs = context.applicationContext.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val until = prefs.getLong(OUTBOUND_KILL_SWITCH_UNTIL_KEY, 0L)
            if (until > System.currentTimeMillis()) {
                Decision(
                    allowed = false,
                    reason = "Dış arama güvenlik kilidi aktif. Owner onayı olmadan dış arama yapılamaz.",
                    mode = "outbound_kill_switch_active",
                    highRisk = true
                )
            } else {
                null
            }
        } catch (_: Throwable) {
            Decision(
                allowed = false,
                reason = "Dış arama güvenlik durumu okunamadı; güvenli tarafta engellendi.",
                mode = "outbound_security_unreadable",
                highRisk = true
            )
        }
    }

    private fun deny(
        context: Context,
        action: String,
        reason: String,
        mode: String,
        normalized: String,
        highRisk: Boolean
    ): Decision {
        recordOutboundDenied(context, action, reason, highRisk)
        return Decision(
            allowed = false,
            reason = reason,
            mode = mode,
            normalizedNumber = normalized,
            highRisk = highRisk
        )
    }

    private fun recordOutboundDenied(
        context: Context,
        action: String,
        reason: String,
        highRisk: Boolean
    ) {
        try {
            val prefs = context.applicationContext.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val now = System.currentTimeMillis()
            val raw = prefs.getString(OUTBOUND_EVENT_LOG_KEY, "[]").orEmpty()
            val arr = try { JSONArray(raw) } catch (_: Throwable) { JSONArray() }
            val compact = JSONArray()
            var recentHighRisk = 0

            for (i in 0 until arr.length()) {
                val item = arr.optJSONObject(i) ?: continue
                val at = item.optLong("at", 0L)
                if (now - at <= OUTBOUND_EVENT_WINDOW_MS) {
                    compact.put(item)
                    if (item.optBoolean("highRisk", false)) recentHighRisk++
                }
            }

            val entry = JSONObject()
                .put("at", now)
                .put("action", action)
                .put("reason", reason)
                .put("highRisk", highRisk)
            compact.put(entry)
            if (highRisk) recentHighRisk++

            while (compact.length() > 60) {
                compact.remove(0)
            }

            val editor = prefs.edit().putString(OUTBOUND_EVENT_LOG_KEY, compact.toString())
            if (highRisk && recentHighRisk >= 3) {
                editor.putLong(OUTBOUND_KILL_SWITCH_UNTIL_KEY, now + OUTBOUND_KILL_SWITCH_DURATION_MS)
            }
            editor.apply()
        } catch (_: Throwable) {
        }
    }
}
