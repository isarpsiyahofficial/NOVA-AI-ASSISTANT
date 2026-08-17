package com.example.nova.testing

import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.telecom.PhoneAccount
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.util.Log
import com.example.nova.NovaCallAuthorityGuard
import com.example.nova.NovaCallControlBridge
import com.example.nova.NovaCallStateBridge
import com.example.nova.NovaCallStateObserver
import com.example.nova.NovaCompanionConnectionService
import org.json.JSONObject

/**
 * Debug-build-only test receiver. It is never packaged in release builds.
 * GitHub's Android emulator uses it to register an isolated Telecom
 * PhoneAccount, inject a real managed incoming call, and exercise the exact
 * Nova InCallService and native call-control bridge.
 */
class NovaDebugControlReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val appContext = context.applicationContext
        NovaCallControlBridge.initialize(appContext)
        NovaCallStateObserver.start(appContext)
        val command = intent.getStringExtra("command").orEmpty().trim().lowercase()
        val result = when (command) {
            "register_test_account" -> registerTestAccount(appContext)
            "inject_incoming_call" -> injectIncomingCall(
                context = appContext,
                number = intent.getStringExtra("number").orEmpty().ifBlank { TEST_NUMBER },
            )
            "unregister_test_account" -> unregisterTestAccount(appContext)
            "answer" -> {
                NovaCallAuthorityGuard.registerUserCallAction("answer")
                NovaCallControlBridge.answerRingingCall()
            }
            "reject" -> {
                NovaCallAuthorityGuard.registerUserCallAction("reject")
                NovaCallControlBridge.rejectRingingCall()
            }
            "hangup" -> {
                NovaCallAuthorityGuard.registerUserCallAction("hangup")
                NovaCallControlBridge.disconnectCurrentCall()
            }
            "mute_on" -> {
                NovaCallAuthorityGuard.registerUserCallAction("mute")
                NovaCallControlBridge.setMuted(true)
            }
            "mute_off" -> {
                NovaCallAuthorityGuard.registerUserCallAction("mute")
                NovaCallControlBridge.setMuted(false)
            }
            "speaker_on" -> {
                NovaCallAuthorityGuard.registerUserCallAction("speaker")
                NovaCallControlBridge.routeToSpeaker(true)
            }
            "speaker_off" -> {
                NovaCallAuthorityGuard.registerUserCallAction("speaker")
                NovaCallControlBridge.routeToSpeaker(false)
            }
            "state" -> NovaCallStateBridge.getState() +
                NovaCallControlBridge.getCapabilities() +
                mapOf(
                    "success" to true,
                    "message" to "Debug Telecom state captured.",
                )
            else -> mapOf(
                "success" to false,
                "message" to "Unsupported debug command: $command",
            )
        }

        val json = JSONObject(result).toString()
        context.getSharedPreferences("nova_debug_control", Context.MODE_PRIVATE)
            .edit()
            .putString("last_command", command)
            .putString("last_result", json)
            .putLong("updated_at", System.currentTimeMillis())
            .apply()
        Log.i("NOVA_DEBUG_CONTROL", "command=$command result=$json")
        setResultCode(if (result["success"] == true) 0 else 1)
        setResultData(json)
    }

    private fun registerTestAccount(context: Context): Map<String, Any> {
        val telecom = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            ?: return failure("TelecomManager alınamadı.")
        return try {
            val handle = testAccountHandle(context)
            val account = PhoneAccount.builder(handle, "NOVA Telecom E2E")
                .setCapabilities(PhoneAccount.CAPABILITY_CALL_PROVIDER)
                .setSupportedUriSchemes(listOf(PhoneAccount.SCHEME_TEL))
                .build()
            telecom.registerPhoneAccount(account)
            val registered = telecom.getPhoneAccount(handle) != null
            mapOf(
                "success" to registered,
                "message" to if (registered) "Test PhoneAccount kaydedildi." else "Test PhoneAccount kaydedilemedi.",
                "component" to handle.componentName.flattenToString(),
                "accountId" to handle.id,
            )
        } catch (error: Throwable) {
            failure("Test PhoneAccount kaydedilemedi: ${error.message ?: error.javaClass.simpleName}")
        }
    }

    private fun injectIncomingCall(context: Context, number: String): Map<String, Any> {
        val telecom = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            ?: return failure("TelecomManager alınamadı.")
        val cleanNumber = number.trim()
        if (cleanNumber.isEmpty()) return failure("Test çağrı numarası boş.")
        return try {
            val handle = testAccountHandle(context)
            if (telecom.getPhoneAccount(handle) == null) {
                return failure("Test PhoneAccount kayıtlı değil.")
            }
            val incomingPermitted = telecom.isIncomingCallPermitted(handle)
            if (!incomingPermitted) {
                return failure("Telecom bu PhoneAccount için gelen çağrıya izin vermedi.")
            }
            val extras = Bundle().apply {
                putParcelable(
                    TelecomManager.EXTRA_INCOMING_CALL_ADDRESS,
                    Uri.fromParts(PhoneAccount.SCHEME_TEL, cleanNumber, null),
                )
            }
            telecom.addNewIncomingCall(handle, extras)
            mapOf(
                "success" to true,
                "message" to "Gerçek Telecom gelen çağrısı istendi.",
                "number" to cleanNumber,
                "component" to handle.componentName.flattenToString(),
                "accountId" to handle.id,
                "incomingCallPermitted" to incomingPermitted,
            )
        } catch (error: Throwable) {
            failure("Telecom gelen çağrısı oluşturulamadı: ${error.message ?: error.javaClass.simpleName}")
        }
    }

    private fun unregisterTestAccount(context: Context): Map<String, Any> {
        val telecom = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            ?: return failure("TelecomManager alınamadı.")
        return try {
            telecom.unregisterPhoneAccount(testAccountHandle(context))
            mapOf("success" to true, "message" to "Test PhoneAccount kaldırıldı.")
        } catch (error: Throwable) {
            failure("Test PhoneAccount kaldırılamadı: ${error.message ?: error.javaClass.simpleName}")
        }
    }

    private fun testAccountHandle(context: Context): PhoneAccountHandle = PhoneAccountHandle(
        ComponentName(context, NovaCompanionConnectionService::class.java),
        TEST_ACCOUNT_ID,
    )

    private fun failure(message: String): Map<String, Any> = mapOf(
        "success" to false,
        "message" to message,
    )

    private companion object {
        const val TEST_ACCOUNT_ID = "nova_telecom_e2e"
        const val TEST_NUMBER = "5551234"
    }
}
