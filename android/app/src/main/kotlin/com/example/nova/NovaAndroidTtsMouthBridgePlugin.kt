package com.example.nova

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaAndroidTtsMouthBridgePlugin(
    private val context: Context
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "nova/android_tts_mouth"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context
        ) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            channel.setMethodCallHandler(
                NovaAndroidTtsMouthBridgePlugin(context.applicationContext)
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "warmup" -> {
                val language = call.argument<String>("language")?.trim().orEmpty().ifBlank { "tr-TR" }
                val preferFemale = call.argument<Boolean>("preferFemale") ?: true
                result.success(
                    NovaAndroidTtsMouthEngine.warmup(
                        context = context,
                        language = language,
                        preferFemale = preferFemale
                    )
                )
            }

            "speak" -> {
                val text = call.argument<String>("text")?.trim().orEmpty()
                val language = call.argument<String>("language")?.trim().orEmpty().ifBlank { "tr-TR" }
                val preferFemale = call.argument<Boolean>("preferFemale") ?: true
                val allowUnknownGenderTurkish = call.argument<Boolean>("allowUnknownGenderTurkish") ?: true
                val speechRate = (call.argument<Double>("speechRate") ?: 0.96).toFloat()
                val pitch = (call.argument<Double>("pitch") ?: 1.03).toFloat()

                if (text.isEmpty()) {
                    result.success(false)
                    return
                }

                Thread {
                    val success = NovaAndroidTtsMouthEngine.speak(
                        context = context,
                        text = text,
                        language = language,
                        preferFemale = preferFemale,
                        allowUnknownGenderTurkish = allowUnknownGenderTurkish,
                        speechRate = speechRate,
                        pitch = pitch,
                        waitForDone = true
                    )
                    Handler(Looper.getMainLooper()).post {
                        result.success(success)
                    }
                }.apply {
                    name = "Nova-AndroidTtsMouth"
                    isDaemon = true
                }.start()
            }

            "stop" -> result.success(NovaAndroidTtsMouthEngine.stop())

            "getState" -> result.success(NovaAndroidTtsMouthEngine.debugState())

            else -> result.notImplemented()
        }
    }
}
