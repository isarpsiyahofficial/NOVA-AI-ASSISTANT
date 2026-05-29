package com.example.nova

// NOVA_API_FIRST_BOOT_GUARD_PASSIVE_V1
// Old persisted security/kill stages must not block the API-first rebuild.
// Keep method signatures stable for existing native callers, but make boot,
// runtime, bridge, background, overlay, call and API paths always pass.
class NovaBootGuard(
    private val store: NovaSecurityStateStore
) {
    fun isBootAllowed(): Boolean = true

    fun isRuntimeAllowed(): Boolean = true

    fun isLocalBrainAllowed(): Boolean = true

    fun isNativeBridgeAllowed(): Boolean = true

    fun isBackgroundAllowed(): Boolean = true

    // Local model file preparation is intentionally not required in the API-first build.
    fun isModelPresenceAllowed(): Boolean = false
}
