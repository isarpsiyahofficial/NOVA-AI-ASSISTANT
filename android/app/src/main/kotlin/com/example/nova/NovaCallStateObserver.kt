package com.example.nova

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat
import java.util.concurrent.Executor
import java.util.concurrent.Executors

object NovaCallStateObserver {
    @Volatile private var started = false
    private var telephonyManager: TelephonyManager? = null
    private var listener: PhoneStateListener? = null
    private var callback: TelephonyCallback? = null
    private val callbackExecutor: Executor = Executors.newSingleThreadExecutor()

    fun start(context: Context) {
        if (started) return
        val appContext = context.applicationContext
        if (!hasReadPhoneStatePermission(appContext)) {
            NovaCallStateBridge.updateTelephonyObservation(
                number = null,
                stateLabel = "idle",
                isRinging = false,
                isActiveCall = false,
                authorizedNumber = false,
                observerAvailable = false,
            )
            refreshDefaultDialerState(appContext)
            return
        }
        val manager = appContext.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager ?: return
        telephonyManager = manager

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val stateCallback = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                    override fun onCallStateChanged(state: Int) {
                        publishTelephonyState(appContext, state, null)
                    }
                }
                callback = stateCallback
                manager.registerTelephonyCallback(callbackExecutor, stateCallback)
            } else {
                val phoneStateListener = object : PhoneStateListener() {
                    override fun onCallStateChanged(state: Int, incomingNumber: String?) {
                        super.onCallStateChanged(state, incomingNumber)
                        publishTelephonyState(appContext, state, incomingNumber)
                    }
                }
                listener = phoneStateListener
                manager.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
            }
            started = true
        } catch (_: Throwable) {
            started = false
        }
        refreshDefaultDialerState(appContext)
    }

    private fun publishTelephonyState(
        context: Context,
        state: Int,
        incomingNumber: String?,
    ) {
        val normalized = NovaAuthorizedCallRegistry.normalize(incomingNumber)
        val authorized = NovaAuthorizedCallRegistry.isAuthorizedCallHandlingNumber(context, normalized)
        val label = when (state) {
            TelephonyManager.CALL_STATE_RINGING -> "ringing"
            TelephonyManager.CALL_STATE_OFFHOOK -> "active"
            else -> "idle"
        }
        NovaCallStateBridge.updateTelephonyObservation(
            number = normalized,
            stateLabel = label,
            isRinging = state == TelephonyManager.CALL_STATE_RINGING,
            isActiveCall = state == TelephonyManager.CALL_STATE_OFFHOOK,
            authorizedNumber = authorized,
            observerAvailable = true,
        )
    }

    fun stop() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                callback?.let { telephonyManager?.unregisterTelephonyCallback(it) }
            } else {
                telephonyManager?.listen(listener, PhoneStateListener.LISTEN_NONE)
            }
        } catch (_: Throwable) {}
        callback = null
        listener = null
        telephonyManager = null
        started = false
    }

    fun refreshDefaultDialerState(context: Context) {
        NovaCallStateBridge.updateDefaultDialerState(NovaCallControlBridge.isDefaultDialer(context))
    }

    fun hasReadPhoneStatePermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(context, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
    }
}
