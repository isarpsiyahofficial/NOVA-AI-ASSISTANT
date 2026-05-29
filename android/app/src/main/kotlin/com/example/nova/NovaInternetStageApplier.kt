package com.example.nova

import android.content.Context

// NOVA_API_FIRST_INTERNET_STAGE_PASSIVE_V1
object NovaInternetStageApplier {
    fun applyRestrict(context: Context, reason: String) = Unit
    fun applyQuarantine(context: Context, reason: String) = Unit
    fun applyMemoryReset(context: Context, reason: String) = Unit
    fun applyClusterRestart(context: Context, reason: String) = Unit
    fun applySafeDecommission(context: Context, reason: String) = Unit
    fun applyFinalDestroy(context: Context, reason: String) = Unit
    fun enforceStoredState(context: Context) = Unit
}
