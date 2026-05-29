package com.example.nova

import android.telecom.Call

object NovaCallStateBridge {

    private var activeNumber: String = ""
    private var inCall: Boolean = false
    private var stateLabel: String = "idle"
    private var isRinging: Boolean = false
    private var isActiveCall: Boolean = false
    private var canAnswer: Boolean = false
    private var canDisconnect: Boolean = false
    private var canMute: Boolean = false
    private var isMuted: Boolean = false
    private var isSpeakerOn: Boolean = false
    private var currentAudioRoute: String = "earpiece"
    private var callerDisplayName: String = ""
    private var notificationVisible: Boolean = false
    private var isDefaultDialer: Boolean = false
    private var telephonyObserverReady: Boolean = false
    private var callScreeningReady: Boolean = false
    private var lastObservedAuthorizedNumber: Boolean = false

    fun updateCall(number: String?, state: Int, callerName: String? = null) {
        activeNumber = normalizePhone(number)
        callerDisplayName = callerName?.trim().orEmpty()

        isRinging = state == Call.STATE_RINGING
        isActiveCall = when (state) {
            Call.STATE_ACTIVE,
            Call.STATE_CONNECTING,
            Call.STATE_DIALING,
            Call.STATE_HOLDING -> true
            else -> false
        }

        inCall = isRinging || isActiveCall

        stateLabel = when (state) {
            Call.STATE_NEW -> "new"
            Call.STATE_DIALING -> "dialing"
            Call.STATE_RINGING -> "ringing"
            Call.STATE_ACTIVE -> "active"
            Call.STATE_HOLDING -> "holding"
            Call.STATE_DISCONNECTED -> "disconnected"
            Call.STATE_DISCONNECTING -> "disconnecting"
            Call.STATE_CONNECTING -> "connecting"
            Call.STATE_SELECT_PHONE_ACCOUNT -> "select_phone_account"
            else -> "idle"
        }

        canAnswer = isRinging
        canDisconnect = inCall
        canMute = isActiveCall

        if (!inCall) {
            activeNumber = ""
            isMuted = false
            isSpeakerOn = false
            currentAudioRoute = "earpiece"
            callerDisplayName = ""
            notificationVisible = false
        }
    }

    fun updateMuteState(value: Boolean) {
        isMuted = value
    }

    fun updateSpeakerState(value: Boolean) {
        isSpeakerOn = value
        if (value) {
            currentAudioRoute = "speaker"
        } else if (currentAudioRoute == "speaker") {
            currentAudioRoute = "earpiece"
        }
    }

    fun updateAudioRoute(value: String) {
        currentAudioRoute = value.trim().ifEmpty { if (isSpeakerOn) "speaker" else "earpiece" }
        isSpeakerOn = currentAudioRoute == "speaker"
    }

    fun updateNotificationState(visible: Boolean) {
        notificationVisible = visible
    }

    fun updateAuthorizedNumber(value: Boolean) {
        lastObservedAuthorizedNumber = value
    }

    fun updateTelephonyObservation(number: String?, stateLabel: String, isRinging: Boolean, isActiveCall: Boolean, authorizedNumber: Boolean, observerAvailable: Boolean) {
        val normalized = normalizePhone(number)
        val incomingState = stateLabel.trim().ifEmpty { if (isRinging) "ringing" else if (isActiveCall) "active" else "idle" }
        val callOngoing = isRinging || isActiveCall

        if (normalized.isNotEmpty() && (activeNumber.isEmpty() || activeNumber == normalized || !inCall)) {
            activeNumber = normalized
        }
        if (callerDisplayName.isBlank() && normalized.isNotEmpty()) {
            callerDisplayName = normalized
        }

        if (!inCall || activeNumber.isEmpty() || this.stateLabel == "idle" || incomingState == "ringing" || incomingState == "active") {
            this.stateLabel = incomingState
            this.isRinging = isRinging
            this.isActiveCall = isActiveCall
            inCall = callOngoing
            canAnswer = isRinging
            canDisconnect = callOngoing
            canMute = isActiveCall
        }

        if (!callOngoing && !inCall) {
            activeNumber = ""
            isMuted = false
            isSpeakerOn = false
            currentAudioRoute = "earpiece"
            callerDisplayName = ""
            notificationVisible = false
        }

        lastObservedAuthorizedNumber = authorizedNumber
        telephonyObserverReady = observerAvailable
    }

    fun updateScreeningObservation(
        number: String?,
        isRinging: Boolean,
        authorizedNumber: Boolean,
        screeningAvailable: Boolean,
        callerName: String? = null,
    ) {
        val normalized = normalizePhone(number)
        val resolvedName = callerName?.trim().orEmpty()
        if (normalized.isNotEmpty()) {
            activeNumber = normalized
            callerDisplayName = resolvedName.ifBlank {
                if (callerDisplayName.isBlank() || callerDisplayName == normalized) normalized else callerDisplayName
            }
        } else if (resolvedName.isNotBlank()) {
            callerDisplayName = resolvedName
        }
        if (isRinging) {
            stateLabel = "ringing"
            this.isRinging = true
            inCall = true
            canAnswer = true
            canDisconnect = true
            canMute = false
        }
        lastObservedAuthorizedNumber = authorizedNumber
        callScreeningReady = screeningAvailable
    }

    fun updateDefaultDialerState(value: Boolean) {
        isDefaultDialer = value
    }

    fun getState(): Map<String, Any> {
        return mapOf(
            "inCall" to inCall,
            "number" to activeNumber,
            "state" to stateLabel,
            "isRinging" to isRinging,
            "isActiveCall" to isActiveCall,
            "canAnswer" to canAnswer,
            "canDisconnect" to canDisconnect,
            "canMute" to canMute,
            "isMuted" to isMuted,
            "isSpeakerOn" to isSpeakerOn,
            "currentAudioRoute" to currentAudioRoute,
            "callerDisplayName" to callerDisplayName,
            "notificationVisible" to notificationVisible,
            "isDefaultDialer" to isDefaultDialer,
            "telephonyObserverReady" to telephonyObserverReady,
            "callScreeningReady" to callScreeningReady,
            "isAuthorizedManagedNumber" to lastObservedAuthorizedNumber,
        )
    }

    private fun normalizePhone(value: String?): String {
        val raw = value?.trim().orEmpty()
        if (raw.isEmpty()) return ""

        val builder = StringBuilder()
        var hasPlus = false
        raw.forEachIndexed { index, c ->
            when {
                c == '+' && !hasPlus && index == 0 -> {
                    hasPlus = true
                    builder.append(c)
                }
                c.isDigit() -> builder.append(c)
            }
        }

        var normalized = builder.toString()
        if (normalized.startsWith("00")) {
            normalized = "+" + normalized.substring(2)
        }
        if (normalized.length == 10) {
            normalized = "+90$normalized"
        } else if (normalized.length == 11 && normalized.startsWith("0")) {
            normalized = "+90${normalized.substring(1)}"
        }
        return normalized
    }
}
