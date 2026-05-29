package com.example.nova

import android.content.Intent

object NovaMediaProjectionState {

    data class Consent(
        val resultCode: Int,
        val dataIntent: Intent
    )

    @Volatile
    private var grantedConsent: Consent? = null

    fun setPendingConsent(resultCode: Int, dataIntent: Intent) {
        grantedConsent = Consent(resultCode, dataIntent)
    }

    fun consumePendingConsent(): Consent? = grantedConsent

    fun peekGrantedConsent(): Consent? = grantedConsent

    fun hasPendingConsent(): Boolean = grantedConsent != null

    fun clear() {
        grantedConsent = null
    }
}
