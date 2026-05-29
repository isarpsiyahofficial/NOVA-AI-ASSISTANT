package com.example.nova

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

object NovaCallAuthorityGuard {
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val STATUS_KEY = "flutter.nova_status_state_v1"
    private const val POWER_MODE_KEY = "flutter.nova_power_mode_v1"
    private const val SCHEDULED_NIGHT_HOLD_KEY = "flutter.nova_power_manual_night_hold_until_v1"
    private const val CALL_LOCKDOWN_UNTIL_KEY = "nova_call_security_lockdown_until_v1"
    private const val CALL_EVENT_LOG_KEY = "nova_call_security_event_log_v1"

    private const val USER_ACTION_WINDOW_MS = 5000L
    private const val TRUSTED_SOURCE_WINDOW_MS = 5000L
    private const val LOCKDOWN_WINDOW_MS = 120000L
    private const val LOCKDOWN_DURATION_MS = 15 * 60 * 1000L

    @Volatile
    private var lastUserCallActionAt: Long = 0L

    @Volatile
    private var lastUserCallAction: String = ""

    @Volatile
    private var lastTrustedSourceActionAt: Long = 0L

    @Volatile
    private var lastTrustedSourceAction: String = ""

    @Volatile
    private var lastTrustedSource: String = ""

    data class Decision(
        val allowed: Boolean,
        val reason: String,
        val mode: String = "blocked",
        val authorizedNumber: Boolean = false,
        val nightActive: Boolean = false,
        val userInitiated: Boolean = false
    ) {
        fun toMap(): Map<String, Any> = mapOf(
            "allowed" to allowed,
            "reason" to reason,
            "mode" to mode,
            "authorizedNumber" to authorizedNumber,
            "nightActive" to nightActive,
            "userInitiated" to userInitiated
        )
    }

    fun registerUserCallAction(action: String) {
        lastUserCallActionAt = System.currentTimeMillis()
        lastUserCallAction = action.trim().lowercase()
    }

    fun isRecentUserCallAction(vararg acceptedActions: String): Boolean {
        val now = System.currentTimeMillis()
        if (now - lastUserCallActionAt > USER_ACTION_WINDOW_MS) return false
        if (acceptedActions.isEmpty()) return true
        val action = lastUserCallAction
        return acceptedActions.any { it.trim().lowercase() == action }
    }

    fun consumeUserCallAction(vararg acceptedActions: String): Boolean {
        val ok = isRecentUserCallAction(*acceptedActions)
        if (ok) {
            lastUserCallActionAt = 0L
            lastUserCallAction = ""
        }
        return ok
    }

    fun registerTrustedCallAction(action: String, source: String) {
        val normalizedSource = source.trim().lowercase()
        if (normalizedSource != "companion") return
        lastTrustedSourceActionAt = System.currentTimeMillis()
        lastTrustedSourceAction = action.trim().lowercase()
        lastTrustedSource = normalizedSource
    }

    fun consumeTrustedCallAction(source: String, vararg acceptedActions: String): Boolean {
        val now = System.currentTimeMillis()
        if (now - lastTrustedSourceActionAt > TRUSTED_SOURCE_WINDOW_MS) return false
        if (lastTrustedSource != source.trim().lowercase()) return false
        val action = lastTrustedSourceAction
        val ok = acceptedActions.isEmpty() || acceptedActions.any { it.trim().lowercase() == action }
        if (ok) {
            lastTrustedSourceActionAt = 0L
            lastTrustedSourceAction = ""
            lastTrustedSource = ""
        }
        return ok
    }

    fun canManualCallAction(context: Context): Decision {
        val security = securityAllowsCallFlow(context)
        if (!security.allowed) return security
        return Decision(
            allowed = true,
            reason = "Kullanıcı çağrı ekranında manuel işlem yaptı.",
            mode = "manual",
            userInitiated = true
        )
    }

    fun canAutoAnswer(context: Context, rawNumber: String?): Decision {
        val security = securityAllowsCallFlow(context)
        if (!security.allowed) return security

        val authorized = NovaAuthorizedCallRegistry.isAuthorizedCallHandlingNumber(context, rawNumber)
        val night = isNightAnswerWindowActive(context)

        return when {
            !authorized -> {
                recordDeniedAction(context, "auto_answer", "Otomatik cevap engellendi: kişi Nova çağrı yetki listesinde değil.", true)
                Decision(
                allowed = false,
                reason = "Otomatik cevap engellendi: kişi Nova çağrı yetki listesinde değil.",
                mode = "auto_answer_blocked",
                authorizedNumber = false,
                nightActive = night
            )
            }
            !night -> {
                recordDeniedAction(context, "auto_answer", "Otomatik cevap engellendi: gece modu veya süreli gece/uyku penceresi aktif değil.", true)
                Decision(
                allowed = false,
                reason = "Otomatik cevap engellendi: gece modu veya süreli gece/uyku penceresi aktif değil.",
                mode = "auto_answer_blocked",
                authorizedNumber = true,
                nightActive = false
            )
            }
            else -> Decision(
                allowed = true,
                reason = "Otomatik cevap izni var: yetkili kişi ve gece/süreli gece penceresi aktif.",
                mode = "auto_answer_allowed",
                authorizedNumber = true,
                nightActive = true
            )
        }
    }

