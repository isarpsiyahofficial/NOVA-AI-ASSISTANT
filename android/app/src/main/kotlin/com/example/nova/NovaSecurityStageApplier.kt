package com.example.nova

import android.content.Context

// NOVA_API_FIRST_SECURITY_STAGE_PASSIVE_V1
object NovaSecurityStageApplier {
    fun applyRestrict(context: Context, reason: String) = Unit
    fun applyRevoke(context: Context, reason: String) = Unit
    fun applyQuarantine(context: Context, reason: String) = Unit
    fun applyRuntimeIsolate(context: Context, reason: String) = Unit
    fun applyBlackout(context: Context, reason: String) = Unit
    fun applyHardKill(context: Context, reason: String) = Unit
    fun applyRevivalBlock(context: Context, reason: String) = Unit
    fun applySafeDecommission(context: Context, reason: String) = Unit
    fun applyFinalDestroy(context: Context, reason: String) = Unit
    fun enforceStoredState(context: Context) = Unit
}
