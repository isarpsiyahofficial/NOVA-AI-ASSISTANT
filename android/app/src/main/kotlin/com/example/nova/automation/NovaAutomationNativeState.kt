package com.example.nova.automation

enum class NovaAutomationNativeMode {
    IDLE,
    LEARNING,
    EXECUTING,
    PAUSED,
    CANCELLED,
    ERROR
}

data class NovaAutomationNativeState(
    val mode: NovaAutomationNativeMode = NovaAutomationNativeMode.IDLE,
    val currentPackageName: String = "",
    val currentStepIndex: Int = 0,
    val lastError: String = "",
    val overlayEnabled: Boolean = false,
    val accessibilityReady: Boolean = false,
    val lastVisibleClassName: String = "",
    val lastVisibleText: String = ""
) {
    companion object {
        @JvmStatic
        fun updateScreenState(
            packageName: String,
            className: String,
            visibleText: String
        ) {
            NovaAutomationCoordinator.updateScreenState(
                packageName = packageName,
                className = className,
                visibleText = visibleText
            )
        }
    }
}