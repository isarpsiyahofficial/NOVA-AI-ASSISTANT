package com.example.nova

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.example.nova.asr.NovaStreamingAsrEngineProvider
import java.util.concurrent.atomic.AtomicBoolean

class NovaNativeAudioBridgePlugin(
    private val context: Context,
    private val activity: Activity?
) : MethodChannel.MethodCallHandler {

    private val micHelper = NovaMicAudioCaptureHelper(context)
    private val internalAudioHelper = NovaInternalAudioCaptureHelper(context)
    private val cloneAdapter = NovaCloneEngineAdapter(context)
    private val streamingAsrEngine by lazy { NovaStreamingAsrEngineProvider.get(context) }

    companion object {
        private const val CHANNEL = "nova/native_audio_bridge"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context,
            activity: Activity?
        ) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            channel.setMethodCallHandler(
                NovaNativeAudioBridgePlugin(context, activity)
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "decodeStreamingSnapshot" -> {
                val mode = call.argument<String>("mode").orEmpty()
                    .ifBlank { "normalCommandListening" }
                val maxDurationSeconds = call.argument<Int>("maxDurationSeconds") ?: 8
                val completed = AtomicBoolean(false)

                fun finish(payload: Map<String, Any?>) {
                    if (!completed.compareAndSet(false, true)) return
                    result.success(payload)
                }

                fun fallbackToPlatformRecognizer(reason: String) {
                    NovaSpeechRecognizerHelper(context).transcribeTurkishOnce(
                        mode = mode,
                        maxDurationSeconds = maxDurationSeconds.coerceIn(8, 60),
                        callback = object : NovaSpeechRecognizerHelper.Callback {
                            override fun onResult(success: Boolean, text: String, locale: String, message: String) {
                                finish(
                                    mapOf(
                                        "success" to success,
                                        "recognizedText" to text,
                                        "detectedLocale" to locale,
                                        "message" to if (success) {
                                            "Platform SpeechRecognizer fallback kullanıldı. Önceki ASR durumu: $reason"
                                        } else {
                                            "Embedded ASR ve platform fallback tamamlanamadı. Embedded: $reason | Platform: $message"
                                        },
                                        "usedEmbeddedAsr" to false,
                                        "usedPlatformSpeechRecognizerFallback" to true,
                                        "audioInputPolicy" to NovaAudioInputPolicy.getState(context),
                                        "streamingAsrState" to streamingAsrEngine.stateMap(),
                                    )
                                )
                            }
                        }
                    )
                }

                val embeddedReady = try {
                    streamingAsrEngine.initialize()
                } catch (t: Throwable) {
                    false
                }

                if (!embeddedReady) {
                    fallbackToPlatformRecognizer("Embedded Sherpa ASR hazır değil")
                    return@setMethodCallHandler
                }

                try {
                    streamingAsrEngine.decodeStreamingSnapshot(
                        mode = mode,
                        maxDurationSeconds = maxDurationSeconds,
                    ) { success, text, locale, message, usedEmbedded ->
                        if (success && text.trim().length >= 2) {
                            finish(
                                mapOf(
                                    "success" to true,
                                    "recognizedText" to text,
                                    "detectedLocale" to locale,
                                    "message" to message,
                                    "usedEmbeddedAsr" to usedEmbedded,
                                    "usedPlatformSpeechRecognizerFallback" to false,
                                    "audioInputPolicy" to NovaAudioInputPolicy.getState(context),
                                    "streamingAsrState" to streamingAsrEngine.stateMap(),
                                )
                            )
                        } else {
                            fallbackToPlatformRecognizer(message.ifBlank { "Embedded ASR boş sonuç döndürdü" })
                        }
                    }
                } catch (t: Throwable) {
                    fallbackToPlatformRecognizer(t.message ?: "Embedded ASR çağrısı hata verdi")
                }
            }

            "beginPassiveListening" -> {
                result.success(NovaAudioInputPolicy.beginPassiveListening(context))
            }

            "endPassiveListening" -> {
                result.success(NovaAudioInputPolicy.endPassiveListening(context))
            }

            "beginCallCompanionListening" -> {
                result.success(NovaAudioInputPolicy.beginCallCompanionListening(context))
            }

            "endCallCompanionListening" -> {
                result.success(NovaAudioInputPolicy.endCallCompanionListening(context))
            }

            "endListeningSession" -> {
                result.success(NovaAudioInputPolicy.endListeningSession(context))
            }

            "getAudioInputPolicyState" -> {
                result.success(NovaAudioInputPolicy.getState(context))
            }


            "ensureStreamingAsrReady" -> {
                val success = streamingAsrEngine.initialize()
                result.success(
                    mapOf(
                        "success" to success,
                        "message" to if (success) "Streaming ASR yürütücü hazır." else "Streaming ASR yürütücüsü hazırlanamadı.",
                        "streamingAsrState" to streamingAsrEngine.stateMap(),
                    )
                )
            }

            "getStreamingAsrExecutiveState" -> {
                result.success(
                    mapOf(
                        "success" to true,
                        "message" to "OK",
                        "streamingAsrState" to streamingAsrEngine.stateMap(),
                    )
                )
            }

            "prewarmContinuousListeningSession" -> {
                val holdForMs = (call.argument<Int>("holdForMs") ?: 120000).toLong()
                val success = streamingAsrEngine.initialize()
                val state = streamingAsrEngine.stateMap()
                result.success(
                    mapOf(
                        "success" to success,
                        "message" to if (success) "Sürekli dinleme için embedded streaming ASR hazırlandı." else "Embedded streaming ASR hazır değil.",
                        "holdForMs" to holdForMs,
                        "session" to mapOf(
                            "hasRecognizer" to (state["embeddedSherpaReady"] as? Boolean ?: false),
                            "activeClientCount" to if (state["running"] as? Boolean == true) 1 else 0,
                            "keepWarmActive" to success,
                            "engineMode" to (state["lastMode"] ?: "idle"),
                            "engineReady" to (state["embeddedSherpaReady"] as? Boolean ?: false),
                        ),
                        "streamingAsrState" to state,
                    )
                )
            }

            "releaseContinuousListeningSession" -> {
                streamingAsrEngine.stop()
                result.success(
                    mapOf(
                        "success" to true,
                        "message" to "Sürekli dinleme yürütücüsü serbest bırakıldı.",
                        "session" to mapOf(
                            "hasRecognizer" to false,
                            "activeClientCount" to 0,
                            "keepWarmActive" to false,
                            "engineMode" to "stopped",
                            "engineReady" to false,
                        ),
                        "streamingAsrState" to streamingAsrEngine.stateMap(),
                    )
                )
            }

            "getContinuousListeningSessionState" -> {
                val state = streamingAsrEngine.stateMap()
                result.success(
                    mapOf(
                        "success" to true,
                        "message" to "OK",
                        "session" to mapOf(
                            "hasRecognizer" to (state["embeddedSherpaReady"] as? Boolean ?: false),
                            "activeClientCount" to if (state["running"] as? Boolean == true) 1 else 0,
                            "keepWarmActive" to (state["embeddedSherpaReady"] as? Boolean ?: false),
                            "engineMode" to (state["lastMode"] ?: "idle"),
                            "engineReady" to (state["embeddedSherpaReady"] as? Boolean ?: false),
                        ),
                        "streamingAsrState" to state,
                    )
                )
            }

            "startStreamingVoiceGate" -> {
                result.success(NovaStreamingVoiceGate.start(context))
            }

            "stopStreamingVoiceGate" -> {
                result.success(NovaStreamingVoiceGate.stop())
            }

            "getStreamingVoiceGateState" -> {
                result.success(NovaStreamingVoiceGate.stateMap())
            }

            "captureCloneSampleExternal" -> {
                val seconds = call.argument<Int>("maxDurationSeconds") ?: 10
                val outputName =
                    call.argument<String>("outputName") ?: "nova_external_clone"

                micHelper.recordSample(
                    seconds = seconds,
                    outputName = outputName,
                    callback = object : NovaMicAudioCaptureHelper.Callback {
                        override fun onDone(success: Boolean, filePath: String, message: String) {
                            result.success(
                                mapOf(
                                    "success" to success,
                                    "filePath" to filePath,
                                    "message" to message
                                )
                            )
                        }
                    }
                )
            }

            "captureCloneSampleInternal" -> {
                val seconds = call.argument<Int>("maxDurationSeconds") ?: 10
                val outputName =
                    call.argument<String>("outputName") ?: "nova_internal_clone"

                internalAudioHelper.recordInternalAudio(
                    seconds = seconds,
                    outputName = outputName,
                    callback = object : NovaInternalAudioCaptureHelper.Callback {
                        override fun onDone(success: Boolean, filePath: String, message: String) {
                            result.success(
                                mapOf(
                                    "success" to success,
                                    "filePath" to filePath,
                                    "message" to message
                                )
                            )
                        }
                    }
                )
            }

            "createVoiceClone" -> {
                val sourcePath = call.argument<String>("sourceReference").orEmpty()
                val suggestedName = call.argument<String>("suggestedName").orEmpty()
                val styleInstruction = call.argument<String>("styleInstruction").orEmpty()

                result.success(
                    cloneAdapter.createClone(
                        sourcePath = sourcePath,
                        suggestedName = suggestedName.ifBlank { "Klon Ses" },
                        styleInstruction = styleInstruction
                    )
                )
            }

            else -> result.notImplemented()
        }
    }
}