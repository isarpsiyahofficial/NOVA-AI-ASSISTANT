package com.example.nova

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaPhoneControlBridgePlugin(
    private val context: Context
) : MethodChannel.MethodCallHandler {

    init {
        NovaPhoneControlBridge.initialize(context)
    }

    companion object {
        private const val CHANNEL = "nova/phone_control_bridge"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context
        ) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            channel.setMethodCallHandler(
                NovaPhoneControlBridgePlugin(context)
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getBridgeStatus" -> {
                    result.success(
                        NovaPhoneControlBridge.getBridgeStatus()
                    )
                }

                "executeStep" -> {
                    val command = call.argument<String>("command").orEmpty()
                    val value = call.argument<String>("value").orEmpty()
                    val waitMs = call.argument<Int>("waitMs") ?: 0
                    val userInitiated = call.argument<Boolean>("userInitiated") == true
                    if (userInitiated && command.trim() == "place_call") {
                        // Dart/AI tarafında userInitiated dış arama için token üretmez.
                        // Dış arama yalnız native DialerActivity manual token veya owner approval token ile geçer.
                        NovaCallAuthorityGuard.registerUserCallAction("dial")
                    }
                    val trustedSource = call.argument<String>("trustedSource").orEmpty().trim()
                    if (userInitiated && command.trim() == "speaker_on") {
                        NovaCallAuthorityGuard.registerUserCallAction("speaker")
                    }
                    if (userInitiated && command.trim() == "speaker_off") {
                        NovaCallAuthorityGuard.registerUserCallAction("speaker")
                    }
                    if (trustedSource == "companion" && (command.trim() == "speaker_on" || command.trim() == "speaker_off")) {
                        NovaCallAuthorityGuard.registerTrustedCallAction("speaker", "companion")
                    }

                    result.success(
                        NovaPhoneControlBridge.executeStep(
                            command = command,
                            value = value,
                            waitMs = waitMs
                        )
                    )
                }

                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.success(
                mapOf(
                    "success" to false,
                    "message" to "Phone control bridge hatası: ${t.message ?: "unknown"}"
                )
            )
        }
    }
}