    fun canNovaTakeover(context: Context, rawNumber: String?): Decision {
        val security = securityAllowsCallFlow(context)
        if (!security.allowed) return security

        val authorized = NovaAuthorizedCallRegistry.isAuthorizedCallHandlingNumber(context, rawNumber)
        return if (authorized) {
            Decision(
                allowed = true,
                reason = "Nova devralma izni var: kişi çağrı yetki listesinde.",
                mode = "handoff_allowed",
                authorizedNumber = true,
                nightActive = isNightAnswerWindowActive(context)
            )
        } else {
            Decision(
                allowed = false,
                reason = "Nova devralma engellendi: kişi çağrı yetki listesinde değil.",
                mode = "handoff_blocked",
                authorizedNumber = false,
                nightActive = isNightAnswerWindowActive(context)
            )
        }
    }

    fun canCompanionCallControl(context: Context, rawNumber: String?): Decision {
        val security = securityAllowsCallFlow(context)
        if (!security.allowed) return security

        val authorized = NovaAuthorizedCallRegistry.isAuthorizedCallHandlingNumber(context, rawNumber)
        return if (authorized) {
            Decision(
                allowed = true,
                reason = "Companion çağrı yardımı izni var: kişi çağrı yetki listesinde.",
                mode = "companion_call_control_allowed",
                authorizedNumber = true,
                nightActive = isNightAnswerWindowActive(context)
            )
        } else {
            recordDeniedAction(context, "companion_call_control", "Companion çağrı yardımı engellendi: kişi çağrı yetki listesinde değil.", true)
            Decision(
                allowed = false,
                reason = "Companion çağrı yardımı engellendi: kişi çağrı yetki listesinde değil.",
                mode = "companion_call_control_blocked",
                authorizedNumber = false,
                nightActive = isNightAnswerWindowActive(context)
            )
        }
    }

    fun canAutonomousCallControl(context: Context, rawNumber: String?): Decision {
        val security = securityAllowsCallFlow(context)
        if (!security.allowed) return security

        val authorized = NovaAuthorizedCallRegistry.isAuthorizedCallHandlingNumber(context, rawNumber)
        val night = isNightAnswerWindowActive(context)
        return when {
            !authorized -> {
                recordDeniedAction(context, "autonomous_call_control", "Arka plan çağrı kontrolü engellendi: kişi Nova çağrı yetki listesinde değil.", true)
                Decision(
                allowed = false,
                reason = "Arka plan çağrı kontrolü engellendi: kişi Nova çağrı yetki listesinde değil.",
                mode = "autonomous_call_control_blocked",
                authorizedNumber = false,
                nightActive = night
            )
            }
            !night -> {
                recordDeniedAction(context, "autonomous_call_control", "Arka plan çağrı kontrolü engellendi: gece modu veya süreli gece penceresi aktif değil.", true)
                Decision(
                allowed = false,
                reason = "Arka plan çağrı kontrolü engellendi: gece modu veya süreli gece penceresi aktif değil.",
                mode = "autonomous_call_control_blocked",
                authorizedNumber = true,
                nightActive = false
            )
            }
            else -> Decision(
                allowed = true,
                reason = "Arka plan çağrı kontrolü izni var: yetkili kişi ve gece/süreli gece penceresi aktif.",
                mode = "autonomous_call_control_allowed",
                authorizedNumber = true,
                nightActive = true
            )
        }
    }

    fun canStartOutgoingCall(context: Context, rawNumber: String?): Decision {
        val security = securityAllowsCallFlow(context)
        if (!security.allowed) return security

        val carrier = NovaCarrierBoundaryGuard.canPlaceCall(
            context = context,
            rawNumber = rawNumber,
            source = "authority_guard",
            userInitiated = false
        )
        return Decision(
            allowed = carrier.allowed,
            reason = carrier.reason,
            mode = carrier.mode,
            authorizedNumber = NovaAuthorizedCallRegistry.isAuthorizedCallHandlingNumber(context, rawNumber),
            nightActive = isNightAnswerWindowActive(context),
            userInitiated = carrier.userInitiated
        )
    }

