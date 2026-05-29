package com.example.nova

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class NovaReminderBridgePlugin(
    private val context: Context
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "nova/reminder_bridge"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context
        ) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            channel.setMethodCallHandler(NovaReminderBridgePlugin(context))
        }
    }

    override fun onMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "syncReminders" -> {
                try {
                    val items = call.argument<List<Map<String, Any?>>>("items") ?: emptyList()
                    NovaReminderScheduler.sync(context, items)
                    result.success(null)
                } catch (t: Throwable) {
                    result.error(
                        "REMINDER_SYNC_FAILED",
                        t.message ?: "Hatırlatıcı planı güncellenemedi.",
                        null
                    )
                }
            }
            else -> result.notImplemented()
        }
    }
}
