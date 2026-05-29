package com.example.nova

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.telecom.TelecomManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaCallStateBridgePlugin(
    private val context: Context
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "nova/call_state"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context,
        ) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            NovaCallStateObserver.start(context)
            channel.setMethodCallHandler(
                NovaCallStateBridgePlugin(context)
            )
        }
    }

    @Suppress("UNUSED_PARAMETER")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCallState" -> {
                NovaCallStateObserver.refreshDefaultDialerState(context)
                result.success(NovaCallStateBridge.getState())
            }

            "requestDefaultDialerRole" -> {
                result.success(requestDefaultDialerRole())
            }

            "openDefaultPhoneSettings" -> {
                result.success(openDefaultPhoneSettings())
            }

            else -> result.notImplemented()
        }
    }

    private fun requestDefaultDialerRole(): Map<String, Any> {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = context.getSystemService(RoleManager::class.java)
                if (roleManager == null || !roleManager.isRoleAvailable(RoleManager.ROLE_DIALER)) {
                    return mapOf(
                        "success" to false,
                        "message" to "Bu cihazda varsayılan telefon rolü kullanılamıyor.",
                    )
                }
                if (roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
                    NovaCallStateBridge.updateDefaultDialerState(true)
                    return mapOf(
                        "success" to true,
                        "message" to "Nova zaten varsayılan telefon uygulaması.",
                    )
                }
                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                mapOf(
                    "success" to true,
                    "message" to "Varsayılan telefon rolü isteği açıldı.",
                )
            } else {
                val intent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                    putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, context.packageName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                mapOf(
                    "success" to true,
                    "message" to "Varsayılan telefon değişikliği isteği açıldı.",
                )
            }
        } catch (t: Throwable) {
            mapOf(
                "success" to false,
                "message" to (t.message ?: "Varsayılan telefon rolü isteği açılamadı."),
            )
        }
    }

    private fun openDefaultPhoneSettings(): Map<String, Any> {
        return try {
            val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            mapOf(
                "success" to true,
                "message" to "Varsayılan uygulamalar ayarı açıldı.",
            )
        } catch (t: Throwable) {
            mapOf(
                "success" to false,
                "message" to (t.message ?: "Varsayılan uygulamalar ayarı açılamadı."),
            )
        }
    }
}
