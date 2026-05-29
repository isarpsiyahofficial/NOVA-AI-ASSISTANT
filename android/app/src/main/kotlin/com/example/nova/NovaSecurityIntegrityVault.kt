package com.example.nova

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.util.Base64
import java.nio.charset.StandardCharsets
import javax.crypto.KeyGenerator
import javax.crypto.Mac

class NovaSecurityIntegrityVault(
    private val context: Context,
) {
    companion object {
        private const val KEYSTORE = "AndroidKeyStore"
        private const val ALIAS = "nova_security_integrity_hmac_v1"
    }

    private fun ensureKey() {
        val ks = java.security.KeyStore.getInstance(KEYSTORE).apply { load(null) }
        if (ks.containsAlias(ALIAS)) return
        val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA256, KEYSTORE)
        val spec = KeyGenParameterSpec.Builder(
            ALIAS,
            KeyProperties.PURPOSE_SIGN or KeyProperties.PURPOSE_VERIFY
        ).setDigests(KeyProperties.DIGEST_SHA256)
            .build()
        keyGenerator.init(spec)
        keyGenerator.generateKey()
    }

    fun sign(value: String): String {
        ensureKey()
        val ks = java.security.KeyStore.getInstance(KEYSTORE).apply { load(null) }
        val secretKey = ks.getKey(ALIAS, null) as javax.crypto.SecretKey
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(secretKey)
        val out = mac.doFinal(value.toByteArray(StandardCharsets.UTF_8))
        return Base64.encodeToString(out, Base64.NO_WRAP)
    }

    fun verify(value: String, signature: String?): Boolean {
        if (signature.isNullOrBlank()) return false
        return try {
            sign(value) == signature
        } catch (_: Throwable) {
            false
        }
    }
}
