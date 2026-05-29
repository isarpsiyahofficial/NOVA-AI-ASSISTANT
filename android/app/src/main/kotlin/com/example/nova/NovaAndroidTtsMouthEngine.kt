package com.example.nova

import android.content.Context
import android.media.AudioAttributes
import android.os.Bundle
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import android.speech.tts.Voice
import android.util.Log
import java.util.Locale
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

object NovaAndroidTtsMouthEngine {
    private const val TAG = "NovaAndroidTtsMouth"
    private const val DEFAULT_WAIT_MS = 45_000L

    @Volatile private var tts: TextToSpeech? = null
    @Volatile private var initialized: Boolean = false
    @Volatile private var initializing: Boolean = false
    @Volatile private var selectedVoiceName: String = ""
    @Volatile private var selectedVoiceLocale: String = ""
    @Volatile private var lastMessage: String = "Android/Google TTS mouth henüz başlatılmadı."

    @Synchronized
    fun warmup(context: Context, language: String = "tr-TR", preferFemale: Boolean = true): Boolean {
        if (initialized && tts != null) {
            return configureVoice(language = language, preferFemale = preferFemale)
        }

        if (initializing) {
            waitUntilReady()
            return initialized && configureVoice(language = language, preferFemale = preferFemale)
        }

        initializing = true
        val latch = CountDownLatch(1)
        val appContext = context.applicationContext
        try {
            var engine: TextToSpeech? = null
            engine = TextToSpeech(appContext) { status ->
                initialized = status == TextToSpeech.SUCCESS
                lastMessage = if (initialized) {
                    "Android/Google TTS mouth hazır."
                } else {
                    "Android/Google TTS başlatılamadı. status=$status"
                }
                tts = engine
                initializing = false
                latch.countDown()
            }
            tts = engine
            latch.await(8, TimeUnit.SECONDS)
        } catch (t: Throwable) {
            initializing = false
            initialized = false
            lastMessage = t.message ?: "Android/Google TTS warmup hatası."
            Log.e(TAG, "warmup failed", t)
            return false
        }

        return initialized && configureVoice(language = language, preferFemale = preferFemale)
    }

    private fun waitUntilReady(): Boolean {
        val started = System.currentTimeMillis()
        while (initializing && System.currentTimeMillis() - started < 8_000L) {
            try {
                Thread.sleep(40L)
            } catch (_: InterruptedException) {
                return false
            }
        }
        return initialized
    }

