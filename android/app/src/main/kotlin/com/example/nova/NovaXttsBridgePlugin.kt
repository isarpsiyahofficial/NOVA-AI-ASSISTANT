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

    private val engine = NovaXttsEngine(context)

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
                NovaXttsBridgePlugin(context)
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

                    if (text.isEmpty()) {
                        result.success(false)
                        return
                    }

                    Thread {
                        val success = try {
                            val languageLower = language.lowercase()
                            if (languageLower.startsWith("tr")) {
                                val neuralOk = engine.speak(
                                    text = text,
                                    language = language,
                                    speakerPath = speakerPath
                                )
                                if (neuralOk) {
                                    true
                                } else {
                                    NovaAndroidTtsMouthEngine.speak(
                                        context = context,
                                        text = text,
                                        language = language,
                                        preferFemale = true,
                                        allowUnknownGenderTurkish = true,
                                        waitForDone = true
                                    )
                                }
                            } else {
                                engine.speak(
                                    text = text,
                                    language = language,
                                    speakerPath = speakerPath
                                )
                            }
                        } catch (_: Throwable) {
                            false
                        }
                        Handler(Looper.getMainLooper()).post {
                            result.success(success)
                        }
                    }.apply {
                        name = "NovaXttsSpeakAwaiter"
                        isDaemon = true
                    }.start()
                }

                "stopXtts" -> {
                    engine.stop()
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
                        "supportsSpeakerId" to false,
                        "supportsReferenceAudio" to false,
                        "availableModels" to emptyList<String>(),
                        "message" to "XTTS capability bilgisi alınamadı."
                    )
                )
                "speakWithXtts" -> result.success(false)
                "stopXtts" -> result.success(false)
                else -> result.notImplemented()
            }
        }
    }
}
