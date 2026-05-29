package com.example.nova

import android.content.Context
import org.json.JSONArray

object NovaAuthorizedCallRegistry {
    private const val PREF_FILE = "FlutterSharedPreferences"
    private const val CONTACTS_KEY = "flutter.nova_contacts_v1"

    fun isAuthorizedCallHandlingNumber(context: Context, rawNumber: String?): Boolean {
        val number = normalize(rawNumber)
        if (number.isEmpty()) return false
        return loadAuthorizedNumbers(context).contains(number)
    }

    fun loadAuthorizedNumbers(context: Context): Set<String> {
        return try {
            val prefs = context.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
            val raw = prefs.getString(CONTACTS_KEY, "").orEmpty().trim()
            if (raw.isEmpty()) return emptySet()
            val arr = JSONArray(raw)
            buildSet {
                for (i in 0 until arr.length()) {
                    val item = arr.optJSONObject(i) ?: continue
                    val canHandle = item.optBoolean("canReceiveAutoCallHandling", item.optBoolean("allowsCallHandling", false))
                    if (!canHandle) continue
                    val normalized = normalize(item.optString("phoneNumber", ""))
                    if (normalized.isNotEmpty()) add(normalized)
                }
            }
        } catch (_: Throwable) {
            emptySet()
        }
    }

    fun displayNameForNumber(context: Context, rawNumber: String?): String {
        val number = normalize(rawNumber)
        if (number.isEmpty()) return ""
        return try {
            val prefs = context.getSharedPreferences(PREF_FILE, Context.MODE_PRIVATE)
            val raw = prefs.getString(CONTACTS_KEY, "").orEmpty().trim()
            if (raw.isEmpty()) return ""
            val arr = JSONArray(raw)
            for (i in 0 until arr.length()) {
                val item = arr.optJSONObject(i) ?: continue
                val normalized = normalize(item.optString("phoneNumber", ""))
                if (normalized != number) continue
                val candidates = listOf(
                    item.optString("displayName", ""),
                    item.optString("name", ""),
                    item.optString("fullName", ""),
                    item.optString("label", "")
                )
                val label = candidates.firstOrNull { it.trim().isNotEmpty() }.orEmpty().trim()
                if (label.isNotEmpty()) return label
            }
            ""
        } catch (_: Throwable) {
            ""
        }
    }

    fun normalize(value: String?): String {
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
        if (normalized.startsWith("00")) normalized = "+" + normalized.substring(2)
        if (normalized.length == 10) normalized = "+90$normalized"
        else if (normalized.length == 11 && normalized.startsWith("0")) normalized = "+90${normalized.substring(1)}"
        return normalized
    }
}