    @Synchronized
    fun configureVoice(language: String = "tr-TR", preferFemale: Boolean = true): Boolean {
        val engine = tts ?: return false
        val locale = localeFrom(language)
        try {
            val languageResult = engine.setLanguage(locale)
            if (languageResult == TextToSpeech.LANG_MISSING_DATA ||
                languageResult == TextToSpeech.LANG_NOT_SUPPORTED
            ) {
                lastMessage = "Türkçe TTS dili cihazda desteklenmiyor veya veri eksik."
                Log.w(TAG, lastMessage)
                return false
            }

            engine.setAudioAttributes(
                AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ASSISTANCE_ACCESSIBILITY)
                    .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                    .build()
            )

            val voice = chooseBestVoice(engine.voices, locale, preferFemale)
            if (voice != null) {
                try {
                    engine.voice = voice
                    selectedVoiceName = voice.name.orEmpty()
                    selectedVoiceLocale = voice.locale?.toLanguageTag().orEmpty()
                    lastMessage = if (isFemaleLike(selectedVoiceName)) {
                        "Kadın/insancıl Türkçe Android TTS mouth seçildi: $selectedVoiceName"
                    } else {
                        "Cinsiyeti belirsiz ama Türkçe Android TTS mouth seçildi: $selectedVoiceName"
                    }
                    Log.i(TAG, lastMessage)
                } catch (t: Throwable) {
                    lastMessage = "TTS voice set edilemedi; platform default Türkçe kullanılacak. ${t.message.orEmpty()}"
                    Log.w(TAG, lastMessage)
                }
            } else {
                selectedVoiceName = "platform_default_tr_TR_unverified_gender"
                selectedVoiceLocale = locale.toLanguageTag()
                lastMessage = "Voice listesi güvenli seçim vermedi; platform default Türkçe mouth kullanılacak."
                Log.w(TAG, lastMessage)
            }

            return true
        } catch (t: Throwable) {
            lastMessage = t.message ?: "Android/Google TTS voice yapılandırması başarısız."
            Log.e(TAG, "configureVoice failed", t)
            return false
        }
    }

    fun speak(
        context: Context,
        text: String,
        language: String = "tr-TR",
        preferFemale: Boolean = true,
        allowUnknownGenderTurkish: Boolean = true,
        speechRate: Float = 0.96f,
        pitch: Float = 1.03f,
        waitForDone: Boolean = true,
    ): Boolean {
        val prepared = text.trim()
        if (prepared.isEmpty()) {
            lastMessage = "Boş metin konuşulmadı."
            return false
        }

        if (!warmup(context, language, preferFemale)) {
            return false
        }

        val engine = tts ?: return false
        if (!allowUnknownGenderTurkish && selectedVoiceName.contains("unverified", ignoreCase = true)) {
            lastMessage = "Cinsiyeti belirsiz Türkçe TTS owner policy nedeniyle konuşmadı."
            return false
        }

        return try {
            engine.setSpeechRate(speechRate.coerceIn(0.75f, 1.15f))
            engine.setPitch(pitch.coerceIn(0.88f, 1.16f))

            val done = CountDownLatch(1)
            val ok = AtomicBoolean(false)
            val failed = AtomicBoolean(false)
            val utteranceId = "nova_mouth_${UUID.randomUUID()}"

            engine.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                override fun onStart(utteranceId: String?) {
                    ok.set(true)
                    Log.i(TAG, "speak started id=$utteranceId voice=$selectedVoiceName")
                }

                override fun onDone(utteranceId: String?) {
                    ok.set(true)
                    done.countDown()
                    Log.i(TAG, "speak done id=$utteranceId")
                }

                @Deprecated("Deprecated in Java")
                override fun onError(utteranceId: String?) {
                    failed.set(true)
                    done.countDown()
                    Log.e(TAG, "speak error id=$utteranceId")
                }

                override fun onError(utteranceId: String?, errorCode: Int) {
                    failed.set(true)
                    done.countDown()
                    Log.e(TAG, "speak error id=$utteranceId code=$errorCode")
                }
            })

            val params = Bundle()
            val queued = engine.speak(prepared, TextToSpeech.QUEUE_FLUSH, params, utteranceId)
            if (queued != TextToSpeech.SUCCESS) {
                lastMessage = "Android/Google TTS speak kuyruğa alınamadı. result=$queued"
                return false
            }

            if (!waitForDone) {
                lastMessage = "Android/Google TTS konuşma başlatıldı."
                return true
            }

            val waitMs = (2_500L + prepared.length * 85L).coerceIn(6_000L, DEFAULT_WAIT_MS)
            done.await(waitMs, TimeUnit.MILLISECONDS)
            val success = ok.get() && !failed.get()
            lastMessage = if (success) {
                "Android/Google TTS konuşma tamamlandı."
            } else {
                "Android/Google TTS konuşma tamamlanamadı veya callback dönmedi."
            }
            success
        } catch (t: Throwable) {
            lastMessage = t.message ?: "Android/Google TTS konuşma hatası."
            Log.e(TAG, "speak failed", t)
            false
        }
    }

    fun stop(): Boolean {
        return try {
            tts?.stop()
            lastMessage = "Android/Google TTS mouth durduruldu."
            true
        } catch (t: Throwable) {
            lastMessage = t.message ?: "Android/Google TTS stop hatası."
            false
        }
    }

    fun debugState(): Map<String, Any> = linkedMapOf(
        "ready" to (initialized && tts != null),
        "initializing" to initializing,
        "selectedVoiceName" to selectedVoiceName,
        "selectedVoiceLocale" to selectedVoiceLocale,
        "message" to lastMessage,
    )

    private fun chooseBestVoice(voices: Set<Voice>?, targetLocale: Locale, preferFemale: Boolean): Voice? {
        if (voices.isNullOrEmpty()) return null

        var best: Voice? = null
        var bestScore = Int.MIN_VALUE

        for (voice in voices) {
            val name = voice.name.orEmpty()
            val locale = voice.locale ?: continue
            val localeMatches = locale.language.equals(targetLocale.language, ignoreCase = true) ||
                name.contains("tr-tr", ignoreCase = true) ||
                name.contains("turkish", ignoreCase = true) ||
                name.contains("turk", ignoreCase = true)
            if (!localeMatches) continue

            val female = isFemaleLike(name)
            val male = isMaleLike(name)

            if (male && !female) {
                Log.i(TAG, "skipped male/default-like voice=$name locale=${locale.toLanguageTag()}")
                continue
            }

            var score = 0
            if (locale.toLanguageTag().equals(targetLocale.toLanguageTag(), ignoreCase = true)) score += 1000
            if (locale.language.equals(targetLocale.language, ignoreCase = true)) score += 450
            if (name.contains("google", ignoreCase = true)) score += 150
            if (preferFemale && female) score += 700
            if (!female && !male) score += 120
            if (voice.isNetworkConnectionRequired) score -= 160
            score += voice.quality
            score -= voice.latency / 3

            if (score > bestScore) {
                bestScore = score
                best = voice
            }
        }

        return best
    }

    private fun localeFrom(language: String): Locale {
        val normalized = language.trim().replace('_', '-').lowercase(Locale.ROOT)
        return when {
            normalized.startsWith("tr") -> Locale("tr", "TR")
            normalized.startsWith("en") -> Locale.US
            else -> Locale("tr", "TR")
        }
    }

    private fun isFemaleLike(name: String): Boolean {
        val lower = name.lowercase(Locale.ROOT)
        return hasToken(lower, "female") ||
            hasToken(lower, "woman") ||
            lower.contains("kadın") ||
            lower.contains("kadin") ||
            lower.contains("seda") ||
            lower.contains("selin") ||
            lower.contains("zeynep") ||
            lower.contains("filiz") ||
            lower.contains("elif") ||
            lower.contains("ece") ||
            lower.contains("ofg")
    }

    private fun isMaleLike(name: String): Boolean {
        val lower = name.lowercase(Locale.ROOT)
            .replace("female", "")
            .replace("woman", "")
            .replace("kadın", "")
            .replace("kadin", "")
        return hasToken(lower, "male") ||
            hasToken(lower, "man") ||
            lower.contains("erkek") ||
            lower.contains("adam") ||
            lower.contains("fahrettin") ||
            lower.contains("fettah") ||
            lower.contains("baritone") ||
            lower.contains("bariton") ||
            lower.contains("default") ||
            lower.contains("robot")
    }

    private fun hasToken(value: String, token: String): Boolean {
        return Regex("(^|[^a-z0-9])${Regex.escape(token.lowercase(Locale.ROOT))}([^a-z0-9]|$)")
            .containsMatchIn(value.lowercase(Locale.ROOT))
    }
}
