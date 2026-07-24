package com.example.nova

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaXttsBridgePlugin(
    private val context: Context
) : MethodChannel.MethodCallHandler {

    private val engine = NovaXttsEngine(context.applicationContext)

    companion object {
        private const val CHANNEL = "nova/xtts_bridge"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context
        ) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            channel.setMethodCallHandler(
                NovaXttsBridgePlugin(context.applicationContext)
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isXttsReady" -> result.success(engine.isReady())

                "warmupXtts" -> {
                    val preferredModelKey = call.argument<String>("preferredModelKey").orEmpty()
                    result.success(engine.warmup(preferredModelKey))
                }

                "getXttsCapabilities" -> result.success(engine.getCapabilities())

                "speakWithXtts" -> {
                    val text = call.argument<String>("text").orEmpty().trim()
                    val language = call.argument<String>("language")?.trim().orEmpty()
                        .ifEmpty { "tr" }
                    val speakerPath = call.argument<String>("speakerPath")?.trim().orEmpty()
                    val speed = (call.argument<Double>("speed") ?: 1.0).toFloat()

                    if (text.isEmpty()) {
                        result.success(false)
                        return
                    }

                    Thread {
                        val success = try {
                            engine.speak(
                                text = text,
                                language = language,
                                speakerPath = speakerPath,
                                speed = speed,
                            )
                        } catch (_: Throwable) {
                            false
                        }
                        Handler(Looper.getMainLooper()).post {
                            result.success(success)
                        }
                    }.apply {
                        name = "NovaSherpaOfflineTts"
                        isDaemon = true
                    }.start()
                }

                "stopXtts" -> {
                    engine.stop()
                    result.success(true)
                }

                "releaseXtts" -> {
                    engine.release()
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        } catch (_: Throwable) {
            when (call.method) {
                "isXttsReady" -> result.success(false)
                "warmupXtts" -> result.success(false)
                "getXttsCapabilities" -> result.success(
                    mapOf(
                        "ready" to false,
                        "assetReady" to false,
                        "supportsSpeakerId" to false,
                        "supportsReferenceAudio" to false,
                        "availableModels" to emptyList<String>(),
                        "engine" to "sherpa_onnx_offline_tts",
                        "message" to "Sherpa offline TTS capability bilgisi alınamadı."
                    )
                )
                "speakWithXtts" -> result.success(false)
                "stopXtts", "releaseXtts" -> result.success(false)
                else -> result.notImplemented()
            }
        }
    }
}
