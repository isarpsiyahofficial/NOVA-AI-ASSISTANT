package com.example.nova

import android.net.Uri
import android.telecom.Connection
import android.telecom.ConnectionRequest
import android.telecom.ConnectionService
import android.telecom.DisconnectCause
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager

class NovaCompanionConnectionService : ConnectionService() {

    override fun onCreateIncomingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ): Connection {
        return NovaManagedConnection(
            address = request?.address,
            incoming = true,
        ).apply {
            setRinging()
            NovaCallStateBridge.updateCall(
                number = request?.address?.schemeSpecificPart,
                state = android.telecom.Call.STATE_RINGING,
                callerName = request?.address?.schemeSpecificPart,
            )
        }
    }

    override fun onCreateOutgoingConnection(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ): Connection {
        return NovaManagedConnection(
            address = request?.address,
            incoming = false,
        ).apply {
            setDialing()
            NovaCallStateBridge.updateCall(
                number = request?.address?.schemeSpecificPart,
                state = android.telecom.Call.STATE_DIALING,
                callerName = request?.address?.schemeSpecificPart,
            )
        }
    }

    override fun onCreateIncomingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ) {
        NovaCallStateBridge.updateCall(
            number = request?.address?.schemeSpecificPart,
            state = android.telecom.Call.STATE_DISCONNECTED,
            callerName = request?.address?.schemeSpecificPart,
        )
        super.onCreateIncomingConnectionFailed(connectionManagerPhoneAccount, request)
    }

    override fun onCreateOutgoingConnectionFailed(
        connectionManagerPhoneAccount: PhoneAccountHandle?,
        request: ConnectionRequest?,
    ) {
        NovaCallStateBridge.updateCall(
            number = request?.address?.schemeSpecificPart,
            state = android.telecom.Call.STATE_DISCONNECTED,
            callerName = request?.address?.schemeSpecificPart,
        )
        super.onCreateOutgoingConnectionFailed(connectionManagerPhoneAccount, request)
    }
}

private class NovaManagedConnection(
    private val address: Uri?,
    private val incoming: Boolean,
) : Connection() {

    init {
        setAddress(address, TelecomManager.PRESENTATION_ALLOWED)
        setAudioModeIsVoip(true)
        setCallerDisplayName(address?.schemeSpecificPart ?: "Nova companion", TelecomManager.PRESENTATION_ALLOWED)
    }

    override fun onAnswer() {
        super.onAnswer()
        setActive()
        NovaCallStateBridge.updateCall(
            number = address?.schemeSpecificPart,
            state = android.telecom.Call.STATE_ACTIVE,
            callerName = address?.schemeSpecificPart,
        )
    }

    override fun onReject() {
        super.onReject()
        setDisconnected(DisconnectCause(DisconnectCause.REJECTED))
        destroy()
        NovaCallStateBridge.updateCall(
            number = address?.schemeSpecificPart,
            state = android.telecom.Call.STATE_DISCONNECTED,
            callerName = address?.schemeSpecificPart,
        )
    }

    override fun onDisconnect() {
        super.onDisconnect()
        setDisconnected(DisconnectCause(DisconnectCause.LOCAL))
        destroy()
        NovaCallStateBridge.updateCall(
            number = address?.schemeSpecificPart,
            state = android.telecom.Call.STATE_DISCONNECTED,
            callerName = address?.schemeSpecificPart,
        )
    }

    override fun onHold() {
        super.onHold()
        setOnHold()
        NovaCallStateBridge.updateCall(
            number = address?.schemeSpecificPart,
            state = android.telecom.Call.STATE_HOLDING,
            callerName = address?.schemeSpecificPart,
        )
    }

    override fun onUnhold() {
        super.onUnhold()
        setActive()
        NovaCallStateBridge.updateCall(
            number = address?.schemeSpecificPart,
            state = android.telecom.Call.STATE_ACTIVE,
            callerName = address?.schemeSpecificPart,
        )
    }
}