    fun isNightAnswerWindowActive(context: Context): Boolean {
        val prefs = context.applicationContext.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        val nowMs = System.currentTimeMillis()

        val scheduledHold = prefs.getString(SCHEDULED_NIGHT_HOLD_KEY, "").orEmpty().trim()
        if (parseIsoEpochMs(scheduledHold)?.let { it > nowMs } == true) return true

        val statusRaw = prefs.getString(STATUS_KEY, "").orEmpty().trim()
        if (statusRaw.isNotEmpty()) {
            try {
                val root = JSONObject(statusRaw)
                val active = root.optJSONObject("activeStatus")
                if (active != null) {
                    val expires = parseIsoEpochMs(active.optString("expiresAt", ""))
                    if (expires != null && expires > nowMs) return true
                }

                val config = root.optJSONObject("config")
                val start = config?.optInt("nightlySleepStartHour", 23) ?: 23
                val end = config?.optInt("nightlySleepEndHour", 6) ?: 6
                if (isHourWithinWindow(currentHour(), start, end)) return true
            } catch (_: Throwable) {
                // Bozuk status JSON güvenli tarafta kalır; varsayılan pencere kontrolüne düşer.
            }
        }

        val powerRaw = prefs.getString(POWER_MODE_KEY, "").orEmpty().trim()
        if (powerRaw.isNotEmpty()) {
            try {
                val mode = JSONObject(powerRaw).optString("mode", "").trim()
                if (mode == "passiveSleep") return true
            } catch (_: Throwable) {
            }
        }

        return isHourWithinWindow(currentHour(), 23, 6)
    }

    private fun securityAllowsCallFlow(context: Context): Decision {
        return Decision(
            allowed = true,
            reason = "API-first sürümde çağrı güvenlik kalkanı pasif; çağrı akışı eski kill/blackout state ile engellenmez.",
            mode = "api_first_call_security_passive"
        )
    }

    fun recordDeniedAction(
        context: Context,
        action: String,
        reason: String,
        highRisk: Boolean
    ) {
        try {
            val prefs = context.applicationContext.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            val now = System.currentTimeMillis()
            val raw = prefs.getString(CALL_EVENT_LOG_KEY, "[]").orEmpty()
            val arr = try {
                JSONArray(raw)
            } catch (_: Throwable) {
                JSONArray()
            }

            val compact = JSONArray()
            var recentHighRisk = 0

            for (i in 0 until arr.length()) {
                val item = arr.optJSONObject(i) ?: continue
                val at = item.optLong("at", 0L)
                if (now - at <= LOCKDOWN_WINDOW_MS) {
                    compact.put(item)
                    if (item.optBoolean("highRisk", false)) {
                        recentHighRisk++
                    }
                }
            }

            val entry = JSONObject()
                .put("at", now)
                .put("action", action.trim())
                .put("reason", reason.trim())
                .put("highRisk", highRisk)
                .put("apiFirstSecurityPassive", true)
            compact.put(entry)

            if (highRisk) {
                recentHighRisk++
            }

            while (compact.length() > 40) {
                compact.remove(0)
            }

            val editor = prefs.edit().putString(CALL_EVENT_LOG_KEY, compact.toString())
            // API-first sürümde eski kill/blackout güvenlik kalkanı pasif kalır;
            // yine de audit ve lockdown zaman damgası korunur ki UI/diagnostics tarafı
            // yetkisiz çağrı denemelerini görebilsin. securityAllowsCallFlow bu değeri
            // çağrı akışını otomatik öldürmek için kullanmaz.
            if (highRisk && recentHighRisk >= 3) {
                editor.putLong(CALL_LOCKDOWN_UNTIL_KEY, now + LOCKDOWN_DURATION_MS)
            }
            editor.apply()
        } catch (_: Throwable) {
            // Çağrı kontrolü log yazılamadığı için çökmemeli.
        }
    }

    fun clearCallLockdown(context: Context) {
        try {
            val prefs = context.applicationContext.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
            prefs.edit().remove(CALL_LOCKDOWN_UNTIL_KEY).apply()
        } catch (_: Throwable) {
        }
    }

    private fun isHourWithinWindow(hour: Int, startRaw: Int, endRaw: Int): Boolean {
        val start = startRaw.coerceIn(0, 23)
        val end = endRaw.coerceIn(0, 23)
        if (start == end) return false
        return if (start < end) {
            hour >= start && hour < end
        } else {
            hour >= start || hour < end
        }
    }

    private fun currentHour(): Int {
        return Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
    }

    private fun parseIsoEpochMs(raw: String): Long? {
        val value = raw.trim()
        if (value.isEmpty()) return null

        val utcPatterns = listOf(
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ss'Z'"
        )
        for (pattern in utcPatterns) {
            try {
                val formatter = SimpleDateFormat(pattern, Locale.US)
                formatter.timeZone = TimeZone.getTimeZone("UTC")
                formatter.parse(value)?.time?.let { return it }
            } catch (_: Throwable) {
            }
        }

        val localPatterns = listOf(
            "yyyy-MM-dd'T'HH:mm:ss.SSS",
            "yyyy-MM-dd'T'HH:mm:ss"
        )
        for (pattern in localPatterns) {
            try {
                val formatter = SimpleDateFormat(pattern, Locale.US)
                formatter.timeZone = TimeZone.getDefault()
                formatter.parse(value)?.time?.let { return it }
            } catch (_: Throwable) {
            }
        }

        return null
    }
}
