package com.example.nova

import android.content.Context
import android.content.Intent

object NovaSecurityProcessLauncher {
    fun start(context: Context, serviceClass: Class<*>, action: String, extras: Map<String, Any?> = emptyMap()): Boolean {
        return try {
            val intent = Intent(context.applicationContext, serviceClass).apply {
                `package` = context.packageName
                this.action = action
                extras.forEach { (key, value) ->
                    when (value) {
                        is String -> putExtra(key, value)
                        is Int -> putExtra(key, value)
                        is Boolean -> putExtra(key, value)
                        is Long -> putExtra(key, value)
                    }
                }
            }
            context.startService(intent)
            true
        } catch (_: Throwable) {
            false
        }
    }
}
