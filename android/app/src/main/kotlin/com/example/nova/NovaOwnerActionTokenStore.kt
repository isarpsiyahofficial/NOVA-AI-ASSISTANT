package com.example.nova

import android.content.Context
import android.util.Base64
import java.security.SecureRandom

/**
 * In-memory, short-lived, single-use owner action tokens.
 *
 * A token is issued only after native TitaNet matched the voiceprint that was
 * explicitly marked as the device owner. It must then be bound to the current
 * Dart turn lease and that lease must be activated before the token can be
 * consumed by a native action bridge.
 */
object NovaOwnerActionTokenStore {
    private const val PREFS = "nova_owner_action_authority"
    private const val OWNER_VOICE_ID = "owner_voice_id"
    private const val TOKEN_TTL_MS = 20_000L
    private val random = SecureRandom()
    private val lock = Any()

    private data class Entry(
        val token: String,
        val ownerVoiceId: String,
        val expiresAt: Long,
        var leaseId: String = "",
        var consumed: Boolean = false,
    )

    private val entries = LinkedHashMap<String, Entry>()
    @Volatile private var activeLeaseId: String = ""

    fun setOwnerVoiceId(context: Context, voiceId: String): Boolean {
        val safe = voiceId.trim()
        if (safe.isEmpty()) return false
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(OWNER_VOICE_ID, safe)
            .apply()
        synchronized(lock) {
            entries.clear()
            activeLeaseId = ""
        }
        return true
    }

    fun issueForMatchedOwner(context: Context, voiceId: String): String {
        val safeVoiceId = voiceId.trim()
        val ownerVoiceId = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(OWNER_VOICE_ID, "")
            .orEmpty()
            .trim()
        if (safeVoiceId.isEmpty() || ownerVoiceId.isEmpty() || safeVoiceId != ownerVoiceId) {
            return ""
        }

        val bytes = ByteArray(32)
        random.nextBytes(bytes)
        val token = Base64.encodeToString(
            bytes,
            Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING,
        )
        val now = System.currentTimeMillis()
        synchronized(lock) {
            purgeLocked(now)
            entries[token] = Entry(
                token = token,
                ownerVoiceId = ownerVoiceId,
                expiresAt = now + TOKEN_TTL_MS,
            )
            while (entries.size > 8) {
                entries.remove(entries.keys.first())
            }
        }
        return token
    }

    fun bindToLease(token: String, leaseId: String): Boolean {
        val safeToken = token.trim()
        val safeLease = leaseId.trim()
        if (safeToken.isEmpty() || safeLease.isEmpty()) return false
        val now = System.currentTimeMillis()
        synchronized(lock) {
            purgeLocked(now)
            val entry = entries[safeToken] ?: return false
            if (entry.consumed || entry.expiresAt <= now || entry.leaseId.isNotEmpty()) {
                return false
            }
            entry.leaseId = safeLease
            return true
        }
    }

    fun activateLease(leaseId: String) {
        val safeLease = leaseId.trim()
        synchronized(lock) {
            activeLeaseId = safeLease
            val now = System.currentTimeMillis()
            purgeLocked(now)
            if (safeLease.isEmpty()) entries.clear()
        }
    }

    fun consume(token: String): Boolean {
        val safeToken = token.trim()
        if (safeToken.isEmpty()) return false
        val now = System.currentTimeMillis()
        synchronized(lock) {
            purgeLocked(now)
            val entry = entries[safeToken] ?: return false
            val allowed = !entry.consumed &&
                entry.expiresAt > now &&
                entry.leaseId.isNotEmpty() &&
                entry.leaseId == activeLeaseId
            entry.consumed = true
            entries.remove(safeToken)
            return allowed
        }
    }

    fun clearOwner(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(OWNER_VOICE_ID)
            .apply()
        synchronized(lock) {
            entries.clear()
            activeLeaseId = ""
        }
    }

    private fun purgeLocked(now: Long) {
        val expired = entries.values
            .filter { it.consumed || it.expiresAt <= now }
            .map { it.token }
        expired.forEach(entries::remove)
    }
}
