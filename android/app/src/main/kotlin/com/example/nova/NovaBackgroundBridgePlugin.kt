package com.example.nova

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaBackgroundBridgePlugin(
    private val context: Context,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "nova/background_bridge"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context,
        ) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            channel.setMethodCallHandler(
                NovaBackgroundBridgePlugin(context)
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "startBackground" -> {
                    val ok = NovaNativeServiceBridge.startBackground(context)
                    result.success(
                        mapOf(
                            "success" to ok,
                            "message" to if (ok) {
                                "Nova background başlatıldı."
                            } else {
                                "Nova background başlatılamadı."
                            }
                        )
                    )
                }

                "setBackgroundRunning" -> {
                    val ok = NovaNativeServiceBridge.setBackgroundRunning(context)
                    result.success(
                        mapOf(
                            "success" to ok,
                            "message" to if (ok) {
                                "Nova background aktif moda alındı."
                            } else {
                                "Nova background aktif moda alınamadı."
                            }
                        )
                    )
                }

                "setBackgroundSleeping" -> {
                    val ok = NovaNativeServiceBridge.setBackgroundSleeping(context)
                    result.success(
                        mapOf(
                            "success" to ok,
                            "message" to if (ok) {
                                "Nova background pasif uykuya alındı."
                            } else {
                                "Nova background pasif uykuya alınamadı."
                            }
                        )
                    )
                }

                "setBackgroundFullyOff" -> {
                    val ok = NovaNativeServiceBridge.setBackgroundFullyOff(context)
                    result.success(
                        mapOf(
                            "success" to ok,
                            "message" to if (ok) {
                                "Nova background tamamen kapatıldı."
                            } else {
                                "Nova background tamamen kapatılamadı."
                            }
                        )
                    )
                }

                "showOverlayIdle" -> {
                    val ok = NovaNativeServiceBridge.showOverlayIdle(context)
                    result.success(
                        overlayResult(
                            ok = ok,
                            successText = "Idle overlay gösterildi."
                        )
                    )
                }

                "showOverlayListening" -> {
                    val ok = NovaNativeServiceBridge.showOverlayListening(context)
                    result.success(
                        overlayResult(
                            ok = ok,
                            successText = "Listening overlay gösterildi."
                        )
                    )
                }

                "showOverlaySpeaking" -> {
                    val ok = NovaNativeServiceBridge.showOverlaySpeaking(context)
                    result.success(
                        overlayResult(
                            ok = ok,
                            successText = "Speaking overlay gösterildi."
                        )
                    )
                }

                "showOverlaySleeping" -> {
                    val ok = NovaNativeServiceBridge.showOverlaySleeping(context)
                    result.success(
                        overlayResult(
                            ok = ok,
                            successText = "Sleeping overlay gösterildi."
                        )
                    )
                }

                "hideOverlay" -> {
                    val ok = NovaNativeServiceBridge.hideOverlay(context)
                    result.success(
                        overlayResult(
                            ok = ok,
                            successText = "Overlay gizlendi."
                        )
                    )
                }

                "removeOverlay" -> {
                    val ok = NovaNativeServiceBridge.removeOverlay(context)
                    result.success(
                        overlayResult(
                            ok = ok,
                            successText = "Overlay kaldırıldı."
                        )
                    )
                }


                "isIgnoringBatteryOptimizations" -> {
                    val powerManager = context.getSystemService(Context.POWER_SERVICE) as? PowerManager
                    val ignoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        powerManager?.isIgnoringBatteryOptimizations(context.packageName) == true
                    } else {
                        true
                    }
                    result.success(
                        mapOf(
                            "success" to ignoring,
                            "message" to if (ignoring) {
                                "Nova pil optimizasyonu tarafından uyutulmuyor."
                            } else {
                                "Nova pil optimizasyonu tarafından kısıtlanabilir. TECNO/HiOS üzerinde Uyutulmayan Uygulamalar listesine ekleyin."
                            }
                        )
                    )
                }

                "openBatteryOptimizationSettings" -> {
                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to "Pil optimizasyonu ayarları açıldı. Nova'i kısıtlanmayan/uyutulmayan uygulama yapın."
                        )
                    )
                }

                "openAppBatterySettings" -> {
                    val intent = Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:${context.packageName}")
                    )
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to "Nova uygulama ayarları açıldı. Pil: Kısıtlama yok / Arka planda izinli seçin."
                        )
                    )
                }

                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.success(
                mapOf(
                    "success" to false,
                    "message" to "Background bridge hatası: ${t.message ?: "unknown"}"
                )
            )
        }
    }

    private fun overlayResult(
        ok: Boolean,
        successText: String,
    ): Map<String, Any> {
        if (ok) {
            return mapOf(
                "success" to true,
                "message" to successText,
            )
        }

        val hasPermission = Settings.canDrawOverlays(context)
        return mapOf(
            "success" to false,
            "message" to if (!hasPermission) {
                "Overlay izni kapalı olduğu için işlem uygulanamadı."
            } else {
                "Overlay servisi başlatılamadı."
            }
        )
    }
}