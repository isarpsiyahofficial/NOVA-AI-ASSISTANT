package com.example.nova

import java.time.OffsetDateTime
import java.time.format.DateTimeParseException

object NovaReminderTimeParser {
    fun parseIsoToEpochMillis(value: String): Long {
        return try {
            OffsetDateTime.parse(value).toInstant().toEpochMilli()
        } catch (_: DateTimeParseException) {
            0L
        }
    }
}
