package com.example.nova

import android.content.Context

class NovaSecurityStateStore(
    context: Context
) {
    private val integrityVault = NovaSecurityIntegrityVault(context.applicationContext)
    private val baseContext = context.applicationContext
    private val deviceProtectedContext: Context =
        baseContext.createDeviceProtectedStorageContext() ?: baseContext

    private val prefs =
        baseContext.getSharedPreferences("nova_security_native_v2", Context.MODE_PRIVATE)
    private val devicePrefs =
        deviceProtectedContext.getSharedPreferences("nova_security_device_v2", Context.MODE_PRIVATE)
    private val legacySafeKey = listOf("safe", "decommissioned").joinToString("_")
    private val legacyFinalKey = listOf("final", "destroyed").joinToString("_")
    private val legacyInternetSafeKey = listOf("internet", "safe", "decommissioned").joinToString("_")
    private val legacyInternetFinalKey = listOf("internet", "final", "destroyed").joinToString("_")

    fun getKillStage(): String {
        return canonicalizeKillStage(readString("kill_stage", "none"))
    }

    fun setKillStage(value: String) {
        writeString("kill_stage", canonicalizeKillStage(normalizeStage(value)))
    }

    fun getContainmentStage(): String {
        return readString("containment_stage", "allow")
    }

    fun setContainmentStage(value: String) {
        writeString("containment_stage", canonicalizeKillStage(value.trim().ifBlank { "allow" }))
    }

    fun getLastReason(): String {
        return readString("last_reason", "")
    }

    fun setLastReason(value: String) {
        writeString("last_reason", value.trim())
    }

    fun setLastUpdatedAt(epochMs: Long) {
        writeLong("last_updated_at", epochMs)
    }

    fun getLastUpdatedAt(): Long {
        return readLong("last_updated_at", 0L)
    }

    fun setBootAllowed(value: Boolean) = writeBoolean("boot_allowed", value)
    fun getBootAllowed(defaultValue: Boolean = true): Boolean = readBoolean("boot_allowed", defaultValue)

    fun setRuntimeAllowed(value: Boolean) = writeBoolean("runtime_allowed", value)
    fun getRuntimeAllowed(defaultValue: Boolean = true): Boolean = readBoolean("runtime_allowed", defaultValue)

    fun setNativeBridgeAllowed(value: Boolean) = writeBoolean("native_bridge_allowed", value)
    fun getNativeBridgeAllowed(defaultValue: Boolean = true): Boolean = readBoolean("native_bridge_allowed", defaultValue)

    fun setBackgroundAllowed(value: Boolean) = writeBoolean("background_allowed", value)
    fun getBackgroundAllowed(defaultValue: Boolean = true): Boolean = readBoolean("background_allowed", defaultValue)

    fun setModelPresenceAllowed(value: Boolean) = writeBoolean("model_presence_allowed", value)
    fun getModelPresenceAllowed(defaultValue: Boolean = true): Boolean = readBoolean("model_presence_allowed", defaultValue)

    fun setActionSurfaceAllowed(value: Boolean) = writeBoolean("action_surface_allowed", value)
    fun getActionSurfaceAllowed(defaultValue: Boolean = true): Boolean = readBoolean("action_surface_allowed", defaultValue)

    fun setCallFlowAllowed(value: Boolean) = writeBoolean("call_flow_allowed", value)
    fun getCallFlowAllowed(defaultValue: Boolean = true): Boolean = readBoolean("call_flow_allowed", defaultValue)

    fun setMediaFlowAllowed(value: Boolean) = writeBoolean("media_flow_allowed", value)
    fun getMediaFlowAllowed(defaultValue: Boolean = true): Boolean = readBoolean("media_flow_allowed", defaultValue)

    fun setSelfRepairAllowed(value: Boolean) = writeBoolean("self_repair_allowed", value)
    fun getSelfRepairAllowed(defaultValue: Boolean = true): Boolean = readBoolean("self_repair_allowed", defaultValue)

    fun setNetworkIntentsAllowed(value: Boolean) = writeBoolean("network_intents_allowed", value)
    fun getNetworkIntentsAllowed(defaultValue: Boolean = false): Boolean = readBoolean("network_intents_allowed", defaultValue)

    fun setBlackoutActive(value: Boolean) = writeBoolean("blackout_active", value)
    fun getBlackoutActive(defaultValue: Boolean = false): Boolean = readBoolean("blackout_active", defaultValue)

    fun setSafeDecommissioned(value: Boolean) = writeBoolean("sealed_containment_flag", value)
    fun getSafeDecommissioned(defaultValue: Boolean = false): Boolean {
        val stage = getKillStage()
        return stage == "sealed_containment" || stage == "final_containment" || readBoolean("sealed_containment_flag", defaultValue) || readBoolean(legacySafeKey, false)
    }

    fun setFinalDestroyed(value: Boolean) = writeBoolean("final_containment_flag", value)
    fun getFinalDestroyed(defaultValue: Boolean = false): Boolean {
        val stage = getKillStage()
        return stage == "final_containment" || readBoolean("final_containment_flag", defaultValue) || readBoolean(legacyFinalKey, false)
    }

    fun setNightWatchActive(value: Boolean) = writeDeviceBoolean("night_watch_active", value)
    fun getNightWatchActive(defaultValue: Boolean = false): Boolean = readDeviceBoolean("night_watch_active", defaultValue)

    fun setInternetStage(value: String) = writeString("internet_stage", canonicalizeInternetStage(value.trim().ifBlank { "allow" }))
    fun getInternetStage(defaultValue: String = "allow"): String = canonicalizeInternetStage(readString("internet_stage", defaultValue))

    fun setInternetBrokerAllowed(value: Boolean) = writeBoolean("internet_broker_allowed", value)
    fun getInternetBrokerAllowed(defaultValue: Boolean = false): Boolean = readBoolean("internet_broker_allowed", defaultValue)

    fun setInternetBlackoutActive(value: Boolean) = writeBoolean("internet_blackout_active", value)
    fun getInternetBlackoutActive(defaultValue: Boolean = false): Boolean = readBoolean("internet_blackout_active", defaultValue)

    fun setInternetSafeDecommissioned(value: Boolean) = writeBoolean("internet_sealed_containment_flag", value)
    fun getInternetSafeDecommissioned(defaultValue: Boolean = false): Boolean {
        val stage = getInternetStage()
        return stage == "internet_sealed_containment" || stage == "internet_final_containment" || readBoolean("internet_sealed_containment_flag", defaultValue) || readBoolean(legacyInternetSafeKey, false)
    }

    fun setInternetFinalDestroyed(value: Boolean) = writeBoolean("internet_final_containment_flag", value)
    fun getInternetFinalDestroyed(defaultValue: Boolean = false): Boolean {
        val stage = getInternetStage()
        return stage == "internet_final_containment" || readBoolean("internet_final_containment_flag", defaultValue) || readBoolean(legacyInternetFinalKey, false)
    }

    fun setInternetObserverQuorum(value: Int) = writeInt("internet_observer_quorum", value.coerceIn(0, 100))
    fun getInternetObserverQuorum(defaultValue: Int = 0): Int = readInt("internet_observer_quorum", defaultValue)

    fun incrementInternetIncidentCount() {
        writeInt("internet_incident_count", getInternetIncidentCount() + 1)
    }

    fun getInternetIncidentCount(): Int = readInt("internet_incident_count", 0)

    fun setOwnerReachable(value: Boolean) = writeDeviceBoolean("owner_reachable", value)
    fun getOwnerReachable(defaultValue: Boolean = true): Boolean = readDeviceBoolean("owner_reachable", defaultValue)

    fun setObserverQuorum(value: Int) = writeInt("observer_quorum", value.coerceIn(0, 100))
    fun getObserverQuorum(defaultValue: Int = 0): Int = readInt("observer_quorum", defaultValue)

    fun setIntegrityMismatch(value: Boolean) = writeBoolean("integrity_mismatch", value)
    fun getIntegrityMismatch(defaultValue: Boolean = false): Boolean = readBoolean("integrity_mismatch", defaultValue) || !validateIntegrity()

    fun incrementIncidentCount() {
        writeInt("incident_count", getIncidentCount() + 1)
    }

    fun getIncidentCount(): Int {
        return readInt("incident_count", 0)
    }

    fun clearAll() {
        prefs.edit().clear().apply()
        devicePrefs.edit().clear().apply()
    }

    fun validateIntegrity(): Boolean {
        val signature = prefs.getString("integrity_signature", null)
        if (signature.isNullOrBlank()) {
            return prefs.all.isEmpty() && devicePrefs.all.isEmpty()
        }
        val payload = buildCriticalPayload()
        return integrityVault.verify(payload, signature)
    }

    fun clearAppStateOnly() {
        prefs.edit().clear().apply()
    }

    private fun normalizeStage(value: String): String {
        return value.trim().ifBlank { "none" }
    }

    private fun canonicalizeKillStage(value: String): String {
        val trimmed = value.trim()
        val legacySafe = listOf("safe", "decommissioned").joinToString("_")
        val legacyFinal = listOf("final", "destroyed").joinToString("_")
        val legacyHard = listOf("hard", "killed").joinToString("_")
        return when (trimmed) {
            legacySafe -> "sealed_containment"
            legacyFinal -> "final_containment"
            legacyHard -> "sealed_runtime"
            else -> trimmed.ifBlank { "none" }
        }
    }

    private fun canonicalizeInternetStage(value: String): String {
        val trimmed = value.trim()
        val legacyInternetSafe = listOf("internet", "safe", "decommission").joinToString("_")
        val legacyInternetFinal = listOf("internet", "final", "destroy").joinToString("_")
        return when (trimmed) {
            legacyInternetSafe -> "internet_sealed_containment"
            legacyInternetFinal -> "internet_final_containment"
            else -> trimmed.ifBlank { "allow" }
        }
    }

    private fun persistSignature() {
        val payload = buildCriticalPayload()
        val signature = try { integrityVault.sign(payload) } catch (_: Throwable) { return }
        prefs.edit().putString("integrity_signature", signature).apply()
    }

    private fun buildCriticalPayload(): String {
        val values = listOf(
            getKillStage(),
            getContainmentStage(),
            getLastReason(),
            getLastUpdatedAt().toString(),
            getBootAllowed().toString(),
            getRuntimeAllowed().toString(),
            getNativeBridgeAllowed().toString(),
            getBackgroundAllowed().toString(),
            getModelPresenceAllowed().toString(),
            getActionSurfaceAllowed().toString(),
            getCallFlowAllowed().toString(),
            getMediaFlowAllowed().toString(),
            getSelfRepairAllowed().toString(),
            getNetworkIntentsAllowed().toString(),
            getBlackoutActive().toString(),
            getSafeDecommissioned().toString(),
            getFinalDestroyed().toString(),
            getNightWatchActive().toString(),
            getInternetStage().toString(),
            getInternetBrokerAllowed().toString(),
            getInternetBlackoutActive().toString(),
            getInternetSafeDecommissioned().toString(),
            getInternetFinalDestroyed().toString(),
            getInternetObserverQuorum().toString(),
            getInternetIncidentCount().toString(),
            getOwnerReachable().toString(),
            getObserverQuorum().toString(),
            getIncidentCount().toString(),
            prefs.getBoolean("integrity_mismatch", false).toString(),
        )
        return values.joinToString("|")
    }

    private fun readBoolean(key: String, defaultValue: Boolean): Boolean = prefs.getBoolean(key, defaultValue)
    private fun writeBoolean(key: String, value: Boolean) { prefs.edit().putBoolean(key, value).apply(); persistSignature() }

    private fun readDeviceBoolean(key: String, defaultValue: Boolean): Boolean = devicePrefs.getBoolean(key, defaultValue)
    private fun writeDeviceBoolean(key: String, value: Boolean) { devicePrefs.edit().putBoolean(key, value).apply(); persistSignature() }

    private fun readString(key: String, defaultValue: String): String = prefs.getString(key, defaultValue)?.trim().orEmpty().ifBlank { defaultValue }
    private fun writeString(key: String, value: String) { prefs.edit().putString(key, value).apply(); persistSignature() }

    private fun readLong(key: String, defaultValue: Long): Long = prefs.getLong(key, defaultValue)
    private fun writeLong(key: String, value: Long) { prefs.edit().putLong(key, value).apply(); persistSignature() }

    private fun readInt(key: String, defaultValue: Int): Int = prefs.getInt(key, defaultValue)
    private fun writeInt(key: String, value: Int) { prefs.edit().putInt(key, value).apply(); persistSignature() }
}
