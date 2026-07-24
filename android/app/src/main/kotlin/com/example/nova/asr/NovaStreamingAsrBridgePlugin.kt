package com.example.nova.asr

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import com.example.nova.NovaStreamingVoiceGate
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaStreamingAsrBridgePlugin(
    private val context: Context,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val engine by lazy { NovaStreamingAsrEngineProvider.get(context) }
    private val mainHandler = Handler(Looper.getMainLooper())
    private var sink: EventChannel.EventSink? = null

    private fun stopForegroundServiceSafely() {
        try {
            context.stopService(Intent(context, NovaAsrForegroundService::class.java))
        } catch (_: Throwable) {
        }
        engine.setForegroundServiceRunning(false)
    }

    private fun startVoiceGate(): Pair<Boolean, String> {
        val state = NovaStreamingVoiceGate.stateMap()
        if (state["running"] == true) {
            return true to "Streaming ses kapısı zaten çalışıyor."
        }
        val started = NovaStreamingVoiceGate.start(context)
        return (started["success"] as? Boolean == true) to
            (started["message"]?.toString() ?: "Streaming ses kapısı yanıt vermedi.")
    }

    private fun stopVoiceGate() {
        try {
            NovaStreamingVoiceGate.stop()
        } catch (_: Throwable) {
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initializeStreamingAsr" -> result.success(engine.initialize())

            "startStreamingAsr" -> {
                val startForegroundService =
                    call.argument<Boolean>("startForegroundService") ?: true
                val currentState = engine.stateMap()
                if (currentState["running"] as? Boolean == true) {
                    val (gateReady, gateMessage) = startVoiceGate()
                    if (!gateReady) {
                        emit(
                            "error",
                            NovaStreamingAsrResult("", false, 0f, 0, 0, 0, "tr-TR"),
                            gateMessage,
                        )
                        result.success(false)
                        return
                    }
                    engine.resume()
                    emit(
                        "status",
                        NovaStreamingAsrResult("", false, 0f, 0, 0, 0, "tr-TR"),
                        "Streaming ASR ve tek mikrofon kapısı zaten çalışıyor; ikinci start idempotent kabul edildi.",
                    )
                    result.success(true)
                    return
                }

                if (startForegroundService) {
                    try {
                        val intent = Intent(context, NovaAsrForegroundService::class.java)
                        context.startForegroundService(intent)
                        engine.setForegroundServiceRunning(true)
                    } catch (t: Throwable) {
                        stopVoiceGate()
                        stopForegroundServiceSafely()
                        emit(
                            "error",
                            NovaStreamingAsrResult("", false, 0f, 0, 0, 0, "tr-TR"),
                            t.message ?: "ASR foreground servisi başlatılamadı.",
                        )
                        result.success(false)
                        return
                    }
                }

                val (gateReady, gateMessage) = startVoiceGate()
                if (!gateReady) {
                    stopVoiceGate()
                    stopForegroundServiceSafely()
                    emit(
                        "error",
                        NovaStreamingAsrResult("", false, 0f, 0, 0, 0, "tr-TR"),
                        gateMessage,
                    )
                    result.success(false)
                    return
                }

                val started = engine.start(::emit)
                if (!started) {
                    engine.stop()
                    stopVoiceGate()
                    stopForegroundServiceSafely()
                    emit(
                        "error",
                        NovaStreamingAsrResult("", false, 0f, 0, 0, 0, "tr-TR"),
                        "Streaming ASR engine başlatılamadı; mikrofon ve foreground bildirim güvenli kapatıldı.",
                    )
                }
                result.success(started)
            }

            "pauseStreamingAsr" -> {
                val paused = engine.pause()
                stopVoiceGate()
                result.success(paused)
            }

            "resumeStreamingAsr" -> {
                val (gateReady, gateMessage) = startVoiceGate()
                if (!gateReady) {
                    emit(
                        "error",
                        NovaStreamingAsrResult("", false, 0f, 0, 0, 0, "tr-TR"),
                        gateMessage,
                    )
                    result.success(false)
                    return
                }
                result.success(engine.resume())
            }

            "clearStreamingAsrBuffer" -> {
                NovaStreamingVoiceGate.clearBuffer()
                result.success(engine.clearBuffer())
            }

            "stopStreamingAsr" -> {
                val stopped = engine.stop()
                stopVoiceGate()
                stopForegroundServiceSafely()
                result.success(stopped)
            }

            "flushStreamingAsr" -> result.success(engine.flush())
            "getStreamingAsrState" -> {
                val engineState = engine.stateMap().toMutableMap()
                engineState["voiceGate"] = NovaStreamingVoiceGate.stateMap()
                result.success(engineState)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private fun emit(type: String, payload: NovaStreamingAsrResult, message: String) {
        val event = mapOf(
            "type" to type,
            "transcript" to mapOf(
                "text" to payload.text,
                "isFinal" to payload.isFinal,
                "confidence" to payload.confidence.toDouble(),
                "segmentId" to payload.segmentId,
                "startMs" to payload.startMs,
                "endMs" to payload.endMs,
                "locale" to payload.locale,
            ),
            "message" to message,
            "createdAt" to java.time.Instant.now().toString(),
        )
        mainHandler.post {
            try {
                sink?.success(event)
            } catch (_: Throwable) {
            }
        }
    }

    companion object {
        private const val METHOD_CHANNEL = "nova/streaming_asr_bridge"
        private const val EVENT_CHANNEL = "nova/streaming_asr_bridge/events"

        fun register(flutterEngine: FlutterEngine, context: Context) {
            val plugin = NovaStreamingAsrBridgePlugin(context)
            MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                METHOD_CHANNEL,
            ).setMethodCallHandler(plugin)
            EventChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                EVENT_CHANNEL,
            ).setStreamHandler(plugin)
        }
    }
}
