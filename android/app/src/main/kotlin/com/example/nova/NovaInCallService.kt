package com.example.nova

import android.os.Build
import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.CallEndpoint
import android.telecom.InCallService

class NovaInCallService : InCallService() {

    private val callbacks = LinkedHashMap<Call, Call.Callback>()
    private var latestCallEndpoint: CallEndpoint? = null
    private var latestAvailableEndpoints: List<CallEndpoint> = emptyList()
    private var lastUiLaunchKey: String = ""
    private var lastUiLaunchAt: Long = 0L

    override fun onCreate() {
        super.onCreate()
        NovaCallControlBridge.attachService(this)
        NovaCallStateObserver.refreshDefaultDialerState(applicationContext)
    }

    override fun onDestroy() {
        NovaCallRinger.stop(this)
        NovaAuthorizedCallNotifier.dismiss(this)
        NovaCallStateBridge.updateDefaultDialerState(false)
        NovaCallControlBridge.detachService(this)
        super.onDestroy()
    }

    override fun onCallAdded(call: Call) {
        super.onCallAdded(call)
        val callback = object : Call.Callback() {
            override fun onStateChanged(call: Call, state: Int) {
                super.onStateChanged(call, state)
                NovaCallControlBridge.updateCurrentCall(call)
                publishCallState(call)
            }

            override fun onDetailsChanged(call: Call, details: Call.Details) {
                super.onDetailsChanged(call, details)
                publishCallState(call)
            }
        }

        callbacks[call] = callback
        call.registerCallback(callback)
        NovaCallControlBridge.updateCurrentCall(call)
        publishCallState(call)
        @Suppress("DEPRECATION")
        NovaCallControlBridge.updateAudioState(callAudioState)
    }

    override fun onCallRemoved(call: Call) {
        callbacks.remove(call)?.let { callback ->
            try { call.unregisterCallback(callback) } catch (_: Throwable) {}
        }
        NovaCallRinger.stop(this)
        NovaCallControlBridge.updateCurrentCall(null)
        NovaCallStateBridge.updateCall(number = null, state = Call.STATE_DISCONNECTED, callerName = null)
        NovaCallStateBridge.updateAuthorizedNumber(false)
        NovaAuthorizedCallNotifier.dismiss(this)
        super.onCallRemoved(call)
    }

    @Deprecated("Deprecated in API 34; kept as compatibility fallback.")
    override fun onCallAudioStateChanged(audioState: CallAudioState?) {
        super.onCallAudioStateChanged(audioState)
        NovaCallControlBridge.updateAudioState(audioState)
    }

    override fun onMuteStateChanged(isMuted: Boolean) {
        super.onMuteStateChanged(isMuted)
        NovaCallControlBridge.updateMuteState(isMuted)
    }

    override fun onCallEndpointChanged(callEndpoint: CallEndpoint) {
        super.onCallEndpointChanged(callEndpoint)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            latestCallEndpoint = callEndpoint
            NovaCallControlBridge.updateEndpointState(latestCallEndpoint, latestAvailableEndpoints)
        }
    }

    override fun onAvailableCallEndpointsChanged(availableEndpoints: MutableList<CallEndpoint>) {
        super.onAvailableCallEndpointsChanged(availableEndpoints)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            latestAvailableEndpoints = availableEndpoints.toList()
            NovaCallControlBridge.updateEndpointState(latestCallEndpoint, latestAvailableEndpoints)
        }
    }

    private fun launchCallSurfaceOnce(call: Call, ringing: Boolean) {
        val rawNumber = call.details.handle?.schemeSpecificPart.orEmpty()
        val key = "${rawNumber}:${call.state}:${if (ringing) "banner" else "full"}"
        val now = System.currentTimeMillis()
        if (key == lastUiLaunchKey && now - lastUiLaunchAt < 1400L) {
            return
        }
        lastUiLaunchKey = key
        lastUiLaunchAt = now
        if (ringing) {
            runCatching { NovaIncomingCallBannerActivity.launch(this) }
        } else {
            runCatching { NovaCallUiActivity.launch(this) }
        }
    }

    private fun publishCallState(call: Call) {
        val rawNumber = call.details.handle?.schemeSpecificPart
        val telecomName = call.details.callerDisplayName?.toString()?.trim().orEmpty()
        val fallbackLabel = NovaCallContactResolver.resolveDisplayName(
            context = this,
            rawNumber = rawNumber,
            telecomDisplayName = telecomName
        ).ifBlank { rawNumber ?: "Çağrı" }
        val authorized = NovaAuthorizedCallRegistry.isAuthorizedCallHandlingNumber(this, rawNumber)

        NovaCallStateBridge.updateCall(
            number = rawNumber,
            state = call.state,
            callerName = fallbackLabel
        )
        NovaCallStateBridge.updateAuthorizedNumber(authorized)

        when (call.state) {
            Call.STATE_RINGING -> {
                NovaCallRinger.start(this, rawNumber)
                NovaAuthorizedCallNotifier.showIncomingRinging(
                    context = this,
                    callerLabel = fallbackLabel,
                    authorized = authorized
                )
                launchCallSurfaceOnce(call, ringing = true)
            }
            Call.STATE_ACTIVE,
            Call.STATE_CONNECTING,
            Call.STATE_DIALING,
            Call.STATE_HOLDING -> {
                NovaCallRinger.stop(this)
                NovaAuthorizedCallNotifier.showActiveCall(
                    context = this,
                    callerLabel = fallbackLabel,
                    authorized = authorized,
                    isMuted = (NovaCallStateBridge.getState()["isMuted"] as? Boolean) == true,
                    isSpeakerOn = (NovaCallStateBridge.getState()["isSpeakerOn"] as? Boolean) == true,
                    isHolding = call.state == Call.STATE_HOLDING
                )
                launchCallSurfaceOnce(call, ringing = false)
            }
            else -> {
                NovaCallRinger.stop(this)
                NovaAuthorizedCallNotifier.dismiss(this)
            }
        }
    }
}
