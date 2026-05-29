package com.example.nova.automation

import android.content.Context
import android.provider.Settings
import com.example.nova.NovaAccessibilityService
import java.util.concurrent.atomic.AtomicReference

class NovaAutomationCoordinator(
    private val context: Context
) {
    fun getState(): NovaAutomationNativeState = stateRef.get()

    fun setLearningMode() {
        replaceState {
            it.copy(
                mode = NovaAutomationNativeMode.LEARNING,
                lastError = ""
            )
        }
    }

    fun setExecutingMode() {
        replaceState {
            it.copy(
                mode = NovaAutomationNativeMode.EXECUTING,
                lastError = ""
            )
        }
    }

    fun pauseExecution() {
        replaceState {
            it.copy(mode = NovaAutomationNativeMode.PAUSED)
        }
    }

    fun cancelExecution() {
        replaceState {
            it.copy(mode = NovaAutomationNativeMode.CANCELLED)
        }
    }

    fun markError(message: String) {
        replaceState {
            it.copy(
                mode = NovaAutomationNativeMode.ERROR,
                lastError = message.trim()
            )
        }
    }

    fun resetIdle() {
        replaceState {
            it.copy(
                mode = NovaAutomationNativeMode.IDLE,
                currentStepIndex = 0,
                lastError = ""
            )
        }
    }

    fun updateCurrentPackage(packageName: String?) {
        replaceState {
            it.copy(currentPackageName = packageName?.trim().orEmpty())
        }
    }

    fun updateCurrentStep(stepIndex: Int) {
        replaceState {
            it.copy(currentStepIndex = if (stepIndex < 0) 0 else stepIndex)
        }
    }

    fun refreshPlatformReadiness(
        overlayEnabled: Boolean,
        accessibilityReady: Boolean
    ) {
        replaceState {
            it.copy(
                overlayEnabled = overlayEnabled,
                accessibilityReady = accessibilityReady
            )
        }
    }

    fun isAccessibilityEnabled(): Boolean {
        val expectedService =
            "${context.packageName}/${NovaAccessibilityService::class.java.name}"

        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return enabledServices.contains(expectedService, ignoreCase = true)
    }

    private fun replaceState(transform: (NovaAutomationNativeState) -> NovaAutomationNativeState) {
        val current = stateRef.get()
        stateRef.set(transform(current))
    }

    companion object {
        private val stateRef = AtomicReference(NovaAutomationNativeState())

        @Volatile
        private var lastAccessibilityEventName: String = ""

        @Volatile
        private var lastAccessibilityPayload: String = ""

        @JvmStatic
        fun onAccessibilityEvent(
            eventName: String,
            payload: String
        ) {
            lastAccessibilityEventName = eventName.trim()
            lastAccessibilityPayload = payload.trim()

            val current = stateRef.get()
            val next = when (eventName.trim()) {
                "accessibility_connected" -> current.copy(
                    accessibilityReady = true,
                    lastError = ""
                )
                "accessibility_interrupted" -> current.copy(
                    accessibilityReady = false,
                    lastError = payload.trim()
                )
                "accessibility_destroyed" -> current.copy(
                    accessibilityReady = false,
                    lastError = payload.trim()
                )
                else -> current
            }
            stateRef.set(next)
        }

        @JvmStatic
        fun updateScreenState(
            packageName: String,
            className: String,
            visibleText: String
        ) {
            val current = stateRef.get()
            stateRef.set(
                current.copy(
                    currentPackageName = packageName.trim(),
                    lastVisibleClassName = className.trim(),
                    lastVisibleText = visibleText.trim()
                )
            )
        }



        @JvmStatic
        fun getStateSnapshot(): NovaAutomationNativeState = stateRef.get()

        @JvmStatic
        fun getLastAccessibilityEventName(): String = lastAccessibilityEventName

        @JvmStatic
        fun getLastAccessibilityPayload(): String = lastAccessibilityPayload
    }
}