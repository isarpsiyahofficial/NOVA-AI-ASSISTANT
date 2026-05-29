package com.example.nova

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class NovaAccessibilityService : AccessibilityService() {

    companion object {
        @Volatile
        var currentService: NovaAccessibilityService? = null
            private set
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    @Volatile
    private var serviceReady: Boolean = false

    override fun onServiceConnected() {
        super.onServiceConnected()

        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED or
                AccessibilityEvent.TYPE_VIEW_CLICKED or
                AccessibilityEvent.TYPE_VIEW_FOCUSED or
                AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED

            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            notificationTimeout = 120
            flags =
                AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS or
                    AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS
        }

        serviceInfo = info
        serviceReady = true
        currentService = this

        Log.d("NovaAccessibility", "Accessibility service connected")
        safeNotifyCoordinator(
            eventName = "accessibility_connected",
            payload = "ready"
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!serviceReady || event == null) return

        val root = rootInActiveWindow ?: return
        val packageName = event.packageName?.toString().orEmpty()
        val className = event.className?.toString().orEmpty()

        safeNotifyCoordinator(
            eventName = "accessibility_event",
            payload = buildEventPayload(
                eventType = event.eventType,
                packageName = packageName,
                className = className
            )
        )

        safeUpdateNativeState(
            packageName = packageName,
            className = className,
            screenText = collectVisibleTexts(root, limit = 25)
        )
    }

    override fun onInterrupt() {
        Log.w("NovaAccessibility", "Accessibility interrupted")
        safeNotifyCoordinator(
            eventName = "accessibility_interrupted",
            payload = "interrupted"
        )
    }

    override fun onDestroy() {
        serviceReady = false
        if (currentService === this) {
            currentService = null
        }

        Log.d("NovaAccessibility", "Accessibility service destroyed")
        safeNotifyCoordinator(
            eventName = "accessibility_destroyed",
            payload = "destroyed"
        )
        super.onDestroy()
    }

    fun isReady(): Boolean = serviceReady

    fun findFirstNodeByText(text: String): AccessibilityNodeInfo? {
        if (!serviceReady || text.isBlank()) return null
        val root = rootInActiveWindow ?: return null
        val matches = root.findAccessibilityNodeInfosByText(text.trim())
        if (matches.isNullOrEmpty()) return null
        return matches.firstOrNull()
    }

    fun performTapByText(text: String): Boolean {
        val node = findFirstNodeByText(text) ?: return false
        return clickNodeOrParent(node)
    }

    fun setTextToFocusedInput(text: String): Boolean {
        if (!serviceReady || text.isBlank()) return false

        return try {
            val root = rootInActiveWindow ?: return false

            var target = root.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
            if (target == null) {
                target = root.findFocus(AccessibilityNodeInfo.FOCUS_ACCESSIBILITY)
            }

            if (target == null) return false
            if (!target.isEditable) return false

            val args = Bundle().apply {
                putCharSequence(
                    AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE,
                    text
                )
            }

            target.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, args)
        } catch (t: Throwable) {
            Log.e("NovaAccessibility", "Set text failed", t)
            false
        }
    }

    fun performBackActionSafe(): Boolean {
        return try {
            performGlobalAction(GLOBAL_ACTION_BACK)
        } catch (t: Throwable) {
            Log.e("NovaAccessibility", "Back action failed", t)
            false
        }
    }

    fun performHomeActionSafe(): Boolean {
        return try {
            performGlobalAction(GLOBAL_ACTION_HOME)
        } catch (t: Throwable) {
            Log.e("NovaAccessibility", "Home action failed", t)
            false
        }
    }

    fun openNotificationsSafe(): Boolean {
        return try {
            performGlobalAction(GLOBAL_ACTION_NOTIFICATIONS)
        } catch (t: Throwable) {
            Log.e("NovaAccessibility", "Notifications action failed", t)
            false
        }
    }

    fun openQuickSettingsSafe(): Boolean {
        return try {
            performGlobalAction(GLOBAL_ACTION_QUICK_SETTINGS)
        } catch (t: Throwable) {
            Log.e("NovaAccessibility", "Quick settings action failed", t)
            false
        }
    }

    private fun clickNodeOrParent(node: AccessibilityNodeInfo?): Boolean {
        var current = node
        var depth = 0

        while (current != null && depth < 8) {
            try {
                if (current.isClickable) {
                    return current.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                }
            } catch (t: Throwable) {
                Log.e("NovaAccessibility", "Click failed", t)
                return false
            }

            current = current.parent
            depth++
        }

        return false
    }

    private fun collectVisibleTexts(
        root: AccessibilityNodeInfo,
        limit: Int
    ): String {
        val results = LinkedHashSet<String>()
        walkTree(root, results, limit)
        return results.joinToString(separator = " | ")
    }

    private fun walkTree(
        node: AccessibilityNodeInfo?,
        results: LinkedHashSet<String>,
        limit: Int
    ) {
        if (node == null || results.size >= limit) return

        val text = node.text?.toString()?.trim().orEmpty()
        val desc = node.contentDescription?.toString()?.trim().orEmpty()

        if (text.isNotEmpty()) results.add(text)
        if (desc.isNotEmpty()) results.add(desc)

        for (i in 0 until node.childCount) {
            if (results.size >= limit) return
            walkTree(node.getChild(i), results, limit)
        }
    }

    private fun buildEventPayload(
        eventType: Int,
        packageName: String,
        className: String
    ): String {
        return "type=$eventType;package=$packageName;class=$className"
    }

    private fun safeNotifyCoordinator(
        eventName: String,
        payload: String
    ) {
        try {
            mainHandler.post {
                try {
                    invokeAutomationCoordinatorEvent(
                        eventName = eventName,
                        payload = payload
                    )
                } catch (inner: Throwable) {
                    Log.w("NovaAccessibility", "Coordinator notify skipped: ${inner.message}")
                }
            }
        } catch (t: Throwable) {
            Log.w("NovaAccessibility", "Coordinator notify failed", t)
        }
    }

    private fun safeUpdateNativeState(
        packageName: String,
        className: String,
        screenText: String
    ) {
        try {
            mainHandler.post {
                try {
                    invokeAutomationNativeStateUpdate(
                        packageName = packageName,
                        className = className,
                        visibleText = screenText
                    )
                } catch (inner: Throwable) {
                    Log.w("NovaAccessibility", "Native state update skipped: ${inner.message}")
                }
            }
        } catch (t: Throwable) {
            Log.w("NovaAccessibility", "Native state update failed", t)
        }
    }

    private fun invokeAutomationCoordinatorEvent(
        eventName: String,
        payload: String
    ) {
        val candidateNames = listOf(
            "com.example.nova.automation.NovaAutomationCoordinator",
            "com.example.nova.NovaAutomationCoordinator"
        )

        for (className in candidateNames) {
            try {
                val clazz = Class.forName(className)

                try {
                    val method = clazz.getMethod(
                        "onAccessibilityEvent",
                        String::class.java,
                        String::class.java
                    )
                    method.invoke(null, eventName, payload)
                    return
                } catch (_: Throwable) {
                }

                try {
                    val instanceField = clazz.getField("INSTANCE")
                    val instance = instanceField.get(null)
                    val method = clazz.getMethod(
                        "onAccessibilityEvent",
                        String::class.java,
                        String::class.java
                    )
                    method.invoke(instance, eventName, payload)
                    return
                } catch (_: Throwable) {
                }
            } catch (_: Throwable) {
            }
        }
    }

    private fun invokeAutomationNativeStateUpdate(
        packageName: String,
        className: String,
        visibleText: String
    ) {
        val candidateNames = listOf(
            "com.example.nova.automation.NovaAutomationNativeState",
            "com.example.nova.NovaAutomationNativeState"
        )

        for (target in candidateNames) {
            try {
                val clazz = Class.forName(target)

                try {
                    val method = clazz.getMethod(
                        "updateScreenState",
                        String::class.java,
                        String::class.java,
                        String::class.java
                    )
                    method.invoke(null, packageName, className, visibleText)
                    return
                } catch (_: Throwable) {
                }

                try {
                    val instanceField = clazz.getField("INSTANCE")
                    val instance = instanceField.get(null)
                    val method = clazz.getMethod(
                        "updateScreenState",
                        String::class.java,
                        String::class.java,
                        String::class.java
                    )
                    method.invoke(instance, packageName, className, visibleText)
                    return
                } catch (_: Throwable) {
                }
            } catch (_: Throwable) {
            }
        }
    }
}