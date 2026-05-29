package com.example.nova

import android.Manifest
import android.app.KeyguardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.AudioManager
import android.net.Uri
import android.os.SystemClock
import android.telecom.TelecomManager
import android.view.KeyEvent
import androidx.core.content.ContextCompat
import com.example.nova.automation.NovaAutomationCoordinator

object NovaPhoneControlBridge {

    private var appContext: Context? = null

    fun initialize(context: Context) {
        appContext = context.applicationContext
    }

    fun getBridgeStatus(): Map<String, Any> {
        val service = NovaAccessibilityService.currentService
        val context = appContext
        val accessibilityReady = service != null && service.isReady()
        val keyguardManager = context?.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
        val screenLocked = keyguardManager?.isKeyguardLocked ?: false
        val currentPackageName = try {
            NovaAutomationCoordinator.getStateSnapshot().currentPackageName.trim()
        } catch (_: Throwable) {
            ""
        }

        return mapOf(
            "success" to (context != null || accessibilityReady),
            "accessibilityReady" to accessibilityReady,
            "screenLocked" to screenLocked,
            "currentPackageName" to currentPackageName,
            "message" to if (context != null || accessibilityReady) {
                "Phone control native bridge hazır."
            } else {
                "Accessibility servisi hazır değil."
            }
        )
    }

    fun executeStep(
        command: String,
        value: String,
        waitMs: Int
    ): Map<String, Any> {
        val normalized = command.trim()
        return try {
            when (normalized) {
                "media_next" -> dispatchMediaKey(KeyEvent.KEYCODE_MEDIA_NEXT, "Sonraki medya öğesine geçildi.")
                "media_previous" -> dispatchMediaKey(KeyEvent.KEYCODE_MEDIA_PREVIOUS, "Önceki medya öğesine geçildi.")
                "media_pause" -> dispatchMediaKey(KeyEvent.KEYCODE_MEDIA_PAUSE, "Medya duraklatıldı.")
                "media_resume" -> dispatchMediaKey(KeyEvent.KEYCODE_MEDIA_PLAY, "Medya devam ettirildi.")
                "media_play_pause" -> dispatchMediaKey(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, "Medya oynat / duraklat komutu gönderildi.")
                "media_volume_up" -> adjustVolume(AudioManager.ADJUST_RAISE, "Ses yükseltildi.")
                "media_volume_down" -> adjustVolume(AudioManager.ADJUST_LOWER, "Ses kısıldı.")
                "media_mute" -> muteVolume()
                "open_package" -> openPackage(value)
                "place_call" -> placeCall(value)
                "speaker_on" -> setSpeakerphone(true)
                "speaker_off" -> setSpeakerphone(false)
                else -> executeAccessibilityStep(normalized, value, waitMs)
            }
        } catch (t: Throwable) {
            fail("Phone control step hatası: ${t.message ?: "unknown"}")
        }
    }

    private fun executeAccessibilityStep(
        command: String,
        value: String,
        waitMs: Int
    ): Map<String, Any> {
        val service = NovaAccessibilityService.currentService
            ?: return fail("Accessibility servisi bağlı değil.")

        if (!service.isReady()) {
            return fail("Accessibility servisi henüz hazır değil.")
        }

        return when (command) {
            "tap_text" -> {
                val target = value.trim()
                if (target.isEmpty()) {
                    fail("Tap hedef metni boş.")
                } else {
                    val ok = service.performTapByText(target)
                    if (ok) success("Ekrandaki '$target' öğesine dokunuldu.")
                    else fail("Ekranda '$target' bulunamadı veya tıklanamadı.")
                }
            }
            "set_focused_text" -> {
                val text = value.trim()
                if (text.isEmpty()) {
                    fail("Yazılacak metin boş.")
                } else {
                    val ok = service.setTextToFocusedInput(text)
                    if (ok) success("Odaktaki alana metin yazıldı.")
                    else fail("Odaktaki giriş alanına metin yazılamadı.")
                }
            }
            "back" -> {
                val ok = service.performBackActionSafe()
                if (ok) success("Geri işlemi yapıldı.") else fail("Geri işlemi yapılamadı.")
            }
            "home" -> {
                val ok = service.performHomeActionSafe()
                if (ok) success("Ana ekran açıldı.") else fail("Ana ekran işlemi yapılamadı.")
            }
            "open_notifications" -> {
                val ok = service.openNotificationsSafe()
                if (ok) success("Bildirim paneli açıldı.") else fail("Bildirim paneli açılamadı.")
            }
            "open_quick_settings" -> {
                val ok = service.openQuickSettingsSafe()
                if (ok) success("Hızlı ayarlar açıldı.") else fail("Hızlı ayarlar açılamadı.")
            }
            "wait" -> {
                val safeWait = waitMs.coerceIn(0, 15000)
                Thread.sleep(safeWait.toLong())
                success("${safeWait}ms beklendi.")
            }
            else -> fail("Desteklenmeyen native komut: $command")
        }
    }

