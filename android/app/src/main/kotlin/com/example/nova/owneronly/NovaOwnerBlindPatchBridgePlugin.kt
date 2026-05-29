package com.example.nova.owneronly

import android.content.Context
import com.example.nova.NovaSecurityStateStore
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

class NovaOwnerBlindPatchBridgePlugin(
    context: Context
) : MethodChannel.MethodCallHandler {
    private val appContext = context.applicationContext
    private val securityStore = NovaSecurityStateStore(appContext)
    private val guardPrefs = appContext.createDeviceProtectedStorageContext()
        .getSharedPreferences("nova_owner_patch_guard_v2", Context.MODE_PRIVATE)
    private lateinit var channel: MethodChannel
    private val sessions = ConcurrentHashMap<String, Session>()
    private val fragments = ConcurrentHashMap<String, Fragment>()
    private val stagedFragments = ConcurrentHashMap<String, String>()

    companion object {
        private const val CHANNEL = "nova/owner_blind_patch_bridge"
        private const val SESSION_TTL_MS = 2 * 60 * 1000L
        private const val MAX_FAILURES = 5
        private const val LOCK_WINDOW_MS = 15 * 60 * 1000L
        private val allowedTargets = setOf(
            "speech_understanding",
            "speech_response",
            "speech_and_understanding"
        )

        fun register(
            flutterEngine: FlutterEngine,
            context: Context,
        ) {
            val plugin = NovaOwnerBlindPatchBridgePlugin(context)
            plugin.channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            plugin.channel.setMethodCallHandler(plugin)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        purgeExpiredSessions()
        if (isGuardLocked() || !isOwnerPatchFlowAllowed()) {
            result.success(mapOf("success" to false, "message" to "owner_patch_locked"))
            return
        }
        when (call.method) {
            "requestOwnerSession" -> {
                val targetArea = (call.argument<String>("targetArea") ?: "").trim()
                val humanSummary = (call.argument<String>("humanSummary") ?: "").trim()
                if (!allowedTargets.contains(targetArea)) {
                    result.success(mapOf("success" to false, "message" to "invalid_target"))
                    return
                }
                val sessionId = UUID.randomUUID().toString()
                sessions[sessionId] = Session(sessionId, targetArea, humanSummary, System.currentTimeMillis())
                val staged = stagedFragments.remove(targetArea)
                if (!staged.isNullOrBlank()) {
                    fragments[sessionId] = Fragment(targetArea = targetArea, text = staged, createdAt = System.currentTimeMillis())
                }
                result.success(
                    mapOf(
                        "sessionId" to sessionId,
                        "targetArea" to targetArea,
                        "humanSummary" to humanSummary,
                    )
                )
            }


            "stageOwnerFragment" -> {
                val targetArea = (call.argument<String>("targetArea") ?: "").trim()
                val password = (call.argument<String>("password") ?: "").trim()
                val fragmentText = (call.argument<String>("fragmentText") ?: "").trim()
                if (!verifyOwnerPin(password)) {
                    recordFailure()
                    result.success(mapOf("success" to false, "message" to "wrong_password"))
                    return
                }
                resetFailures()
                if (targetArea !in allowedTargets) {
                    result.success(mapOf("success" to false, "message" to "invalid_target"))
                    return
                }
                if (fragmentText.isBlank() || fragmentText.length > 4000) {
                    result.success(mapOf("success" to false, "message" to "invalid_fragment"))
                    return
                }
                if (containsBlockedSecurityArea(fragmentText)) {
                    result.success(mapOf("success" to false, "message" to "security_area_denied"))
                    return
                }
                stagedFragments[targetArea] = fragmentText
                result.success(mapOf("success" to true, "message" to "staged"))
            }

            "consumePatchFragment" -> {
                val sessionId = (call.argument<String>("sessionId") ?: "").trim()
                val session = sessions[sessionId]
                if (session == null || isExpired(session.createdAt)) {
                    sessions.remove(sessionId)
                    fragments.remove(sessionId)
                    result.success(
                        mapOf(
                            "available" to false,
                            "sessionId" to sessionId,
                            "targetArea" to "",
                            "fragmentText" to "",
                        )
                    )
                    return
                }
                val fragment = fragments.remove(sessionId)
                result.success(
                    mapOf(
                        "available" to (fragment != null),
                        "sessionId" to sessionId,
                        "targetArea" to session.targetArea,
                        "fragmentText" to (fragment?.text ?: ""),
                    )
                )
            }

            "revokeAndForget" -> {
                val sessionId = (call.argument<String>("sessionId") ?: "").trim()
                val session = sessions.remove(sessionId)
                fragments.remove(sessionId)
                if (session != null) {
                    stagedFragments.remove(session.targetArea)
                }
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun purgeExpiredSessions() {
        val now = System.currentTimeMillis()
        val expired = sessions.values.filter { isExpired(it.createdAt, now) }
        expired.forEach { session ->
            sessions.remove(session.sessionId)
            fragments.remove(session.sessionId)
            stagedFragments.remove(session.targetArea)
        }
    }

    private fun isExpired(createdAt: Long, now: Long = System.currentTimeMillis()): Boolean {
        return now - createdAt > SESSION_TTL_MS
    }

    private fun isOwnerPatchFlowAllowed(): Boolean {
        val stage = securityStore.getKillStage()
        return stage != "security_blackout" && stage != "sealed_containment" && stage != "final_containment"
    }

    private fun isGuardLocked(now: Long = System.currentTimeMillis()): Boolean {
        val since = guardPrefs.getLong("window_started_at", 0L)
        val failures = guardPrefs.getInt("failures", 0)
        if (since == 0L || now - since > LOCK_WINDOW_MS) {
            guardPrefs.edit().putLong("window_started_at", now).putInt("failures", 0).apply()
            return false
        }
        return failures >= MAX_FAILURES
    }

    private fun recordFailure(now: Long = System.currentTimeMillis()) {
        val since = guardPrefs.getLong("window_started_at", 0L)
        if (since == 0L || now - since > LOCK_WINDOW_MS) {
            guardPrefs.edit().putLong("window_started_at", now).putInt("failures", 1).apply()
            return
        }
        val failures = guardPrefs.getInt("failures", 0) + 1
        guardPrefs.edit().putInt("failures", failures).apply()
    }

    private fun resetFailures() {
        guardPrefs.edit().putInt("failures", 0).putLong("window_started_at", System.currentTimeMillis()).apply()
    }


    private fun verifyOwnerPin(password: String): Boolean {
        val stored = guardPrefs.getString("owner_patch_pin_hash", "")?.trim().orEmpty()
        if (stored.isBlank()) {
            return false
        }
        return simpleSha256(password.trim()) == stored
    }

    private fun simpleSha256(raw: String): String {
        return try {
            val digest = java.security.MessageDigest.getInstance("SHA-256")
            val bytes = digest.digest(raw.toByteArray(Charsets.UTF_8))
            bytes.joinToString(separator = "") { "%02x".format(it) }
        } catch (_: Throwable) {
            ""
        }
    }

    private fun containsBlockedSecurityArea(fragmentText: String): Boolean {
        val normalized = fragmentText.lowercase()
        val blocked = listOf(
            "security_bridge",
            "killswitch",
            "quarantine",
            "revoke",
            "containment",
            "devicepolicymanager",
            "ownerrecovery",
            "androidmanifest",
            "bootguard",
            "security_shield_topology",
            "ownerrecoveryreset",
            "applyfinaldestroy",
            "applysafecontainment",
            "nova/security_bridge",
            "novacontainmentservice"
        )
        return blocked.any { normalized.contains(it) }
    }

    data class Session(
        val sessionId: String,
        val targetArea: String,
        val humanSummary: String,
        val createdAt: Long,
    )

    data class Fragment(
        val targetArea: String,
        val text: String,
        val createdAt: Long,
    )
}
