package com.example.nova

import org.json.JSONArray
import org.json.JSONObject

object NovaReminderJsonParser {
    fun parsePendingReminderMaps(raw: String): List<Map<String, Any?>> {
        return try {
            val array = JSONArray(raw)
            val result = mutableListOf<Map<String, Any?>>()

            for (i in 0 until array.length()) {
                val obj = array.optJSONObject(i) ?: continue
                val item = mutableMapOf<String, Any?>()
                item["id"] = obj.optString("id", "")
                item["text"] = obj.optString("text", "")
                item["dueAtIso"] = obj.optString("dueAtIso", "")
                item["isCompleted"] = obj.optBoolean("isCompleted", false)
                item["isWakeAlarm"] = obj.optBoolean("isWakeAlarm", false)
                result.add(item)
            }

            result
        } catch (_: Throwable) {
            emptyList()
        }
    }
}
