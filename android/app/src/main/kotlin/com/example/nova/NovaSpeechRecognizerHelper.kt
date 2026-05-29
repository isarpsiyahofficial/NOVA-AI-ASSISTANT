package com.example.nova

import android.Manifest
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager

class NovaSpeechRecognizerHelper(
    private val context: Context
) {

    interface Callback {
        fun onResult(success: Boolean, text: String, locale: String, message: String)
    }

    fun transcribeTurkishOnce(
        mode: String,
        maxDurationSeconds: Int,
        callback: Callback
    ) {
        if (ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.RECORD_AUDIO
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            callback.onResult(false, "", "tr-TR", "Mikrofon izni verilmedi.")
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            callback.onResult(false, "", "tr-TR", "SpeechRecognizer kullanılamıyor.")
            return
        }

        val recognizer = NovaSpeechSessionManager.acquire(context)
        if (recognizer == null) {
            callback.onResult(false, "", "tr-TR", "SpeechRecognizer başlatılamadı.")
            return
        }
        val normalizedMode = mode.trim().ifBlank { "normalCommandListening" }
        val handler = Handler(Looper.getMainLooper())
        var completed = false
        var bestEffortPartial = ""

        fun finish(success: Boolean, text: String, locale: String, message: String) {
            if (completed) return
            completed = true

            handler.removeCallbacksAndMessages(null)

            try {
                recognizer.cancel()
            } catch (_: Throwable) {
            }

            NovaSpeechSessionManager.touch()
            NovaSpeechSessionManager.releaseSoft()
            callback.onResult(success, text, locale, message)
        }

        recognizer.setRecognitionListener(object : RecognitionListener {
            private var heardSpeech = false
            private var bestPartial = ""

            override fun onReadyForSpeech(params: Bundle?) = Unit

            override fun onBeginningOfSpeech() {
                heardSpeech = true
            }

            override fun onRmsChanged(rmsdB: Float) {
                if (rmsdB > -38f) {
                    heardSpeech = true
                    if (bestPartial.isBlank() && bestEffortPartial.isNotBlank()) {
                        bestPartial = bestEffortPartial
                    }
                }
            }

            override fun onBufferReceived(buffer: ByteArray?) = Unit
            override fun onEndOfSpeech() {
                if (bestPartial.isNotBlank()) {
                    handler.postDelayed({
                        finish(true, bestPartial.trim(), "tr-TR", "Konuşma kısmi sonuçla tamamlandı.")
                    }, if (normalizedMode == "normalCommandListening") 900 else 600)
                }
            }

            override fun onError(error: Int) {
                val message = when (error) {
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "Mikrofon izni eksik ya da Android izin zinciri tamamlanmadı."
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT,
                    SpeechRecognizer.ERROR_NO_MATCH -> if (bestPartial.isNotBlank()) {
                        finish(true, bestPartial.trim(), "tr-TR", "Kısmi sonuç döndürüldü.")
                        return
                    } else {
                        "Ses algılanamadı. Biraz daha doğal ve net konuşun."
                    }
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> if (bestEffortPartial.isNotBlank()) {
                        finish(true, bestEffortPartial.trim(), "tr-TR", "Motor meşguldü; son kısmi sonuç döndürüldü.")
                        return
                    } else {
                        "Ses tanıma motoru meşgul. Kısa süre sonra tekrar deneyin."
                    }
                    SpeechRecognizer.ERROR_NETWORK,
                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> if (bestEffortPartial.isNotBlank()) {
                        finish(true, bestEffortPartial.trim(), "tr-TR", "Ağ kesildi; son kısmi sonuç döndürüldü.")
                        return
                    } else {
                        "Ses tanıma ağı zaman aşımına uğradı."
                    }
                    else -> if (heardSpeech) {
                        "Konuşma tamamlanamadı. STT hata kodu: $error"
                    } else {
                        "Ses algılanamadı. STT hata kodu: $error"
                    }
                }
                finish(false, "", "tr-TR", message)
            }

            override fun onResults(results: Bundle?) {
                val list = results
                    ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    ?.map { normalizeTranscript(it) }
                    ?.filter { it.isNotBlank() }
                    .orEmpty()

                val best = chooseBestResult(list, bestPartial).trim()
                if (best.isEmpty()) {
                    if (bestPartial.isNotBlank()) {
                        finish(true, bestPartial.trim(), "tr-TR", "Kısmi sonuç döndürüldü.")
                        return
                    }
                    finish(false, "", "tr-TR", "Herhangi bir metin algılanamadı.")
                    return
                }

                finish(true, best, "tr-TR", "Tamam")
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val partial = chooseBestResult(
                    partialResults
                        ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        ?.map { normalizeTranscript(it) }
                        ?.filter { it.isNotBlank() }
                        .orEmpty(),
                    bestPartial,
                ).trim()
                if (partial.isNotBlank()) {
                    heardSpeech = true
                    bestPartial = partial
                    bestEffortPartial = partial
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) = Unit
        })

        val boundedSeconds = maxDurationSeconds.coerceIn(10, 60)
        val longConversationMode = normalizedMode == "normalCommandListening"
        val silenceMs = if (longConversationMode) {
            ((boundedSeconds * 1000L) / 4).coerceIn(2600L, 7000L)
        } else {
            ((boundedSeconds * 1000L) / 5).coerceIn(1400L, 3600L)
        }

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "tr-TR")
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, "tr-TR")
            putExtra(RecognizerIntent.EXTRA_ONLY_RETURN_LANGUAGE_PREFERENCE, "tr-TR")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_ENABLE_LANGUAGE_DETECTION, false)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
                putExtra(RecognizerIntent.EXTRA_ENABLE_FORMATTING, RecognizerIntent.FORMATTING_OPTIMIZE_LATENCY)
                putExtra(RecognizerIntent.EXTRA_HIDE_PARTIAL_TRAILING_PUNCTUATION, true)
            }
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                putExtra(RecognizerIntent.EXTRA_REQUEST_WORD_CONFIDENCE, true)
                putExtra(RecognizerIntent.EXTRA_REQUEST_WORD_TIMING, true)
            }
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, if (longConversationMode) 5 else 3)
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM
            )
            putExtra(
                RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS,
                silenceMs
            )
            putExtra(
                RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS,
                silenceMs / 2
            )
            putExtra(
                RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS,
                if (longConversationMode) 1800L else 1000L
            )
            putExtra(RecognizerIntent.EXTRA_PROMPT, "Nova sizi dinliyor")
        }

        handler.postDelayed(
            {
                if (completed) return@postDelayed
                if (bestEffortPartial.isNotBlank()) {
                    finish(true, bestEffortPartial.trim(), "tr-TR", "Uzun dinleme sonunda kısmi sonuç döndürüldü.")
                } else {
                    finish(false, "", "tr-TR", "STT zaman aşımına uğradı.")
                }
            },
            boundedSeconds * 1000L + 2500L
        )

        NovaSpeechSessionManager.touch()
        recognizer.startListening(intent)
    }

    private fun chooseBestResult(candidates: List<String>, fallback: String = ""): String {
        if (candidates.isEmpty()) return normalizeTranscript(fallback)
        val preferred = candidates.firstOrNull { looksLikeUsefulSpeech(it) }
        if (preferred != null) return preferred
        return candidates.firstOrNull { it.isNotBlank() }?.trim().orEmpty()
    }

    private fun looksLikeUsefulSpeech(value: String): Boolean {
        val text = normalizeTranscript(value)
        if (text.isBlank()) return false
        if (text.length <= 1) return false
        val blocked = setOf("ay", "ee", "ıı", "hı", "hm")
        if (blocked.contains(text.lowercase())) return false
        val letters = text.count { it.isLetter() }
        return letters >= 2
    }

    private fun normalizeTranscript(value: String): String {
        return value
            .replace(Regex("\\s+"), " ")
            .trim()
            .trim(',', '.', ';', ':')
    }
}
