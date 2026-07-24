package com.example.nova

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaCallControlBridgePlugin(
    @Suppress("UNUSED_PARAMETER")
    private val context: Context
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "nova/call_control"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context
        ) {
            val appContext = context.applicationContext
            NovaCallControlBridge.initialize(appContext)
            NovaCallStateObserver.start(appContext)
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            channel.setMethodCallHandler(
                NovaCallControlBridgePlugin(appContext)
            )
        }
    }

    private fun markUserInitiatedIfPresent(call: MethodCall, action: String) {
        val userInitiated = call.argument<Boolean>("userInitiated") == true
        if (userInitiated) {
            NovaCallAuthorityGuard.registerUserCallAction(action)
        }
    }

    private fun markTrustedSourceIfPresent(call: MethodCall, action: String) {
        val source = call.argument<String>("trustedSource").orEmpty().trim()
        if (source == "companion") {
            NovaCallAuthorityGuard.registerTrustedCallAction(action, source)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "answerRingingCall" -> {
                    markUserInitiatedIfPresent(call, "answer")
                    markTrustedSourceIfPresent(call, "answer")
                    result.success(NovaCallControlBridge.answerRingingCall())
                }

                "rejectRingingCall" -> {
                    markUserInitiatedIfPresent(call, "reject")
                    markTrustedSourceIfPresent(call, "reject")
                    result.success(NovaCallControlBridge.rejectRingingCall())
                }

                "disconnectCurrentCall" -> {
                    markUserInitiatedIfPresent(call, "hangup")
                    markTrustedSourceIfPresent(call, "hangup")
                    result.success(NovaCallControlBridge.disconnectCurrentCall())
                }

                "setMuted" -> {
                    markUserInitiatedIfPresent(call, "mute")
                    markTrustedSourceIfPresent(call, "mute")
                    val muted = call.argument<Boolean>("muted") ?: false
                    result.success(NovaCallControlBridge.setMuted(muted))
                }

                "routeToSpeaker" -> {
                    markUserInitiatedIfPresent(call, "speaker")
                    markTrustedSourceIfPresent(call, "speaker")
                    val speakerOn = call.argument<Boolean>("speakerOn") ?: false
                    result.success(NovaCallControlBridge.routeToSpeaker(speakerOn))
                }

                "toggleMuted" -> {
                    markUserInitiatedIfPresent(call, "mute")
                    markTrustedSourceIfPresent(call, "mute")
                    result.success(NovaCallControlBridge.toggleMuted())
                }

                "toggleSpeaker" -> {
                    markUserInitiatedIfPresent(call, "speaker")
                    markTrustedSourceIfPresent(call, "speaker")
                    result.success(NovaCallControlBridge.toggleSpeaker())
                }

                "toggleHold" -> {
                    markUserInitiatedIfPresent(call, "hold")
                    markTrustedSourceIfPresent(call, "hold")
                    result.success(NovaCallControlBridge.toggleHold())
                }

                "showInCallScreen" -> {
                    result.success(NovaCallControlBridge.showInCallScreen())
                }

                "handOverToNova" -> {
                    // A public Android dialer/InCallService can answer and control a
                    // carrier call, but this APK currently has no verified carrier
                    // downlink capture + uplink TTS injection transport. Speakerphone
                    // plus mute is not an AI conversation transport and must never be
                    // reported as a successful digital-human handover.
                    result.success(
                        mapOf(
                            "success" to false,
                            "verified" to false,
                            "failureCode" to "carrier_ai_audio_transport_unavailable",
                            "message" to "Çağrı kontrolü kullanılabilir; ancak karşı taraf sesini STT'ye taşıyan ve Nova sesini operatör hattına veren doğrulanmış çağrı ses taşıması bu APK'da hazır değil.",
                            "carrierCallControlReady" to true,
                            "carrierAiConversationReady" to false,
                            "carrierDownlinkCaptureReady" to false,
                            "carrierUplinkInjectionReady" to false
                        )
                    )
                }

                "handOverToUser" -> {
                    markUserInitiatedIfPresent(call, "return_to_user")
                    markTrustedSourceIfPresent(call, "return_to_user")
                    result.success(NovaCallControlBridge.handOverToUser())
                }

                "registerOwnerApprovedOutbound" -> {
                    val number = call.argument<String>("number").orEmpty()
                    val userInitiated = call.argument<Boolean>("userInitiated") == true
                    if (!userInitiated) {
                        result.success(mapOf("success" to false, "message" to "Owner outbound approval userInitiated olmadan üretilemez."))
                    } else {
                        val decision = NovaCarrierBoundaryGuard.registerOwnerApprovedOutbound(number)
                        result.success(decision.toMap() + mapOf("success" to decision.allowed, "message" to decision.reason))
                    }
                }

                "getCapabilities" -> {
                    val base = NovaCallControlBridge.getCapabilities().toMutableMap()
                    base["carrierCallControlReady"] = true
                    base["carrierAiConversationReady"] = false
                    base["carrierDownlinkCaptureReady"] = false
                    base["carrierUplinkInjectionReady"] = false
                    base["aiConversationTransport"] = "none_public_android_carrier_audio"
                    result.success(base)
                }

                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.success(
                mapOf(
                    "success" to false,
                    "message" to "Call control bridge hatası: ${t.message ?: "unknown"}",
                    "isMuted" to false,
                    "isSpeakerOn" to false,
                    "carrierAiConversationReady" to false
                )
            )
        }
    }
}
