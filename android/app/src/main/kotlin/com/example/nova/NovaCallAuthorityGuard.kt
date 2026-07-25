package com.example.nova

import android.content.Context
import android.util.Log
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

/**
 * Minimal call authority compatibility layer.
 *
 * Historical denial counters, quarantine/lockdown state and automatic kill
 * switches were removed. This object only correlates an actual UI gesture with
 * a short action window and applies product rules that remain essential:
 * companion/automatic call control is limited to explicitly managed contacts,
 * and unattended answering is limited to the configured night window.
 */
object NovaCallAuthorityGuard {
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val STATUS_KEY = "flutter.nova_status_state_v1"
    private const val POWER_MODE_KEY = "flutter.nova_power_mode_v1"
    private const val SCHEDULED_NIGHT_HOLD_KEY =
        "flutter.nova_power_manual_night_hold_until_v1"
    private const val ACTION_WINDOW_MS = 8_000L

    @Volatile private var lastUserCallActionAt: Long = 0L
    @Volatile private var lastUserCallAction: String = ""
    @Volatile private var lastTrustedSourceActionAt: Long = 0L
    @Volatile private var lastTrustedSourceAction: String = ""
    @Volatile private var lastTrustedSource: String = ""

    data class Decision(
        val allowed: Boolean,
        val reason: String,
        val mode: String = "blocked",
        val authorizedNumber: Boolean = false,
        val nightActive: Boolean = false,
        val userInitiated: Boolean = false,
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "allowed" to allowed,
            "reason" to reason,
            "mode" to mode,
            "authorizedNumber" to authorizedNumber,
            "nightActive" to nightActive,
            "userInitiated" to userInitiated,
        )
    }

    fun registerUserCallAction(action: String) {
        lastUserCallActionAt = System.currentTimeMillis()
        lastUserCallAction = action.trim().lowercase()
    }

    fun isRecentUserCallAction(vararg acceptedActions: String): Boolean {
        if (System.currentTimeMillis() - lastUserCallActionAt > ACTION_WINDOW_MS) {
            return false
        }
        if (acceptedActions.isEmpty()) return true
        return acceptedActions.any {
            it.trim().lowercase() == lastUserCallAction
        }
    }

    fun consumeUserCallAction(vararg acceptedActions: String): Boolean {
        val allowed = isRecentUserCallAction(*acceptedActions)
        if (allowed) {
            lastUserCallActionAt = 0L
            lastUserCallAction = ""
        }
        return allowed
    }

    fun registerTrustedCallAction(action: String, source: String) {
        if (source.trim().lowercase() != "companion") return
        lastTrustedSourceActionAt = System.currentTimeMillis()
        lastTrustedSourceAction = action.trim().lowercase()
        lastTrustedSource = "companion"
    }

    fun consumeTrustedCallAction(
        source: String,
        vararg acceptedActions: String,
    ): Boolean {
        val fresh = System.currentTimeMillis() - lastTrustedSourceActionAt <=
            ACTION_WINDOW_MS
        val sourceMatches = lastTrustedSource == source.trim().lowercase()
        val actionMatches = acceptedActions.isEmpty() || acceptedActions.any {
            it.trim().lowercase() == lastTrustedSourceAction
        }
        val allowed = fresh && sourceMatches && actionMatches
        if (allowed || !fresh) {
            lastTrustedSourceActionAt = 0L
            lastTrustedSourceAction = ""
            lastTrustedSource = ""
        }
        return allowed
    }

    fun canManualCallAction(context: Context): Decision = Decision(
        allowed = true,
        reason = "Kullanıcının çağrı ekranındaki doğrudan işlemi.",
        mode = "manual",
        userInitiated = true,
    )

    fun canAutoAnswer(context: Context, rawNumber: String?): Decision {
        val authorized = NovaAuthorizedCallRegistry
            .isAuthorizedCallHandlingNumber(context, rawNumber)
        val night = isNightAnswerWindowActive(context)
        return Decision(
            allowed = authorized && night,
            reason = when {
                !authorized -> "Otomatik cevap yalnız izin verilen kişilerde çalışır."
                !night -> "Otomatik cevap için gece/uyku çalışma penceresi aktif değil."
                else -> "Yetkili kişi için gece modu otomatik cevabı açık."
            },
            mode = if (authorized && night) {
                "auto_answer_allowed"
            } else {
                "auto_answer_blocked"
            },
            authorizedNumber = authorized,
            nightActive = night,
        )
    }

    fun canNovaTakeover(context: Context, rawNumber: String?): Decision =
        contactDecision(context, rawNumber, "handoff")

    fun canCompanionCallControl(
        context: Context,
        rawNumber: String?,
    ): Decision = contactDecision(context, rawNumber, "companion_call_control")

    fun canAutonomousCallControl(
        context: Context,
        rawNumber: String?,
    ): Decision {
        val contact = contactDecision(context, rawNumber, "autonomous_call_control")
        val night = isNightAnswerWindowActive(context)
        return contact.copy(
            allowed = contact.allowed && night,
            reason = if (!contact.allowed) {
                contact.reason
            } else if (!night) {
                "Arka plan çağrı kontrolü için gece/uyku penceresi aktif değil."
            } else {
                "Yetkili kişi için arka plan çağrı kontrolü açık."
            },
            nightActive = night,
        )
    }

    fun canStartOutgoingCall(context: Context, rawNumber: String?): Decision {
        val carrier = NovaCarrierBoundaryGuard.canPlaceCall(
            context = context,
            rawNumber = rawNumber,
        )
        return Decision(
            allowed = carrier.allowed,
            reason = carrier.reason,
            mode = carrier.mode,
            authorizedNumber = NovaAuthorizedCallRegistry
                .isAuthorizedCallHandlingNumber(context, rawNumber),
            nightActive = isNightAnswerWindowActive(context),
            userInitiated = carrier.userInitiated,
        )
    }

    fun isNightAnswerWindowActive(context: Context): Boolean {
        val prefs = context.applicationContext.getSharedPreferences(
            FLUTTER_PREFS,
            Context.MODE_PRIVATE,
        )
        val nowMs = System.currentTimeMillis()
        val scheduledHold = prefs
            .getString(SCHEDULED_NIGHT_HOLD_KEY, "")
            .orEmpty()
            .trim()
        if (parseIsoEpochMs(scheduledHold)?.let { it > nowMs } == true) return true

        val statusRaw = prefs.getString(STATUS_KEY, "").orEmpty().trim()
        runCatching {
            val root = JSONObject(statusRaw)
            val active = root.optJSONObject("activeStatus")
            val expires = active?.optString("expiresAt", "")
            if (parseIsoEpochMs(expires.orEmpty())?.let { it > nowMs } == true) {
                return true
            }
            val config = root.optJSONObject("config")
            val start = config?.optInt("nightlySleepStartHour", 23) ?: 23
            val end = config?.optInt("nightlySleepEndHour", 6) ?: 6
            if (isHourWithinWindow(currentHour(), start, end)) return true
        }

        val powerRaw = prefs.getString(POWER_MODE_KEY, "").orEmpty().trim()
        runCatching {
            if (JSONObject(powerRaw).optString("mode", "") == "passiveSleep") {
                return true
            }
        }
        return isHourWithinWindow(currentHour(), 23, 6)
    }

    fun recordDeniedAction(
        context: Context,
        action: String,
        reason: String,
        highRisk: Boolean,
    ) {
        Log.w(
            "NOVA_CALL_AUTHORITY",
            "denied action=${action.trim()} highRisk=$highRisk reason=${reason.trim()}",
        )
    }

    fun clearCallLockdown(context: Context) {
        // Compatibility no-op. The automatic call lockdown no longer exists.
    }

    private fun contactDecision(
        context: Context,
        rawNumber: String?,
        mode: String,
    ): Decision {
        val authorized = NovaAuthorizedCallRegistry
            .isAuthorizedCallHandlingNumber(context, rawNumber)
        return Decision(
            allowed = authorized,
            reason = if (authorized) {
                "Kişi NOVA çağrı yönetimi listesinde."
            } else {
                "Bu çağrı kişisi NOVA çağrı yönetimi listesinde değil."
            },
            mode = if (authorized) "${mode}_allowed" else "${mode}_blocked",
            authorizedNumber = authorized,
            nightActive = isNightAnswerWindowActive(context),
        )
    }

    private fun isHourWithinWindow(hour: Int, startRaw: Int, endRaw: Int): Boolean {
        val start = startRaw.coerceIn(0, 23)
        val end = endRaw.coerceIn(0, 23)
        if (start == end) return false
        return if (start < end) hour in start until end else hour >= start || hour < end
    }

    private fun currentHour(): Int = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)

    private fun parseIsoEpochMs(raw: String): Long? {
        val value = raw.trim()
        if (value.isEmpty()) return null
        val candidates = listOf(
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'" to TimeZone.getTimeZone("UTC"),
            "yyyy-MM-dd'T'HH:mm:ss'Z'" to TimeZone.getTimeZone("UTC"),
            "yyyy-MM-dd'T'HH:mm:ss.SSS" to TimeZone.getDefault(),
            "yyyy-MM-dd'T'HH:mm:ss" to TimeZone.getDefault(),
        )
        for ((pattern, zone) in candidates) {
            val parsed = runCatching {
                SimpleDateFormat(pattern, Locale.US).apply {
                    timeZone = zone
                }.parse(value)?.time
            }.getOrNull()
            if (parsed != null) return parsed
        }
        return null
    }
}
