package com.example.nova

import android.content.Context
import android.media.AudioManager

object NovaAudioInputPolicy {

    private val lock = Any()

    private var passiveListeningCount = 0
    private var callCompanionListeningCount = 0

    private var previousMode: Int? = null
    private var previousSpeakerphoneOn: Boolean? = null
    private var previousMicrophoneMute: Boolean? = null

    fun beginPassiveListening(context: Context): Map<String, Any> {
        synchronized(lock) {
            val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            snapshotIfNeeded(manager)

            passiveListeningCount += 1

            if (callCompanionListeningCount == 0 && manager.mode != AudioManager.MODE_NORMAL) {
                manager.mode = AudioManager.MODE_NORMAL
            }

            return buildResult(
                success = true,
                message = "Pasif dinleme politikası etkin.",
                manager = manager
            )
        }
    }

    fun endPassiveListening(context: Context): Map<String, Any> {
        synchronized(lock) {
            val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

            if (passiveListeningCount > 0) {
                passiveListeningCount -= 1
            }

            if (callCompanionListeningCount == 0 && passiveListeningCount == 0) {
                restore(manager)
            }

            return buildResult(
                success = true,
                message = "Pasif dinleme politikası sonlandırıldı.",
                manager = manager
            )
        }
    }

    fun beginCallCompanionListening(context: Context): Map<String, Any> {
        synchronized(lock) {
            val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            snapshotIfNeeded(manager)

            callCompanionListeningCount += 1

            if (manager.mode != AudioManager.MODE_IN_COMMUNICATION) {
                manager.mode = AudioManager.MODE_IN_COMMUNICATION
            }

            return buildResult(
                success = true,
                message = "Çağrı companion giriş politikası etkin.",
                manager = manager
            )
        }
    }

    fun endCallCompanionListening(context: Context): Map<String, Any> {
        synchronized(lock) {
            val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

            if (callCompanionListeningCount > 0) {
                callCompanionListeningCount -= 1
            }

            if (callCompanionListeningCount == 0 && passiveListeningCount == 0) {
                restore(manager)
            } else if (callCompanionListeningCount == 0 && passiveListeningCount > 0) {
                manager.mode = AudioManager.MODE_NORMAL
            }

            return buildResult(
                success = true,
                message = "Çağrı companion giriş politikası sonlandırıldı.",
                manager = manager
            )
        }
    }

    fun endListeningSession(context: Context): Map<String, Any> {
        synchronized(lock) {
            return when {
                passiveListeningCount > 0 && callCompanionListeningCount == 0 -> {
                    endPassiveListening(context)
                }
                callCompanionListeningCount > 0 && passiveListeningCount == 0 -> {
                    endCallCompanionListening(context)
                }
                passiveListeningCount == 0 && callCompanionListeningCount == 0 -> {
                    val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    buildResult(
                        success = true,
                        message = "Aktif dinleme oturumu yoktu.",
                        manager = manager
                    )
                }
                else -> {
                    val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    buildResult(
                        success = false,
                        message = "Belirsiz session kapanışı engellendi. Explicit end kullanılmalı.",
                        manager = manager
                    )
                }
            }
        }
    }

    fun getState(context: Context): Map<String, Any> {
        synchronized(lock) {
            val manager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            return buildResult(
                success = true,
                message = "Ses giriş politikası durumu hazır.",
                manager = manager
            )
        }
    }

    private fun snapshotIfNeeded(manager: AudioManager) {
        if (previousMode == null) {
            previousMode = manager.mode
        }
        if (previousSpeakerphoneOn == null) {
            @Suppress("DEPRECATION")
            run {
                previousSpeakerphoneOn = manager.isSpeakerphoneOn
            }
        }
        if (previousMicrophoneMute == null) {
            @Suppress("DEPRECATION")
            run {
                previousMicrophoneMute = manager.isMicrophoneMute
            }
        }
    }

    private fun restore(manager: AudioManager) {
        previousMode?.let { manager.mode = it }

        @Suppress("DEPRECATION")
        previousSpeakerphoneOn?.let { manager.isSpeakerphoneOn = it }

        @Suppress("DEPRECATION")
        previousMicrophoneMute?.let { manager.isMicrophoneMute = it }

        previousMode = null
        previousSpeakerphoneOn = null
        previousMicrophoneMute = null
    }

    private fun buildResult(
        success: Boolean,
        message: String,
        manager: AudioManager,
    ): Map<String, Any> {
        @Suppress("DEPRECATION")
        val speakerOn = manager.isSpeakerphoneOn

        @Suppress("DEPRECATION")
        val microphoneMute = manager.isMicrophoneMute

        return mapOf(
            "success" to success,
            "message" to message,
            "mode" to manager.mode,
            "passiveListeningCount" to passiveListeningCount,
            "callCompanionListeningCount" to callCompanionListeningCount,
            "speakerOn" to speakerOn,
            "microphoneMute" to microphoneMute,
            "protectsMediaPlayback" to true,
            "requestsAudioFocus" to false,
        )
    }
}