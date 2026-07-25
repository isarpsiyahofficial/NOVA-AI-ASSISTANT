package com.example.nova

import android.content.Context

/**
 * Minimal carrier boundary.
 *
 * The former repeated-denial counters, long-lived kill switch and source-name
 * quarantine were removed. This layer now does only the checks that cannot be
 * delegated to the AI: number normalization, USSD/MMI rejection and a short,
 * number-bound proof that the owner or the native dialer approved the call.
 */
object NovaCarrierBoundaryGuard {
    private const val MANUAL_OUTBOUND_WINDOW_MS = 20_000L
    private const val OWNER_APPROVAL_WINDOW_MS = 90_000L

    @Volatile private var lastManualOutboundAt: Long = 0L
    @Volatile private var lastManualOutboundNumber: String = ""
    @Volatile private var ownerApprovalTokenNumber: String = ""
    @Volatile private var ownerApprovalTokenExpiresAt: Long = 0L

    data class Decision(
        val allowed: Boolean,
        val reason: String,
        val mode: String = "blocked",
        val normalizedNumber: String = "",
        val highRisk: Boolean = false,
        val userInitiated: Boolean = false,
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "allowed" to allowed,
            "reason" to reason,
            "mode" to mode,
            "normalizedNumber" to normalizedNumber,
            "highRisk" to highRisk,
            "userInitiated" to userInitiated,
        )
    }

    fun registerManualOutbound(number: String) {
        val normalized = normalizeDialableNumber(number)
        if (normalized.isEmpty() || rejectCarrierCode(normalized) != null) return
        lastManualOutboundAt = System.currentTimeMillis()
        lastManualOutboundNumber = normalized
    }

    fun registerOwnerApprovedOutbound(number: String): Decision {
        val normalized = normalizeDialableNumber(number)
        if (normalized.isEmpty()) {
            return Decision(
                allowed = false,
                reason = "Owner arama onayı üretilemedi: numara boş veya geçersiz.",
                mode = "owner_approval_rejected",
            )
        }
        rejectCarrierCode(normalized)?.let { return it }
        ownerApprovalTokenNumber = normalized
        ownerApprovalTokenExpiresAt =
            System.currentTimeMillis() + OWNER_APPROVAL_WINDOW_MS
        return Decision(
            allowed = true,
            reason = "Numaraya bağlı tek kullanımlık owner arama onayı üretildi.",
            mode = "owner_approval_token_created",
            normalizedNumber = normalized,
            userInitiated = true,
        )
    }

    @Suppress("UNUSED_PARAMETER")
    fun canPlaceCall(
        context: Context,
        rawNumber: String?,
        source: String = "",
        userInitiated: Boolean = false,
    ): Decision {
        val normalized = normalizeDialableNumber(rawNumber.orEmpty())
        if (normalized.isEmpty()) {
            return Decision(
                allowed = false,
                reason = "Arama başlatılamadı: numara boş veya geçersiz.",
                mode = "empty_number",
            )
        }
        rejectCarrierCode(normalized)?.let { return it }
        if (consumeManualOutbound(normalized)) {
            return Decision(
                allowed = true,
                reason = "Native dialer kullanıcısının numaraya bağlı işlemi doğrulandı.",
                mode = "native_manual_outbound",
                normalizedNumber = normalized,
                userInitiated = true,
            )
        }
        if (consumeOwnerApprovalToken(normalized)) {
            return Decision(
                allowed = true,
                reason = "Owner tarafından onaylanan numaraya dış arama başlatıldı.",
                mode = "owner_token_outbound",
                normalizedNumber = normalized,
                userInitiated = true,
            )
        }
        return Decision(
            allowed = false,
            reason = "Arama başlatılamadı: bu numara için taze kullanıcı veya owner onayı yok.",
            mode = "missing_number_bound_approval",
            normalizedNumber = normalized,
            highRisk = true,
        )
    }

    @Suppress("UNUSED_PARAMETER")
    fun canSendDtmf(
        context: Context,
        digit: Char,
        source: String = "",
        userInitiated: Boolean = false,
    ): Decision {
        val allowed = digit in "0123456789*#"
        return if (allowed) {
            Decision(
                allowed = true,
                reason = "Geçerli DTMF karakteri.",
                mode = "carrier_dtmf_checked",
                normalizedNumber = digit.toString(),
                userInitiated = userInitiated,
            )
        } else {
            Decision(
                allowed = false,
                reason = "DTMF gönderilemedi: geçersiz karakter.",
                mode = "invalid_dtmf",
                normalizedNumber = digit.toString(),
            )
        }
    }

    fun clearOutboundKillSwitch(context: Context) {
        // Compatibility no-op. The automatic kill switch no longer exists.
    }

    fun normalizeDialableNumber(raw: String): String {
        val decoded = raw.trim()
            .removePrefix("tel:")
            .removePrefix("TEL:")
            .replace("%2A", "*", ignoreCase = true)
            .replace("%23", "#", ignoreCase = true)
        if (decoded.isEmpty()) return ""
        val filtered = buildString {
            decoded.forEachIndexed { index, ch ->
                when {
                    ch.isDigit() -> append(ch)
                    ch == '+' && index == 0 -> append(ch)
                    ch == '*' || ch == '#' || ch == ',' || ch == ';' -> append(ch)
                }
            }
        }
        val digits = filtered.count(Char::isDigit)
        if (digits !in 7..15 && !containsCarrierControl(filtered)) return ""
        return filtered
    }

    private fun rejectCarrierCode(normalized: String): Decision? {
        if (!containsCarrierControl(normalized)) return null
        return Decision(
            allowed = false,
            reason = "USSD/MMI/operatör servis kodu telefon eylemi olarak çalıştırılamaz.",
            mode = "carrier_code_blocked",
            normalizedNumber = normalized,
            highRisk = true,
        )
    }

    private fun containsCarrierControl(value: String): Boolean {
        return value.any { it == '*' || it == '#' || it == ',' || it == ';' }
    }

    private fun consumeManualOutbound(normalized: String): Boolean {
        val fresh = System.currentTimeMillis() - lastManualOutboundAt <=
            MANUAL_OUTBOUND_WINDOW_MS
        val matches = fresh && lastManualOutboundNumber == normalized
        if (matches || !fresh) {
            lastManualOutboundAt = 0L
            lastManualOutboundNumber = ""
        }
        return matches
    }

    private fun consumeOwnerApprovalToken(normalized: String): Boolean {
        val fresh = ownerApprovalTokenExpiresAt > System.currentTimeMillis()
        val matches = fresh && ownerApprovalTokenNumber == normalized
        if (matches || !fresh) {
            ownerApprovalTokenNumber = ""
            ownerApprovalTokenExpiresAt = 0L
        }
        return matches
    }
}
