package com.example.nova

import android.content.Context
import android.net.Uri
import android.provider.ContactsContract

object NovaCallContactResolver {
    fun resolveDisplayName(context: Context, rawNumber: String?, telecomDisplayName: String? = null): String {
        val telecom = telecomDisplayName?.trim().orEmpty()
        if (telecom.isUsefulName(rawNumber)) return telecom
        val novaLabel = runCatching { NovaAuthorizedCallRegistry.displayNameForNumber(context, rawNumber) }.getOrNull()?.trim().orEmpty()
        if (novaLabel.isUsefulName(rawNumber)) return novaLabel
        val contactLabel = lookupDeviceContactName(context, rawNumber).trim()
        if (contactLabel.isUsefulName(rawNumber)) return contactLabel
        return normalizeForDisplay(rawNumber)
    }

    private fun lookupDeviceContactName(context: Context, rawNumber: String?): String {
        val normalized = normalizeForLookup(rawNumber)
        if (normalized.isBlank()) return ""
        val uri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(normalized))
        val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME_PRIMARY)
        return runCatching {
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) cursor.getString(0).orEmpty() else ""
            }.orEmpty()
        }.getOrDefault("")
    }

    private fun String.isUsefulName(rawNumber: String?): Boolean {
        val value = trim()
        if (value.isBlank()) return false
        val normalizedValue = normalizeForLookup(value)
        val normalizedNumber = normalizeForLookup(rawNumber)
        if (normalizedNumber.isNotBlank() && normalizedValue == normalizedNumber) return false
        return value.any { it.isLetter() }
    }

    private fun normalizeForDisplay(rawNumber: String?): String = normalizeForLookup(rawNumber).ifBlank { rawNumber?.trim().orEmpty() }

    private fun normalizeForLookup(rawNumber: String?): String {
        val raw = rawNumber?.trim().orEmpty()
        if (raw.isBlank()) return ""
        val out = StringBuilder()
        var plusUsed = false
        raw.forEachIndexed { index, c ->
            when {
                c == '+' && !plusUsed && index == 0 -> { plusUsed = true; out.append(c) }
                c.isDigit() -> out.append(c)
            }
        }
        var normalized = out.toString()
        if (normalized.startsWith("00")) normalized = "+" + normalized.substring(2)
        if (normalized.length == 10) normalized = "+90" + normalized
        if (normalized.length == 11 && normalized.startsWith("0")) normalized = "+90" + normalized.substring(1)
        return normalized
    }
}
