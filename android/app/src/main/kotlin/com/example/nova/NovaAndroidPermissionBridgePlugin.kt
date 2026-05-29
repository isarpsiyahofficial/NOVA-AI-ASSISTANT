package com.example.nova

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.app.role.RoleManager
import android.content.Context
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.telecom.TelecomManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaAndroidPermissionBridgePlugin(
    private val context: Context,
    private val activity: Activity?,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "nova/android_permission_bridge"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context,
            activity: Activity?,
        ) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            channel.setMethodCallHandler(
                NovaAndroidPermissionBridgePlugin(context, activity)
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "canDrawOverlays" -> result.success(Settings.canDrawOverlays(context))

                "openOverlaySettings" -> {
                    result.success(
                        safeStartActivity(
                            Intent(
                                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                Uri.parse("package:${context.packageName}")
                            ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                        )
                    )
                }

                "isAccessibilityEnabled" -> result.success(isAccessibilityEnabled())

                "openAccessibilitySettings" -> {
                    result.success(
                        safeStartActivity(
                            Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                        )
                    )
                }

                "canPostNotifications" -> result.success(canPostNotifications())

                "requestPostNotificationsPermission" -> {
                    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                        result.success(true)
                        return
                    }
                    val host = activity
                    if (host == null) {
                        result.success(false)
                        return
                    }
                    ActivityCompat.requestPermissions(
                        host,
                        arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                        4312
                    )
                    result.success(canPostNotifications())
                }

                "openAppNotificationSettings" -> {
                    val opened = safeStartActivity(
                        Intent().apply {
                            action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                            putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                    ) || safeStartActivity(
                        Intent(
                            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", context.packageName, null)
                        ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                    )
                    result.success(opened)
                }

                "hasRecordAudioPermission" -> result.success(hasRecordAudioPermission())
                "hasReadPhoneStatePermission" -> result.success(hasPermission(Manifest.permission.READ_PHONE_STATE))
                "hasReadPhoneNumbersPermission" -> result.success(
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) hasPermission(Manifest.permission.READ_PHONE_NUMBERS) else true
                )
                "hasReadCallLogPermission" -> result.success(hasPermission(Manifest.permission.READ_CALL_LOG))
                "hasAnswerPhoneCallsPermission" -> result.success(
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) hasPermission(Manifest.permission.ANSWER_PHONE_CALLS) else true
                )
                "hasCallPhonePermission" -> result.success(hasPermission(Manifest.permission.CALL_PHONE))
                "getPermissionSnapshot" -> result.success(buildPermissionSnapshot())

                "requestRecordAudioPermission" -> {
                    val host = activity
                    if (host == null) {
                        result.success(false)
                        return
                    }
                    ActivityCompat.requestPermissions(
                        host,
                        arrayOf(Manifest.permission.RECORD_AUDIO),
                        4311
                    )
                    result.success(hasRecordAudioPermission())
                }

                "requestEssentialCallPermissions" -> {
                    val host = activity
                    if (host == null) {
                        result.success(false)
                        return
                    }
                    val permissions = mutableListOf<String>()
                    if (!hasPermission(Manifest.permission.READ_PHONE_STATE)) permissions.add(Manifest.permission.READ_PHONE_STATE)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !hasPermission(Manifest.permission.READ_PHONE_NUMBERS)) permissions.add(Manifest.permission.READ_PHONE_NUMBERS)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !hasPermission(Manifest.permission.ANSWER_PHONE_CALLS)) permissions.add(Manifest.permission.ANSWER_PHONE_CALLS)
                    if (!hasPermission(Manifest.permission.CALL_PHONE)) permissions.add(Manifest.permission.CALL_PHONE)
                    if (!hasPermission(Manifest.permission.READ_CALL_LOG)) permissions.add(Manifest.permission.READ_CALL_LOG)
                    if (permissions.isEmpty()) {
                        result.success(true)
                        return
                    }
                    ActivityCompat.requestPermissions(host, permissions.toTypedArray(), 4314)
                    result.success(true)
                }

                "isDefaultDialer" -> result.success(isDefaultDialer())
                "isCallScreeningRoleHeld" -> result.success(isCallScreeningRoleHeld())
                "requestCallScreeningRole" -> {
                    val host = activity
                    if (host == null) {
                        result.success(false)
                        return
                    }
                    result.success(requestCallScreeningRole(host))
                }

                "requestDefaultDialerRole" -> {
                    val host = activity
                    if (host == null) {
                        result.success(false)
                        return
                    }
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val roleManager = context.getSystemService(RoleManager::class.java)
                            if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_DIALER)) {
                                if (roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
                                    result.success(true)
                                    return
                                }
                                val roleIntent = roleManager.createRequestRoleIntent(RoleManager.ROLE_DIALER)
                                host.startActivityForResult(roleIntent, 4313)
                                result.success(true)
                                return
                            }
                        }
                        val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                        if (telecomManager?.defaultDialerPackage == context.packageName) {
                            result.success(true)
                            return
                        }
                        val changeIntent = Intent(TelecomManager.ACTION_CHANGE_DEFAULT_DIALER).apply {
                            putExtra(TelecomManager.EXTRA_CHANGE_DEFAULT_DIALER_PACKAGE_NAME, context.packageName)
                        }
                        val opened = tryStartActivityForResult(host, changeIntent, 4313) ||
                            safeStartActivity(
                                Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                            )
                        result.success(opened)
                    } catch (_: Throwable) {
                        result.success(false)
                    }
                }

                "openAppSettings" -> {
                    result.success(
                        safeStartActivity(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", context.packageName, null)
                            ).apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
                        )
                    )
                }

                else -> result.notImplemented()
            }
        } catch (_: Throwable) {
            result.success(false)
        }
    }

    private fun hasRecordAudioPermission(): Boolean {
        return hasPermission(Manifest.permission.RECORD_AUDIO)
    }

    private fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED
    }

    private fun buildPermissionSnapshot(): Map<String, Boolean> {
        val readPhoneState = hasPermission(Manifest.permission.READ_PHONE_STATE)
        val readPhoneNumbers = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) hasPermission(Manifest.permission.READ_PHONE_NUMBERS) else true
        val answerPhoneCalls = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) hasPermission(Manifest.permission.ANSWER_PHONE_CALLS) else true
        val callPhone = hasPermission(Manifest.permission.CALL_PHONE)
        val readCallLog = hasPermission(Manifest.permission.READ_CALL_LOG)
        val defaultDialer = isDefaultDialer()
        val callScreeningRole = isCallScreeningRoleHeld()
        val hybridReady = readPhoneState && readPhoneNumbers && answerPhoneCalls && callPhone
        return mapOf(
            "canDrawOverlays" to Settings.canDrawOverlays(context),
            "accessibilityEnabled" to isAccessibilityEnabled(),
            "notificationsGranted" to canPostNotifications(),
            "recordAudioGranted" to hasRecordAudioPermission(),
            "defaultDialerGranted" to defaultDialer,
            "callScreeningRoleGranted" to callScreeningRole,
            "readPhoneStateGranted" to readPhoneState,
            "readPhoneNumbersGranted" to readPhoneNumbers,
            "readCallLogGranted" to readCallLog,
            "answerPhoneCallsGranted" to answerPhoneCalls,
            "callPhoneGranted" to callPhone,
            "hybridCallControlReady" to hybridReady,
            "fullTelecomAutomationReady" to (hybridReady && defaultDialer && readCallLog),
            "managedCallSupportReady" to (hybridReady && (defaultDialer || callScreeningRole)),
        )
    }

    private fun safeStartActivity(intent: Intent): Boolean {
        return try {
            context.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: Throwable) {
            false
        }
    }

    private fun tryStartActivityForResult(host: Activity, intent: Intent, requestCode: Int): Boolean {
        return try {
            host.startActivityForResult(intent, requestCode)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: Throwable) {
            false
        }
    }

    private fun isAccessibilityEnabled(): Boolean {
        val expectedService =
            "${context.packageName}/${NovaAccessibilityService::class.java.name}"

        val enabledServices = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false

        return enabledServices.contains(expectedService, ignoreCase = true)
    }

    private fun isDefaultDialer(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = context.getSystemService(RoleManager::class.java)
                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_DIALER)) {
                    if (roleManager.isRoleHeld(RoleManager.ROLE_DIALER)) {
                        return true
                    }
                }
            }
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            telecomManager?.defaultDialerPackage == context.packageName
        } catch (_: Throwable) {
            false
        }
    }


    private fun requestCallScreeningRole(host: Activity): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = context.getSystemService(RoleManager::class.java)
                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                    if (roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
                        return true
                    }
                    val roleIntent = roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING)
                    host.startActivityForResult(roleIntent, 4315)
                    return true
                }
            }
            false
        } catch (_: Throwable) {
            false
        }
    }

    private fun isCallScreeningRoleHeld(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val roleManager = context.getSystemService(RoleManager::class.java)
                if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                    return roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)
                }
            }
            false
        } catch (_: Throwable) {
            false
        }
    }

    private fun canPostNotifications(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.areNotificationsEnabled()
        }
    }
}
