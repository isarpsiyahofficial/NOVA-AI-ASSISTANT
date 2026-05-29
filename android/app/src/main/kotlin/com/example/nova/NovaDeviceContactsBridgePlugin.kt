package com.example.nova

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.ContactsContract
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaDeviceContactsBridgePlugin(
    private val context: Context,
    private val activity: Activity?,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "nova/device_contacts_bridge"

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
                NovaDeviceContactsBridgePlugin(
                    context = context,
                    activity = activity,
                )
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getContactsPermissionStatus" -> {
                    result.success(buildPermissionResult())
                }

                "requestContactsPermission" -> {
                    val current = buildPermissionResult()
                    if (current["granted"] == true) {
                        result.success(current)
                        return
                    }

                    val localActivity = activity
                    if (localActivity == null) {
                        result.success(
                            mapOf(
                                "granted" to false,
                                "permanentlyDenied" to false,
                                "message" to "Activity hazır değil, kişi izni istenemedi."
                            )
                        )
                        return
                    }

                    ActivityCompat.requestPermissions(
                        localActivity,
                        arrayOf(Manifest.permission.READ_CONTACTS),
                        9931
                    )

                    result.success(buildPermissionResult())
                }

                "openAppSettings" -> {
                    val intent = Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.fromParts("package", context.packageName, null)
                    ).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    context.startActivity(intent)
                    result.success(true)
                }

                "fetchDeviceContacts" -> {
                    if (!hasReadContactsPermission()) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "contacts" to emptyList<Map<String, Any?>>(),
                                "message" to "Kişi izni verilmedi."
                            )
                        )
                        return
                    }

                    result.success(
                        mapOf(
                            "success" to true,
                            "contacts" to readContacts(),
                            "message" to "Telefon kişileri alındı."
                        )
                    )
                }

                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.success(
                mapOf(
                    "success" to false,
                    "contacts" to emptyList<Map<String, Any?>>(),
                    "granted" to false,
                    "permanentlyDenied" to false,
                    "message" to "Kişi köprüsü hatası: ${t.message ?: "unknown"}"
                )
            )
        }
    }

    private fun buildPermissionResult(): Map<String, Any> {
        val granted = hasReadContactsPermission()
        val permanentlyDenied = if (activity != null && !granted) {
            !ActivityCompat.shouldShowRequestPermissionRationale(
                activity,
                Manifest.permission.READ_CONTACTS
            )
        } else {
            false
        }

        return mapOf(
            "granted" to granted,
            "permanentlyDenied" to permanentlyDenied,
            "message" to if (granted) {
                "Kişi izni hazır."
            } else {
                "Kişi izni kapalı."
            }
        )
    }

    private fun hasReadContactsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CONTACTS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun readContacts(): List<Map<String, Any?>> {
        val resolver = context.contentResolver
        val seenPhones = LinkedHashSet<String>()
        val results = ArrayList<Map<String, Any?>>()

        val projection = arrayOf(
            ContactsContract.CommonDataKinds.Phone.CONTACT_ID,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
            ContactsContract.CommonDataKinds.Phone.NUMBER
        )

        resolver.query(
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
            projection,
            null,
            null,
            ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " ASC"
        )?.use { cursor ->
            val idIndex =
                cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.CONTACT_ID)
            val nameIndex =
                cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME)
            val numberIndex =
                cursor.getColumnIndex(ContactsContract.CommonDataKinds.Phone.NUMBER)

            while (cursor.moveToNext()) {
                val contactId =
                    if (idIndex >= 0) cursor.getString(idIndex).orEmpty() else ""
                val displayName =
                    if (nameIndex >= 0) cursor.getString(nameIndex).orEmpty() else ""
                val rawNumber =
                    if (numberIndex >= 0) cursor.getString(numberIndex).orEmpty() else ""

                val normalizedNumber = normalizePhone(rawNumber)

                if (displayName.trim().isEmpty() || normalizedNumber.isEmpty()) {
                    continue
                }

                if (!seenPhones.add(normalizedNumber)) {
                    continue
                }

                results.add(
                    mapOf(
                        "id" to if (contactId.isBlank()) normalizedNumber else contactId,
                        "displayName" to displayName.trim(),
                        "phoneNumber" to normalizedNumber
                    )
                )
            }
        }

        return results
    }

    private fun normalizePhone(value: String?): String {
        val raw = value?.trim().orEmpty()
        if (raw.isEmpty()) return ""

        val builder = StringBuilder()
        var hasPlus = false

        raw.forEachIndexed { index, c ->
            when {
                c == '+' && !hasPlus && index == 0 -> {
                    hasPlus = true
                    builder.append(c)
                }
                c.isDigit() -> builder.append(c)
            }
        }

        var normalized = builder.toString()
        if (normalized.startsWith("00")) {
            normalized = "+" + normalized.substring(2)
        }

        if (normalized.startsWith("+90") && normalized.length == 13) {
            return normalized
        }

        if (normalized.length == 10) {
            return "+90$normalized"
        }

        if (normalized.length == 11 && normalized.startsWith("0")) {
            return "+90${normalized.substring(1)}"
        }

        return normalized
    }
}