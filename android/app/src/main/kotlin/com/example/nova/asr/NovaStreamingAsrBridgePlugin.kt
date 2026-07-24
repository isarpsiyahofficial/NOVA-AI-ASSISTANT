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
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class NovaStreamingAsrBridgePlugin(
    private val context: Context,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private val engine by lazy { NovaStreamingAsrEngineProvider.get(context) }
    private val mainHandler = Handler(Looper.getMainLooper())
    private val worker: ExecutorService = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "NovaAsrNativeWorker").apply { isDaemon = true }
    }
    private var sink: EventChannel.EventSink? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initializeStreamingAsr" -> runAsync(result) { engine.initialize() }
            "startStreamingAsr" -> {
                val foreground =
                    call.argument<Boolean>("startForegroundService") ?: true
                runAsync(result) { startRuntime(foreground) }
            }
            "pauseStreamingAsr" -> runAsync(result) {
                val paused = engine.pause()
                stopVoiceGate()
                paused
            }
            "resumeStreamingAsr" -> runAsync(result) { resumeRuntime() }
            "clearStreamingAsrBuffer" -> runAsync(result) {
                NovaStreamingVoiceGate.clearBuffer()
                engine.clearBuffer()
            }
            "stopStreamingAsr" -> runAsync(result) { stopRuntime() }
            "flushStreamingAsr" -> runAsync(result) { engine.flush() }
            "getStreamingAsrState" -> runAsync(result) {
                val engineState = engine.stateMap().toMutableMap()
                engineState["voiceGate"] = NovaStreamingVoiceGate.stateMap()
                engineState["nativeWorker"] = "NovaAsrNativeWorker"
                engineState
            }
            else -> result.notImplemented()
        }
    }

    private fun startRuntime(startForegroundService: Boolean): Boolean {
        val currentState = engine.stateMap()
        if (currentState["running"] as? Boolean == true) {
            val (gateReady, gateMessage) = startVoiceGate()
            if (!gateReady) {
                emit("error", emptyResult(), gateMessage)
                return false
            }
            val resumed = engine.resume()
            emit(
                "status",
                emptyResult(),
                "Streaming ASR ve Silero mikrofon kapısı zaten çalışıyor; start idempotent kabul edildi.",
            )
            return resumed
        }

        if (startForegroundService) {
            try {
                context.startForegroundService(
                    Intent(context, NovaAsrForegroundService::class.java),
                )
                engine.setForegroundServiceRunning(true)
            } catch (t: Throwable) {
                stopVoiceGate()
                stopForegroundServiceSafely()
                emit(
                    "error",
                    emptyResult(),
                    t.message ?: "ASR foreground servisi başlatılamadı.",
                )
                return false
            }
        }

        val (gateReady, gateMessage) = startVoiceGate()
        if (!gateReady) {
            stopVoiceGate()
            stopForegroundServiceSafely()
            emit("error", emptyResult(), gateMessage)
            return false
        }

        val started = engine.start(::emit)
        if (!started) {
            engine.stop()
            stopVoiceGate()
            stopForegroundServiceSafely()
            emit(
                "error",
                emptyResult(),
                "Whisper/Silero ASR başlatılamadı; mikrofon ve foreground servis kapatıldı.",
            )
        }
        return started
    }

    private fun resumeRuntime(): Boolean {
        val (gateReady, gateMessage) = startVoiceGate()
        if (!gateReady) {
            emit("error", emptyResult(), gateMessage)
            return false
        }
        return engine.resume()
    }

    private fun stopRuntime(): Boolean {
        val stopped = engine.stop()
        stopVoiceGate()
        stopForegroundServiceSafely()
        return stopped
    }

    private fun startVoiceGate(): Pair<Boolean, String> {
        val state = NovaStreamingVoiceGate.stateMap()
        if (state["running"] == true && state["vadReady"] == true) {
            return true to "Silero VAD mikrofon kapısı zaten çalışıyor."
        }
        val started = NovaStreamingVoiceGate.start(context)
        return (started["success"] as? Boolean == true) to
            (started["message"]?.toString()
                ?: "Silero VAD mikrofon kapısı yanıt vermedi.")
    }

    private fun stopVoiceGate() {
        try {
            NovaStreamingVoiceGate.stop()
        } catch (_: Throwable) {
        }
    }

    private fun stopForegroundServiceSafely() {
        try {
            context.stopService(Intent(context, NovaAsrForegroundService::class.java))
        } catch (_: Throwable) {
        }
        engine.setForegroundServiceRunning(false)
    }

    private fun runAsync(
        result: MethodChannel.Result,
        block: () -> Any?,
    ) {
        worker.execute {
            val value = try {
                block()
            } catch (t: Throwable) {
                emit(
                    "error",
                    emptyResult(),
                    "Native ASR worker hatası: ${t.message ?: t.javaClass.simpleName}",
                )
                false
            }
            mainHandler.post {
                try {
                    result.success(value)
                } catch (_: Throwable) {
                }
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
    }

    override fun onCancel(arguments: Any?) {
        sink = null
    }

    private fun emptyResult(): NovaStreamingAsrResult {
        return NovaStreamingAsrResult(
            text = "",
            isFinal = false,
            confidence = 0f,
            segmentId = 0,
            startMs = 0,
            endMs = 0,
            locale = "tr-TR",
        )
    }

    private fun emit(
        type: String,
        payload: NovaStreamingAsrResult,
        message: String,
    ) {
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
