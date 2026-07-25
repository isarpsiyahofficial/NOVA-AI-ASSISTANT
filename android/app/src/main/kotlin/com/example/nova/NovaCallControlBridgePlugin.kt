package com.example.nova

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaCallControlBridgePlugin(
    private val context: Context,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "nova/call_control"

        fun register(flutterEngine: FlutterEngine, context: Context) {
            val appContext = context.applicationContext
            NovaCallControlBridge.initialize(appContext)
            NovaCallStateObserver.start(appContext)
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL,
            ).setMethodCallHandler(NovaCallControlBridgePlugin(appContext))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "answerRingingCall" -> authorized(call, result) {
                    NovaCallControlBridge.answerRingingCall()
                }
                "rejectRingingCall" -> authorized(call, result) {
                    NovaCallControlBridge.rejectRingingCall()
                }
                "disconnectCurrentCall" -> authorized(call, result) {
                    NovaCallControlBridge.disconnectCurrentCall()
                }
                "setMuted" -> authorized(call, result) {
                    NovaCallControlBridge.setMuted(call.argument<Boolean>("muted") ?: false)
                }
                "routeToSpeaker" -> authorized(call, result) {
                    NovaCallControlBridge.routeToSpeaker(call.argument<Boolean>("speakerOn") ?: false)
                }
                "toggleMuted" -> authorized(call, result) {
                    NovaCallControlBridge.toggleMuted()
                }
                "toggleSpeaker" -> authorized(call, result) {
                    NovaCallControlBridge.toggleSpeaker()
                }
                "toggleHold" -> authorized(call, result) {
                    NovaCallControlBridge.toggleHold()
                }
                "showInCallScreen" -> result.success(NovaCallControlBridge.showInCallScreen())
                "handOverToUser" -> authorized(call, result) {
                    NovaCallControlBridge.handOverToUser()
                }
                "handOverToNova" -> result.success(
                    mapOf(
                        "success" to false,
                        "verified" to false,
                        "failureCode" to "use_carrier_media_bridge",
                        "message" to "İki yönlü NOVA görüşmesi Android hoparlör hilesiyle değil, yapılandırılmış carrier/SIP medya köprüsüyle başlatılmalıdır.",
                        "carrierCallControlReady" to true,
                        "carrierAiConversationReady" to false,
                        "aiConversationTransport" to "external_asterisk_audiosocket",
                    )
                )
                "registerOwnerApprovedOutbound" -> {
                    val auth = authorizeDecision(call)
                    if (!auth.allowed) {
                        result.success(denied(auth))
                    } else {
                        val number = call.argument<String>("number").orEmpty()
                        val decision = NovaCarrierBoundaryGuard.registerOwnerApprovedOutbound(number)
                        result.success(
                            decision.toMap() + mapOf(
                                "success" to decision.allowed,
                                "message" to decision.reason,
                                "authorityMode" to auth.mode,
                            )
                        )
                    }
                }
                "getCapabilities" -> {
                    val base = NovaCallControlBridge.getCapabilities().toMutableMap()
                    base["carrierCallControlReady"] = true
                    base["carrierAiConversationReady"] = false
                    base["aiConversationTransport"] = "external_asterisk_audiosocket"
                    result.success(base)
                }
                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.success(
                mapOf(
                    "success" to false,
                    "verified" to false,
                    "message" to "Call control bridge hatası: ${t.message ?: "unknown"}",
                )
            )
        }
    }

    private fun authorized(
        call: MethodCall,
        result: MethodChannel.Result,
        block: () -> Map<String, Any>,
    ) {
        val decision = authorizeDecision(call)
        if (!decision.allowed) {
            result.success(denied(decision))
            return
        }
        result.success(block() + mapOf("authorityMode" to decision.mode))
    }

    private fun authorizeDecision(call: MethodCall): NovaNativeActionAuthorization.Decision {
        return NovaNativeActionAuthorization.authorize(
            context = context,
            actionToken = call.argument<String>("actionToken").orEmpty(),
            localUiAction = call.argument<Boolean>("localUiAction") == true,
            companionAction = call.argument<Boolean>("companionAction") == true,
        )
    }

    private fun denied(decision: NovaNativeActionAuthorization.Decision): Map<String, Any> =
        mapOf(
            "success" to false,
            "verified" to false,
            "failureCode" to decision.mode,
            "message" to decision.message,
        )
}