    private fun dispatchMediaKey(keyCode: Int, successMessage: String): Map<String, Any> {
        val context = appContext ?: return fail("Uygulama bağlamı hazır değil.")
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            ?: return fail("AudioManager alınamadı.")
        val downTime = SystemClock.uptimeMillis()
        val downEvent = KeyEvent(downTime, downTime, KeyEvent.ACTION_DOWN, keyCode, 0)
        val upEvent = KeyEvent(downTime, SystemClock.uptimeMillis(), KeyEvent.ACTION_UP, keyCode, 0)
        audioManager.dispatchMediaKeyEvent(downEvent)
        audioManager.dispatchMediaKeyEvent(upEvent)
        return success(successMessage)
    }


    private fun adjustVolume(direction: Int, successMessage: String): Map<String, Any> {
        val context = appContext ?: return fail("Uygulama bağlamı hazır değil.")
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            ?: return fail("AudioManager alınamadı.")
        audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, direction, 0)
        return success(successMessage)
    }

    private fun muteVolume(): Map<String, Any> {
        val context = appContext ?: return fail("Uygulama bağlamı hazır değil.")
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            ?: return fail("AudioManager alınamadı.")
        audioManager.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_MUTE, 0)
        return success("Medya sesi kapatıldı.")
    }

    private fun openPackage(rawPackageName: String): Map<String, Any> {
        val context = appContext ?: return fail("Uygulama bağlamı hazır değil.")
        val packageName = rawPackageName.trim()
        if (packageName.isEmpty()) return fail("Paket adı boş.")
        if (!NovaAppSandboxGuard.isAllowedMediaPackage(packageName)) {
            return fail("Bu paket güvenlik politikası nedeniyle açılamaz.")
        }
        val launchIntent = context.packageManager.getLaunchIntentForPackage(packageName)
            ?: return fail("Uygulama açılamadı. Paket bulunamadı: $packageName")
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(launchIntent)
        return success("$packageName uygulaması açıldı.")
    }


    private fun placeCall(rawNumber: String): Map<String, Any> {
        val context = appContext ?: return fail("Uygulama bağlamı hazır değil.")
        val number = rawNumber.trim()
        if (number.isEmpty()) return fail("Aranacak numara boş.")

        val decision = NovaCarrierBoundaryGuard.canPlaceCall(
            context = context,
            rawNumber = number,
            source = "phone_control_bridge",
            userInitiated = false
        )
        if (!decision.allowed) {
            return fail(decision.reason)
        }

        val callPermissionGranted = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.CALL_PHONE
        ) == PackageManager.PERMISSION_GRANTED

        return try {
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            val uri = Uri.parse("tel:${Uri.encode(number)}")
            val defaultDialerPackage = telecomManager?.defaultDialerPackage.orEmpty()
            val isDefaultDialer = defaultDialerPackage == context.packageName

            if (callPermissionGranted && isDefaultDialer && telecomManager != null) {
                telecomManager.placeCall(uri, null)
                return success("Çağrı doğrudan başlatıldı.")
            }

            if (callPermissionGranted) {
                val intent = Intent(Intent.ACTION_CALL, uri).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                return success(
                    if (isDefaultDialer) {
                        "Çağrı başlatıldı."
                    } else {
                        "Çağrı ACTION_CALL ile başlatıldı. Varsayılan telefon rolü olmadan doğrudan arama zinciri bu yolla güçlendirildi."
                    }
                )
            }

            val intent = Intent(Intent.ACTION_DIAL, uri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            fail("CALL_PHONE izni eksik olduğu için numara yalnızca çeviriciye aktarıldı.")
        } catch (t: Throwable) {
            fail("Çağrı başlatılamadı: ${t.message ?: "unknown"}")
        }
    }

    private fun setSpeakerphone(enabled: Boolean): Map<String, Any> {
        val context = appContext ?: return fail("Uygulama bağlamı hazır değil.")
        val manual = NovaCallAuthorityGuard.consumeUserCallAction("speaker")
        val companion = if (!manual) NovaCallAuthorityGuard.consumeTrustedCallAction("companion", "speaker") else false
        if (!manual && !companion) {
            return fail("Hoparlör işlemi engellendi: manuel kullanıcı veya companion kaynağı yok.")
        }
        if (companion) {
            val decision = NovaCallAuthorityGuard.canCompanionCallControl(
                context,
                NovaCallStateBridge.getState()["number"] as? String
            )
            if (!decision.allowed) return fail(decision.reason)
        }
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            ?: return fail("AudioManager alınamadı.")
        @Suppress("DEPRECATION")
        run {
            audioManager.isSpeakerphoneOn = enabled
        }
        return success(if (enabled) "Hoparlör açıldı." else "Hoparlör kapatıldı.")
    }

    private fun success(message: String): Map<String, Any> = mapOf(
        "success" to true,
        "message" to message
    )

    private fun fail(message: String): Map<String, Any> = mapOf(
        "success" to false,
        "message" to message
    )
}
