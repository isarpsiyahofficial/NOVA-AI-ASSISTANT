package com.example.nova.testing

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.nova.NovaCallAuthorityGuard
import com.example.nova.NovaCallControlBridge
import com.example.nova.NovaCallStateBridge
import com.example.nova.NovaCallStateObserver
import org.json.JSONObject

/**
 * Debug-build-only test receiver. It is never packaged in release builds.
 * GitHub's Android emulator uses it to exercise the exact native call bridge
 * after creating a real emulator GSM call through `adb emu gsm call`.
 */
class NovaDebugControlReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        NovaCallControlBridge.initialize(context.applicationContext)
        NovaCallStateObserver.start(context.applicationContext)
        val command = intent.getStringExtra("command").orEmpty().trim().lowercase()
        val result = when (command) {
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
            "state" -> NovaCallStateBridge.getState() + mapOf(
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
}
