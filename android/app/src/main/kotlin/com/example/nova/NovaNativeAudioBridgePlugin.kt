package com.example.nova

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import com.example.nova.asr.NovaStreamingAsrEngineProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

class NovaNativeAudioBridgePlugin(
    private val context: Context,
    private val activity: Activity?
) : MethodChannel.MethodCallHandler {

    private val micHelper = NovaMicAudioCaptureHelper(context)
    private val internalAudioHelper = NovaInternalAudioCaptureHelper(context)
    private val cloneAdapter = NovaCloneEngineAdapter(context)
    private val streamingAsrEngine by lazy { NovaStreamingAsrEngineProvider.get(context) }
    private val mainHandler = Handler(Looper.getMainLooper())

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

    private fun succeedOnMain(result: MethodChannel.Result, payload: Any?) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            result.success(payload)
        } else {
            mainHandler.post { result.success(payload) }
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
                    succeedOnMain(result, payload)
                }

                val embeddedReady = try {
                    streamingAsrEngine.initialize()
                } catch (_: Throwable) {
                    false
                }

                if (!embeddedReady) {
                    finish(
                        mapOf(
                            "success" to false,
                            "recognizedText" to "",
                            "detectedLocale" to "tr-TR",
                            "message" to "Embedded Sherpa ASR hazır değil. Platform SpeechRecognizer fallback kullanılmadı.",
                            "usedEmbeddedAsr" to false,
                            "usedPlatformSpeechRecognizerFallback" to false,
                            "audioInputPolicy" to NovaAudioInputPolicy.getState(context),
                            "streamingAsrState" to streamingAsrEngine.stateMap(),
                        )
                    )
                    return
                }

                try {
                    streamingAsrEngine.decodeStreamingSnapshot(
                        mode = mode,
                        maxDurationSeconds = maxDurationSeconds,
                    ) { success, text, locale, message, usedEmbedded ->
                        val cleanText = text.trim()
                        finish(
                            mapOf(
                                "success" to (success && cleanText.length >= 2 && usedEmbedded),
                                "recognizedText" to if (success && usedEmbedded) cleanText else "",
                                "detectedLocale" to locale.ifBlank { "tr-TR" },
                                "message" to if (success && cleanText.length >= 2 && usedEmbedded) {
                                    message.ifBlank { "Embedded Sherpa ASR transcript üretti." }
                                } else {
                                    message.ifBlank { "Embedded Sherpa ASR kullanılabilir transcript üretmedi." }
                                },
                                "usedEmbeddedAsr" to usedEmbedded,
                                "usedPlatformSpeechRecognizerFallback" to false,
                                "audioInputPolicy" to NovaAudioInputPolicy.getState(context),
                                "streamingAsrState" to streamingAsrEngine.stateMap(),
                            )
                        )
                    }
                } catch (t: Throwable) {
                    finish(
                        mapOf(
                            "success" to false,
                            "recognizedText" to "",
                            "detectedLocale" to "tr-TR",
                            "message" to (t.message ?: "Embedded Sherpa ASR çağrısı hata verdi."),
                            "usedEmbeddedAsr" to false,
                            "usedPlatformSpeechRecognizerFallback" to false,
                            "audioInputPolicy" to NovaAudioInputPolicy.getState(context),
                            "streamingAsrState" to streamingAsrEngine.stateMap(),
                        )
                    )
                }
            }

            "beginPassiveListening" -> succeedOnMain(
                result,
                NovaAudioInputPolicy.beginPassiveListening(context)
            )

            "endPassiveListening" -> succeedOnMain(
                result,
                NovaAudioInputPolicy.endPassiveListening(context)
            )

            "beginCallCompanionListening" -> succeedOnMain(
                result,
                NovaAudioInputPolicy.beginCallCompanionListening(context)
            )

            "endCallCompanionListening" -> succeedOnMain(
                result,
                NovaAudioInputPolicy.endCallCompanionListening(context)
            )

            "endListeningSession" -> succeedOnMain(
                result,
                NovaAudioInputPolicy.endListeningSession(context)
            )

            "getAudioInputPolicyState" -> succeedOnMain(
                result,
                NovaAudioInputPolicy.getState(context)
            )

            "ensureStreamingAsrReady" -> {
                val success = streamingAsrEngine.initialize()
                succeedOnMain(
                    result,
                    mapOf(
                        "success" to success,
                        "message" to if (success) "Streaming ASR yürütücü hazır." else "Streaming ASR yürütücüsü hazırlanamadı.",
                        "streamingAsrState" to streamingAsrEngine.stateMap(),
                    )
                )
            }

            "getStreamingAsrExecutiveState" -> succeedOnMain(
                result,
                mapOf(
                    "success" to true,
                    "message" to "OK",
                    "streamingAsrState" to streamingAsrEngine.stateMap(),
                )
            )

            "prewarmContinuousListeningSession" -> {
                val holdForMs = (call.argument<Int>("holdForMs") ?: 120000).toLong()
                val success = streamingAsrEngine.initialize()
                val state = streamingAsrEngine.stateMap()
                succeedOnMain(
                    result,
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
                succeedOnMain(
                    result,
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
                succeedOnMain(
                    result,
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

            "startStreamingVoiceGate" -> succeedOnMain(
                result,
                NovaStreamingVoiceGate.start(context)
            )

            "stopStreamingVoiceGate" -> succeedOnMain(
                result,
                NovaStreamingVoiceGate.stop()
            )

            "getStreamingVoiceGateState" -> succeedOnMain(
                result,
                NovaStreamingVoiceGate.stateMap()
            )

            "captureCloneSampleExternal" -> {
                val seconds = call.argument<Int>("maxDurationSeconds") ?: 10
                val outputName = call.argument<String>("outputName") ?: "nova_external_clone"

                micHelper.recordSample(
                    seconds = seconds,
                    outputName = outputName,
                    callback = object : NovaMicAudioCaptureHelper.Callback {
                        override fun onDone(success: Boolean, filePath: String, message: String) {
                            succeedOnMain(
                                result,
                                mapOf(
                                    "success" to success,
                                    "filePath" to filePath,
                                    "message" to message,
                                )
                            )
                        }
                    }
                )
            }

            "captureCloneSampleInternal" -> {
                val seconds = call.argument<Int>("maxDurationSeconds") ?: 10
                val outputName = call.argument<String>("outputName") ?: "nova_internal_clone"

                internalAudioHelper.recordInternalAudio(
                    seconds = seconds,
                    outputName = outputName,
                    callback = object : NovaInternalAudioCaptureHelper.Callback {
                        override fun onDone(success: Boolean, filePath: String, message: String) {
                            succeedOnMain(
                                result,
                                mapOf(
                                    "success" to success,
                                    "filePath" to filePath,
                                    "message" to message,
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

                succeedOnMain(
                    result,
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
