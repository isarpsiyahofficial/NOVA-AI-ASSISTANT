package com.example.nova

import android.telecom.Call
import android.telecom.CallScreeningService

class NovaCallScreeningService : CallScreeningService() {

    override fun onScreenCall(callDetails: Call.Details) {
        val rawNumber = callDetails.handle?.schemeSpecificPart
        val normalized = NovaAuthorizedCallRegistry.normalize(rawNumber)
        val callerLabel = NovaCallContactResolver.resolveDisplayName(
            context = this,
            rawNumber = rawNumber,
            telecomDisplayName = callDetails.callerDisplayName?.toString(),
        )
        val authorized = NovaAuthorizedCallRegistry.isAuthorizedCallHandlingNumber(this, normalized)

        NovaCallStateBridge.updateScreeningObservation(
            number = normalized,
            isRinging = true,
            authorizedNumber = authorized,
            screeningAvailable = true,
            callerName = callerLabel,
        )

        NovaCallStateObserver.refreshDefaultDialerState(applicationContext)
        NovaAuthorizedCallNotifier.showIncomingRinging(
            context = this,
            callerLabel = callerLabel.ifBlank { normalized.ifBlank { "Gelen çağrı" } },
            authorized = authorized,
        )

        respondToCall(
            callDetails,
            CallResponse.Builder()
                .setDisallowCall(false)
                .setRejectCall(false)
                .setSilenceCall(false)
                .setSkipNotification(false)
                .setSkipCallLog(false)
                .build(),
        )
    }
}
