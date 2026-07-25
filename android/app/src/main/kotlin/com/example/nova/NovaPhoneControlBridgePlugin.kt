package com.example.nova

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaPhoneControlBridgePlugin(
    private val context: Context,
) : MethodChannel.MethodCallHandler {

    init {
        NovaPhoneControlBridge.initialize(context)
    }

    companion object {
        private const val CHANNEL = "nova/phone_control_bridge"

        fun register(flutterEngine: FlutterEngine, context: Context) {
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL,
            ).setMethodCallHandler(NovaPhoneControlBridgePlugin(context.applicationContext))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getBridgeStatus" -> result.success(NovaPhoneControlBridge.getBridgeStatus())
                "executeStep" -> {
                    val command = call.argument<String>("command").orEmpty().trim()
                    val value = call.argument<String>("value").orEmpty()
                    val waitMs = call.argument<Int>("waitMs") ?: 0

                    // place_call already consumed its owner token while creating
                    // the number-bound carrier approval in CallControlBridge.
                    val requiresDirectAuthority = command != "place_call"
                    if (requiresDirectAuthority) {
                        val auth = NovaNativeActionAuthorization.authorize(
                            context = context,
                            actionToken = call.argument<String>("actionToken").orEmpty(),
                            localUiAction = call.argument<Boolean>("localUiAction") == true,
                            companionAction = call.argument<Boolean>("companionAction") == true,
                        )
                        if (!auth.allowed) {
                            result.success(
                                mapOf(
                                    "success" to false,
                                    "verified" to false,
                                    "failureCode" to auth.mode,
                                    "message" to auth.message,
                                )
                            )
                            return
                        }
                    }

                    result.success(
                        NovaPhoneControlBridge.executeStep(
                            command = command,
                            value = value,
                            waitMs = waitMs,
                        )
                    )
                }
                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.success(
                mapOf(
                    "success" to false,
                    "verified" to false,
                    "message" to "Phone control bridge hatası: ${t.message ?: "unknown"}",
                )
            )
        }
    }
}
