package com.example.nova

import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaOverlayBridgePlugin(
    private val context: Context,
    private val bootGuard: NovaBootGuard,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "nova/overlay_bridge"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context,
            bootGuard: NovaBootGuard,
        ) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            channel.setMethodCallHandler(
                NovaOverlayBridgePlugin(
                    context = context,
                    bootGuard = bootGuard,
                )
            )
        }

        private fun startOverlayService(context: Context, intent: Intent) {
            context.startService(intent)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "showCloneOverlayProgress" -> {
                    if (!bootGuard.isBackgroundAllowed()) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Overlay güvenlik nedeniyle şu an kapalı."
                            )
                        )
                        return
                    }

                    if (!Settings.canDrawOverlays(context)) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Overlay izni kapalı."
                            )
                        )
                        return
                    }

                    val title = call.argument<String>("title").orEmpty().trim()
                    val status = call.argument<String>("status").orEmpty().trim()
                    val progress = (call.argument<Double>("progress") ?: -1.0).toFloat()
                    val textOpacity = (call.argument<Double>("textOpacity") ?: 0.98).toFloat()
                    val shellOpacity = (call.argument<Double>("shellOpacity") ?: 0.55).toFloat()
                    val emotionLabel = call.argument<String>("emotionLabel").orEmpty().trim()
                    val showEmotionChip = call.argument<Boolean>("showEmotionChip") ?: false

                    val startedBackground = NovaNativeServiceBridge.startBackground(context)

                    val intent = Intent(context, NovaOverlayService::class.java).apply {
                        putExtra(
                            NovaOverlayService.EXTRA_ACTION,
                            NovaOverlayService.ACTION_SHOW_CLONE_PROGRESS
                        )
                        putExtra(
                            NovaOverlayService.EXTRA_TITLE,
                            if (title.isBlank()) "Nova" else title
                        )
                        putExtra(
                            NovaOverlayService.EXTRA_STATUS,
                            if (status.isBlank()) "Hazırlanıyor..." else status
                        )
                        putExtra(
                            NovaOverlayService.EXTRA_PROGRESS,
                            progress
                        )
                        putExtra(
                            NovaOverlayService.EXTRA_TEXT_OPACITY,
                            textOpacity
                        )
                        putExtra(
                            NovaOverlayService.EXTRA_SHELL_OPACITY,
                            shellOpacity
                        )
                        putExtra(
                            NovaOverlayService.EXTRA_EMOTION_LABEL,
                            emotionLabel
                        )
                        putExtra(
                            NovaOverlayService.EXTRA_SHOW_EMOTION_CHIP,
                            showEmotionChip
                        )
                    }

                    startOverlayService(context, intent)

                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to if (startedBackground) {
                                "Klon overlay progress gösterildi."
                            } else {
                                "Overlay gösterildi, background servis doğrulaması sınırlı kaldı."
                            }
                        )
                    )
                }

                "hideCloneOverlayProgress" -> {
                    if (!bootGuard.isBackgroundAllowed()) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Overlay güvenlik nedeniyle şu an kapalı."
                            )
                        )
                        return
                    }

                    if (!Settings.canDrawOverlays(context)) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Overlay izni kapalı."
                            )
                        )
                        return
                    }

                    val intent = Intent(context, NovaOverlayService::class.java).apply {
                        putExtra(
                            NovaOverlayService.EXTRA_ACTION,
                            NovaOverlayService.ACTION_HIDE
                        )
                    }

                    startOverlayService(context, intent)

                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to "Klon overlay progress gizlendi."
                        )
                    )
                }

                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.success(
                mapOf(
                    "success" to false,
                    "message" to "Overlay bridge hatası: ${t.message ?: "unknown"}"
                )
            )
        }
    }
}