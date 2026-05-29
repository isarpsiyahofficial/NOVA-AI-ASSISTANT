package com.example.nova

import android.content.Context
import android.content.Intent
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.telecom.Call
import android.telecom.CallAudioState
import android.telecom.CallEndpoint
import android.telecom.TelecomManager
import android.telecom.VideoProfile
import android.provider.Settings
import android.net.Uri
import java.util.Locale
import java.util.concurrent.Executor
import java.util.concurrent.Executors

object NovaCallControlBridge {

    @Volatile
    private var appContext: Context? = null

    @Volatile
    private var inCallService: NovaInCallService? = null

    @Volatile
    private var currentCall: Call? = null

    @Volatile
    private var lastKnownCallState: Int = Call.STATE_DISCONNECTED

    @Volatile
    private var isMuted: Boolean = false

    @Volatile
    private var isSpeakerOn: Boolean = false

    @Volatile
    private var currentEndpoint: CallEndpoint? = null

    @Volatile
    private var availableEndpoints: List<CallEndpoint> = emptyList()

    private val executor = Executors.newSingleThreadExecutor()

    fun initialize(context: Context) {
        appContext = context.applicationContext
        NovaCallStateObserver.refreshDefaultDialerState(context.applicationContext)
    }

    fun attachService(service: NovaInCallService) {
        inCallService = service
        initialize(service.applicationContext)
    }

    fun detachService(service: NovaInCallService) {
        if (inCallService === service) {
            inCallService = null
            currentCall = null
            lastKnownCallState = Call.STATE_DISCONNECTED
            currentEndpoint = null
            availableEndpoints = emptyList()
        }
    }

    fun updateCurrentCall(call: Call?) {
        currentCall = call ?: resolveBestCall()
        lastKnownCallState = currentCall?.state ?: Call.STATE_DISCONNECTED
    }

    fun updateMuteState(value: Boolean) {
        isMuted = value
        NovaCallStateBridge.updateMuteState(value)
    }

    fun updateAudioState(state: CallAudioState?) {
        val muted = state?.isMuted ?: false
        val speaker = state?.route == CallAudioState.ROUTE_SPEAKER
        isMuted = muted
        isSpeakerOn = speaker
        NovaCallStateBridge.updateMuteState(muted)
        NovaCallStateBridge.updateSpeakerState(speaker)
        NovaCallStateBridge.updateAudioRoute(if (speaker) "speaker" else "earpiece")
    }

    fun updateEndpointState(endpoint: CallEndpoint?, endpoints: List<CallEndpoint>) {
        currentEndpoint = endpoint
        availableEndpoints = endpoints.toList()
        val routeLabel = endpoint?.let { endpointTypeLabel(it.endpointType) } ?: if (isSpeakerOn) "speaker" else "earpiece"
        val isSpeaker = routeLabel == "speaker"
        isSpeakerOn = isSpeaker
        NovaCallStateBridge.updateSpeakerState(isSpeaker)
        NovaCallStateBridge.updateAudioRoute(routeLabel)
    }

    private fun resolveManagedCallNumber(call: Call?): String {
        val direct = call?.details?.handle?.schemeSpecificPart.orEmpty().trim()
        if (direct.isNotEmpty()) return NovaAuthorizedCallRegistry.normalize(direct)
        return (NovaCallStateBridge.getState()["number"] as? String?)?.trim().orEmpty()
    }

    private fun isManagedAuthorizedCall(call: Call?): Boolean {
        val number = resolveManagedCallNumber(call)
        if (number.isEmpty()) return false
        val context = appContext ?: return false
        return NovaAuthorizedCallRegistry.isAuthorizedCallHandlingNumber(context, number)
    }

    private fun guardCallControlAction(
        call: Call?,
        actionLabel: String,
        vararg userActions: String
    ): Map<String, Any>? {
        val context = appContext ?: return buildResult(false, "$actionLabel için uygulama bağlamı hazır değil.")
        val manual = NovaCallAuthorityGuard.consumeUserCallAction(*userActions)
        if (manual) {
            val decision = NovaCallAuthorityGuard.canManualCallAction(context)
            return if (decision.allowed) null else buildResult(false, decision.reason) + decision.toMap()
        }

        val companion = NovaCallAuthorityGuard.consumeTrustedCallAction("companion", *userActions)
        val number = resolveManagedCallNumber(call)
        val decision = if (companion) {
            NovaCallAuthorityGuard.canCompanionCallControl(context, number)
        } else {
            NovaCallAuthorityGuard.recordDeniedAction(
                context,
                actionLabel,
                "$actionLabel engellendi: manuel kullanıcı veya companion kaynağı yok.",
                true
            )
            return buildResult(false, "$actionLabel engellendi: manuel kullanıcı veya companion kaynağı yok.")
        }

        return if (decision.allowed) {
            null
        } else {
            buildResult(false, "$actionLabel engellendi: ${decision.reason}") + decision.toMap()
        }
    }

    fun answerRingingCall(): Map<String, Any> {
        val context = appContext ?: return buildResult(false, "Çağrı cevaplama için uygulama bağlamı hazır değil.")
        val call = resolveRingingCall()
        val rawNumber = resolveManagedCallNumber(call).ifBlank { NovaCallStateBridge.getState()["number"] as? String ?: "" }

        val manual = NovaCallAuthorityGuard.consumeUserCallAction("answer", "handoff", "answer_slide", "answer_banner_slide")
        if (!manual) {
            val decision = NovaCallAuthorityGuard.canAutoAnswer(context, rawNumber)
            if (!decision.allowed) {
                return buildResult(false, decision.reason) + decision.toMap()
            }
        } else {
            val decision = NovaCallAuthorityGuard.canManualCallAction(context)
            if (!decision.allowed) {
                return buildResult(false, decision.reason) + decision.toMap()
            }
        }

        if (call != null && call.state == Call.STATE_RINGING) {
            return try {
                call.answer(VideoProfile.STATE_AUDIO_ONLY)
                NovaCallRinger.stop(context)
                updateCurrentCall(call)
                buildResult(true, if (manual) "Gelen çağrı kullanıcı tarafından cevaplandı." else "Gelen çağrı yetkili gece modu kapsamında Nova tarafından cevaplandı.")
            } catch (t: Throwable) {
                buildResult(false, "Gelen çağrı cevaplanamadı: ${t.message ?: "unknown"}")
            }
        }

        val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            ?: return buildResult(false, "TelecomManager alınamadı.")
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                telecomManager.acceptRingingCall()
                NovaCallRinger.stop(context)
                buildResult(true, if (manual) "Gelen çağrı kullanıcı tarafından cevaplandı." else "Gelen çağrı yetkili gece modu kapsamında Nova tarafından cevaplandı.")
            } else {
                buildResult(false, "Bu Android sürümünde güvenli cevaplama desteklenmiyor.")
            }
        } catch (t: Throwable) {
            buildResult(false, "Gelen çağrı cevaplanamadı: ${t.message ?: "unknown"}")
        }
    }

    fun rejectRingingCall(): Map<String, Any> {
        val context = appContext ?: return buildResult(false, "Çağrı reddetme için uygulama bağlamı hazır değil.")
        val call = resolveRingingCall() ?: resolveBestCall()
        val manual = NovaCallAuthorityGuard.consumeUserCallAction("reject", "quick_message", "reject_slide", "reject_banner_slide")
        if (manual) {
            val decision = NovaCallAuthorityGuard.canManualCallAction(context)
            if (!decision.allowed) return buildResult(false, decision.reason) + decision.toMap()
        } else {
            val companion = NovaCallAuthorityGuard.consumeTrustedCallAction("companion", "reject", "reject_slide", "reject_banner_slide")
            val decision = if (companion) {
                NovaCallAuthorityGuard.canCompanionCallControl(context, resolveManagedCallNumber(call))
            } else {
                NovaCallAuthorityGuard.recordDeniedAction(
                    context,
                    "reject",
                    "Çağrı reddetme engellendi: manuel kullanıcı veya companion kaynağı yok.",
                    true
                )
                return buildResult(false, "Çağrı reddetme engellendi: manuel kullanıcı veya companion kaynağı yok.")
            }
            if (!decision.allowed) return buildResult(false, "Çağrı reddetme engellendi: ${decision.reason}") + decision.toMap()
        }
        if (call == null) {
            val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            if (telecomManager != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                return try {
                    telecomManager.endCall()
                    NovaCallRinger.stop(context)
                    buildResult(true, if (manual) "Çağrı kullanıcı tarafından reddedildi." else "Yetkili çağrı Nova tarafından sonlandırıldı.")
                } catch (t: Throwable) {
                    buildResult(false, "Çağrı reddedilemedi: ${t.message ?: "unknown"}")
                }
            }
            return buildResult(false, "Reddedilecek gelen çağrı bulunamadı.")
        }

        return try {
            if (call.state == Call.STATE_RINGING) {
                call.reject(false, null)
            } else {
                call.disconnect()
            }
            NovaCallRinger.stop(context)
            updateCurrentCall(call)
            buildResult(true, if (manual) "Çağrı kullanıcı tarafından reddedildi." else "Yetkili çağrı Nova tarafından sonlandırıldı.")
        } catch (t: Throwable) {
            buildResult(false, "Çağrı reddedilemedi: ${t.message ?: "unknown"}")
        }
    }

    fun disconnectCurrentCall(): Map<String, Any> {
        val context = appContext ?: return buildResult(false, "Çağrı sonlandırma için uygulama bağlamı hazır değil.")
        val call = resolveBestCall() ?: return buildResult(false, "Sonlandırılacak çağrı bulunamadı.")
        val manual = NovaCallAuthorityGuard.consumeUserCallAction("disconnect", "hangup")
        if (manual) {
            val decision = NovaCallAuthorityGuard.canManualCallAction(context)
            if (!decision.allowed) return buildResult(false, decision.reason) + decision.toMap()
        } else {
            val companion = NovaCallAuthorityGuard.consumeTrustedCallAction("companion", "disconnect", "hangup")
            val decision = if (companion) {
                NovaCallAuthorityGuard.canCompanionCallControl(context, resolveManagedCallNumber(call))
            } else {
                NovaCallAuthorityGuard.recordDeniedAction(
                    context,
                    "disconnect",
                    "Çağrı sonlandırma engellendi: manuel kullanıcı veya companion kaynağı yok.",
                    true
                )
                return buildResult(false, "Çağrı sonlandırma engellendi: manuel kullanıcı veya companion kaynağı yok.")
            }
            if (!decision.allowed) return buildResult(false, "Çağrı sonlandırma engellendi: ${decision.reason}") + decision.toMap()
        }
        return try {
            call.disconnect()
            NovaCallRinger.stop(context)
            updateCurrentCall(call)
            buildResult(true, if (manual) "Çağrı kullanıcı tarafından sonlandırıldı." else "Yetkili çağrı Nova tarafından sonlandırıldı.")
        } catch (t: Throwable) {
            buildResult(false, "Çağrı sonlandırılamadı: ${t.message ?: "unknown"}")
        }
    }

    fun setMuted(value: Boolean): Map<String, Any> {
        val call = resolveBestCall()
        guardCallControlAction(call, "Mikrofon işlemi", "mute", "handoff", "return_to_user")?.let { return it }
        val service = inCallService
        if (service != null && call != null) {
            return try {
                if (call.state == Call.STATE_DISCONNECTED) return buildResult(false, "Çağrı bağlı değilken mikrofon değiştirilemez.")
                service.setMuted(value)
                isMuted = value
                NovaCallStateBridge.updateMuteState(value)
                buildResult(true, if (value) "Mikrofon kapatıldı." else "Mikrofon açıldı.")
            } catch (t: Throwable) {
                buildResult(false, "Mikrofon durumu değiştirilemedi: ${t.message ?: "unknown"}")
            }
        }

        val context = appContext ?: return buildResult(false, "Mikrofon ayarı için uygulama bağlamı hazır değil.")
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            ?: return buildResult(false, "AudioManager alınamadı.")
        return try {
            @Suppress("DEPRECATION")
            audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
            audioManager.isMicrophoneMute = value
            isMuted = value
            NovaCallStateBridge.updateMuteState(value)
            buildResult(true, if (value) "Mikrofon kapatıldı." else "Mikrofon açıldı.")
        } catch (t: Throwable) {
            buildResult(false, "Mikrofon değiştirilemedi: ${t.message ?: "unknown"}")
        }
    }

    fun routeToSpeaker(enabled: Boolean): Map<String, Any> {
        val call = resolveBestCall()
        guardCallControlAction(call, "Ses çıkışı işlemi", "speaker", "handoff", "return_to_user")?.let { return it }
        val service = inCallService
        if (service != null && call != null) {
            return try {
                if (call.state == Call.STATE_DISCONNECTED) return buildResult(false, "Çağrı bağlı değilken ses çıkışı değiştirilemez.")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    val preferredTypes = if (enabled) {
                        listOf(CallEndpoint.TYPE_SPEAKER)
                    } else {
                        listOf(CallEndpoint.TYPE_EARPIECE, CallEndpoint.TYPE_WIRED_HEADSET, CallEndpoint.TYPE_BLUETOOTH)
                    }
                    val endpoint = preferredTypes.firstNotNullOfOrNull { targetType ->
                        availableEndpoints.firstOrNull { it.endpointType == targetType } ?: currentEndpoint?.takeIf { it.endpointType == targetType }
                    } ?: return buildResult(false, "Uygun ses çıkış noktası bulunamadı.")
                    var callbackError: String? = null
                    val callbackExecutor: Executor = executor
                    service.requestCallEndpointChange(endpoint, callbackExecutor) { error ->
                        callbackError = error?.toString()
                        if (error == null) {
                            isSpeakerOn = endpoint.endpointType == CallEndpoint.TYPE_SPEAKER
                            NovaCallStateBridge.updateSpeakerState(isSpeakerOn)
                            NovaCallStateBridge.updateAudioRoute(endpointTypeLabel(endpoint.endpointType))
                        }
                    }
                    if (callbackError != null) return buildResult(false, "Ses çıkışı değiştirilemedi: $callbackError")
                    isSpeakerOn = endpoint.endpointType == CallEndpoint.TYPE_SPEAKER
                    NovaCallStateBridge.updateSpeakerState(isSpeakerOn)
                    NovaCallStateBridge.updateAudioRoute(endpointTypeLabel(endpoint.endpointType))
                    return buildResult(true, if (isSpeakerOn) "Ses hoparlöre alındı." else "Ses uygun çağrı çıkışına alındı.")
                }

                @Suppress("DEPRECATION")
                service.setAudioRoute(if (enabled) CallAudioState.ROUTE_SPEAKER else CallAudioState.ROUTE_EARPIECE)
                isSpeakerOn = enabled
                NovaCallStateBridge.updateSpeakerState(enabled)
                NovaCallStateBridge.updateAudioRoute(if (enabled) "speaker" else "earpiece")
                buildResult(true, if (enabled) "Ses hoparlöre alındı." else "Ses normal çıkışa alındı.")
            } catch (t: Throwable) {
                buildResult(false, "Ses çıkışı değiştirilemedi: ${t.message ?: "unknown"}")
            }
        }

        val context = appContext ?: return buildResult(false, "Ses yönlendirmesi için uygulama bağlamı hazır değil.")
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager
            ?: return buildResult(false, "AudioManager alınamadı.")
        return try {
            @Suppress("DEPRECATION")
            audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
            @Suppress("DEPRECATION")
            audioManager.isSpeakerphoneOn = enabled
            isSpeakerOn = enabled
            NovaCallStateBridge.updateSpeakerState(enabled)
            NovaCallStateBridge.updateAudioRoute(if (enabled) "speaker" else "earpiece")
            buildResult(true, if (enabled) "Ses hoparlöre alındı." else "Ses normal çıkışa alındı.")
        } catch (t: Throwable) {
            buildResult(false, "Ses çıkışı değiştirilemedi: ${t.message ?: "unknown"}")
        }
    }

    fun toggleMuted(): Map<String, Any> = setMuted(!isMuted)

    fun toggleSpeaker(): Map<String, Any> = routeToSpeaker(!isSpeakerOn)

    fun toggleHold(): Map<String, Any> {
        val call = resolveBestCall() ?: return buildResult(false, "Bekletme için aktif çağrı bulunamadı.")
        guardCallControlAction(call, "Bekletme işlemi", "hold")?.let { return it }
        return try {
            if (call.state == Call.STATE_HOLDING) {
                call.unhold()
                buildResult(true, "Çağrı beklemeden çıkarıldı.")
            } else {
                val details = call.details
                val canHold = details != null && (details.callCapabilities and Call.Details.CAPABILITY_HOLD) != 0
                if (!canHold) return buildResult(false, "Bu çağrı cihaz veya operatör tarafından bekletmeyi desteklemiyor.")
                call.hold()
                buildResult(true, "Çağrı beklemeye alındı.")
            }
        } catch (t: Throwable) {
            buildResult(false, "Bekletme işlemi yapılamadı: ${t.message ?: "unknown"}")
        }
    }

    fun showInCallScreen(): Map<String, Any> {
        val context = appContext ?: return buildResult(false, "Çağrı ekranı için uygulama bağlamı hazır değil.")
        return try {
            NovaCallUiActivity.launch(context)
            buildResult(true, "Çağrı ekranı açıldı.")
        } catch (t: Throwable) {
            buildResult(false, "Çağrı ekranı açılamadı: ${t.message ?: "unknown"}")
        }
    }

    fun sendDtmfTone(digit: Char): Map<String, Any> {
        val context = appContext ?: return buildResult(false, "DTMF için uygulama bağlamı hazır değil.")
        val call = resolveBestCall() ?: return buildResult(false, "DTMF için aktif çağrı bulunamadı.")
        val carrierDtmf = NovaCarrierBoundaryGuard.canSendDtmf(context, digit)
        if (!carrierDtmf.allowed) {
            return buildResult(false, carrierDtmf.reason) + carrierDtmf.toMap()
        }
        guardCallControlAction(call, "DTMF işlemi", "dtmf")?.let { return it }
        return try {
            call.playDtmfTone(digit)
            executor.execute {
                try { Thread.sleep(180) } catch (_: Throwable) {}
                try { call.stopDtmfTone() } catch (_: Throwable) {}
            }
            buildResult(true, "DTMF gönderildi.")
        } catch (t: Throwable) {
            buildResult(false, "DTMF gönderilemedi: ${t.message ?: "unknown"}")
        }
    }

    fun toggleCallRecording(): Map<String, Any> {
        val context = appContext ?: return buildResult(false, "Kayıt için uygulama bağlamı hazır değil.")
        val call = resolveBestCall() ?: return buildResult(false, "Kayıt için aktif çağrı bulunamadı.")
        guardCallControlAction(call, "Kayıt işlemi", "record")?.let { return it }
        if (call.state != Call.STATE_ACTIVE && call.state != Call.STATE_HOLDING) {
            return buildResult(false, "Kayıt yalnız aktif çağrıda başlatılabilir.")
        }
        return try {
            val raw = NovaCallRecordingController.toggle(context)
            raw + buildResult(raw["success"] == true, raw["message"] as? String ?: "Kayıt durumu değiştirildi.")
        } catch (t: Throwable) {
            buildResult(false, "Kayıt işlemi başarısız: ${t.message ?: "unknown"}")
        }
    }

    fun isCallRecording(): Boolean = NovaCallRecordingController.isRecording()

    fun requestVideoUpgrade(): Map<String, Any> {
        val call = resolveBestCall() ?: return buildResult(false, "Görüntülü arama için aktif çağrı bulunamadı.")
        guardCallControlAction(call, "Görüntülü arama işlemi", "video")?.let { return it }
        if (call.state != Call.STATE_ACTIVE && call.state != Call.STATE_HOLDING) {
            return buildResult(false, "Görüntülü arama yalnız aktif çağrıda istenebilir.")
        }
        return try {
            val details = call.details
            val caps = details?.callCapabilities ?: 0
            val supportsVideo =
                (caps and Call.Details.CAPABILITY_SUPPORTS_VT_LOCAL_TX) != 0 ||
                    (caps and Call.Details.CAPABILITY_SUPPORTS_VT_LOCAL_RX) != 0 ||
                    (caps and Call.Details.CAPABILITY_SUPPORTS_VT_REMOTE_TX) != 0 ||
                    (caps and Call.Details.CAPABILITY_SUPPORTS_VT_REMOTE_RX) != 0
            val videoCall = call.videoCall
            if (videoCall != null && supportsVideo) {
                videoCall.sendSessionModifyRequest(VideoProfile(VideoProfile.STATE_BIDIRECTIONAL))
                buildResult(true, "Görüntülü arama isteği gönderildi.")
            } else {
                openCallSettings()
                buildResult(false, "Bu çağrı görüntülü aramayı doğrudan desteklemiyor; çağrı ayarları açıldı.")
            }
        } catch (t: Throwable) {
            buildResult(false, "Görüntülü arama isteği başarısız: ${t.message ?: "unknown"}")
        }
    }

    fun openClearCallSettings(): Map<String, Any> {
        val call = resolveBestCall()
        guardCallControlAction(call, "Net Arama ayarı", "net_call")?.let { return it }
        return try {
            val opened = openCallSettings()
            if (opened) buildResult(true, "Çağrı/ağ ayarları açıldı.") else buildResult(false, "Çağrı/ağ ayarı açılamadı.")
        } catch (t: Throwable) {
            buildResult(false, "Çağrı/ağ ayarı açılamadı: ${t.message ?: "unknown"}")
        }
    }

    private fun openCallSettings(): Boolean {
        val context = appContext ?: return false
        val intents = listOf(
            Intent("android.telecom.action.CHANGE_DEFAULT_DIALER"),
            Intent(Settings.ACTION_WIRELESS_SETTINGS),
            Intent(Settings.ACTION_NETWORK_OPERATOR_SETTINGS),
            Intent(Settings.ACTION_SETTINGS)
        )
        for (intent in intents) {
            try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context.startActivity(intent)
                return true
            } catch (_: Throwable) {
            }
        }
        return false
    }

    fun handOverToNova(): Map<String, Any> {
        var call = resolveBestCall()
        val managedNumber = resolveManagedCallNumber(call)
        val context = appContext
        if (context == null) return buildResult(false, "Nova devralma için uygulama bağlamı hazır değil.")
        val manual = NovaCallAuthorityGuard.consumeUserCallAction("handoff")
        val companion = if (!manual) NovaCallAuthorityGuard.consumeTrustedCallAction("companion", "handoff") else false
        val decision = when {
            manual -> NovaCallAuthorityGuard.canManualCallAction(context)
            companion -> NovaCallAuthorityGuard.canCompanionCallControl(context, managedNumber)
            else -> {
                NovaCallAuthorityGuard.recordDeniedAction(
                    context,
                    "handoff",
                    "Nova devralma engellendi: manuel kullanıcı veya companion kaynağı yok.",
                    true
                )
                return buildResult(false, "Nova devralma engellendi: manuel kullanıcı veya companion kaynağı yok.")
            }
        }
        if (!decision.allowed) {
            return buildResult(false, decision.reason) + decision.toMap()
        }

        if (call?.state == Call.STATE_RINGING) {
            if (manual) {
                NovaCallAuthorityGuard.registerUserCallAction("handoff")
            }
            val answer = answerRingingCall()
            if (answer["success"] != true) return answer
            Thread.sleep(120)
            call = resolveBestCall()
        }

        if (manual) NovaCallAuthorityGuard.registerUserCallAction("handoff")
        if (companion) NovaCallAuthorityGuard.registerTrustedCallAction("handoff", "companion")
        val speaker = routeToSpeaker(true)
        if (manual) NovaCallAuthorityGuard.registerUserCallAction("handoff")
        if (companion) NovaCallAuthorityGuard.registerTrustedCallAction("handoff", "companion")
        val mute = setMuted(true)
        return buildResult(
            success = speaker["success"] == true && mute["success"] == true,
            message = if (speaker["success"] == true && mute["success"] == true) {
                "Kontrol Nova tarafına geçti. Seçili kişi için dijital insan çağrı düzeni aktif."
            } else {
                "Kontrol Nova tarafına tam geçirilemedi."
            }
        )
    }

    fun handOverToUser(): Map<String, Any> {
        val manual = NovaCallAuthorityGuard.consumeUserCallAction("return_to_user")
        val companion = if (!manual) NovaCallAuthorityGuard.consumeTrustedCallAction("companion", "return_to_user") else false
        if (manual) NovaCallAuthorityGuard.registerUserCallAction("return_to_user")
        if (companion) NovaCallAuthorityGuard.registerTrustedCallAction("return_to_user", "companion")
        val mute = setMuted(false)
        if (manual) NovaCallAuthorityGuard.registerUserCallAction("return_to_user")
        if (companion) NovaCallAuthorityGuard.registerTrustedCallAction("return_to_user", "companion")
        val speaker = routeToSpeaker(false)
        return buildResult(
            success = mute["success"] == true && speaker["success"] == true,
            message = if (mute["success"] == true && speaker["success"] == true) "Kontrol Patrona bırakıldı." else "Kontrol patrona tam bırakılamadı."
        )
    }

    fun getCapabilities(): Map<String, Any> {
        val serviceReady = inCallService != null
        val call = resolveBestCall()
        val hasRinging = resolveRingingCall() != null || NovaCallStateBridge.getState()["isRinging"] == true
        val hasOngoing = (call != null && call.state != Call.STATE_DISCONNECTED) || NovaCallStateBridge.getState()["isActiveCall"] == true
        val hybridReady = appContext != null
        return mapOf(
            "dialerRoleHeld" to (appContext?.let { isDefaultDialer(it) } ?: false),
            "inCallServiceReady" to serviceReady,
            "hybridCallControlReady" to hybridReady,
            "hasRingingCall" to hasRinging,
            "hasOngoingCall" to hasOngoing,
            "notificationSyncReady" to (serviceReady || hybridReady),
            "speakerAvailable" to (hasOngoing && hybridReady),
            "muteAvailable" to (hasOngoing && hybridReady),
            "holdAvailable" to (hasOngoing && serviceReady),
            "showCallUiAvailable" to (hasOngoing || hasRinging),
            "managedOnlyNoUxOverride" to false,
            "isAuthorizedManagedNumber" to (NovaCallStateBridge.getState()["isAuthorizedManagedNumber"] == true),
            "message" to when {
                serviceReady -> "Varsayılan telefon çağrı UI ve kontrol köprüsü hazır. Normal çağrılar cevaplanır/reddedilir; Nova companion yalnız seçili kişilerde devreye girer."
                hybridReady -> "Temel çağrı kontrolü hazır. Varsayılan telefon rolü alındığında tam in-call UI devreye girer."
                else -> "Çağrı kontrol köprüsü hazır değil."
            }
        )
    }

    fun placeOutgoingCall(rawNumber: String): Map<String, Any> {
        val context = appContext ?: return buildResult(false, "Arama için uygulama bağlamı hazır değil.")
        val number = rawNumber.trim()
        if (number.isEmpty()) return buildResult(false, "Aranacak numara boş.")
        val decision = NovaCarrierBoundaryGuard.canPlaceCall(
            context = context,
            rawNumber = number,
            source = "call_control_bridge",
            userInitiated = false
        )
        if (!decision.allowed) {
            return buildResult(false, decision.reason) + decision.toMap()
        }
        val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            ?: return buildResult(false, "TelecomManager alınamadı.")
        return try {
            val uri = android.net.Uri.parse("tel:${android.net.Uri.encode(number)}")
            telecomManager.placeCall(uri, Bundle())
            buildResult(true, "Arama başlatıldı.")
        } catch (t: Throwable) {
            buildResult(false, "Arama başlatılamadı: ${t.message ?: "unknown"}")
        }
    }

    private fun resolveRingingCall(): Call? {
        val direct = currentCall
        if (direct?.state == Call.STATE_RINGING) return direct
        return resolveCalls().firstOrNull { it.state == Call.STATE_RINGING }
    }

    private fun resolveBestCall(): Call? {
        val direct = currentCall
        if (direct != null && direct.state != Call.STATE_DISCONNECTED) return direct
        val orderedStates = listOf(
            Call.STATE_RINGING,
            Call.STATE_ACTIVE,
            Call.STATE_CONNECTING,
            Call.STATE_DIALING,
            Call.STATE_SELECT_PHONE_ACCOUNT,
            Call.STATE_HOLDING
        )
        val calls = resolveCalls()
        for (state in orderedStates) calls.firstOrNull { it.state == state }?.let { return it }
        return calls.firstOrNull()
    }

    private fun resolveCalls(): List<Call> = try { inCallService?.calls?.toList().orEmpty() } catch (_: Throwable) { emptyList() }

    private fun callStateLabel(state: Int): String = when (state) {
        Call.STATE_NEW -> "new"
        Call.STATE_DIALING -> "dialing"
        Call.STATE_RINGING -> "ringing"
        Call.STATE_HOLDING -> "holding"
        Call.STATE_ACTIVE -> "active"
        Call.STATE_DISCONNECTED -> "disconnected"
        Call.STATE_SELECT_PHONE_ACCOUNT -> "select_phone_account"
        Call.STATE_CONNECTING -> "connecting"
        Call.STATE_DISCONNECTING -> "disconnecting"
        else -> "unknown_${state}"
    }

    private fun endpointTypeLabel(endpointType: Int): String = when (endpointType) {
        CallEndpoint.TYPE_EARPIECE -> "earpiece"
        CallEndpoint.TYPE_BLUETOOTH -> "bluetooth"
        CallEndpoint.TYPE_SPEAKER -> "speaker"
        CallEndpoint.TYPE_STREAMING -> "streaming"
        CallEndpoint.TYPE_WIRED_HEADSET -> "wired_headset"
        else -> "unknown_${endpointType}"
    }.lowercase(Locale.US)

    fun isDefaultDialer(context: Context): Boolean = try {
        val telecomManager = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
        telecomManager?.defaultDialerPackage == context.packageName
    } catch (_: Throwable) { false }

    private fun buildResult(success: Boolean, message: String): Map<String, Any> {
        val call = resolveBestCall()
        lastKnownCallState = call?.state ?: lastKnownCallState
        return mapOf(
            "success" to success,
            "message" to message,
            "isMuted" to isMuted,
            "isSpeakerOn" to isSpeakerOn,
            "inCallServiceReady" to (inCallService != null),
            "callState" to callStateLabel(call?.state ?: lastKnownCallState),
            "callCount" to resolveCalls().size,
            "currentEndpoint" to (currentEndpoint?.let { endpointTypeLabel(it.endpointType) } ?: "unknown"),
            "availableEndpoints" to availableEndpoints.map { endpointTypeLabel(it.endpointType) },
            "isAuthorizedManagedNumber" to isManagedAuthorizedCall(call)
        )
    }

    fun isMuted(): Boolean = isMuted

    fun isSpeakerOn(): Boolean = isSpeakerOn

    fun getLastKnownCallState(): Int = lastKnownCallState

    fun getAvailableEndpointNames(): List<String> = availableEndpoints.mapNotNull { endpoint ->
        try { endpoint.endpointName?.toString()?.trim() } catch (_: Throwable) { null }
    }.filter { it.isNotEmpty() }
}

data class NovaCallBridgeSnapshot(
    val muted: Boolean,
    val speakerOn: Boolean,
    val lastKnownState: Int,
    val endpointName: String,
    val endpointCount: Int
)

object NovaCallBridgeDiagnostics {
    fun buildSnapshot(): NovaCallBridgeSnapshot {
        val endpointName = try { NovaCallControlBridge.getAvailableEndpointNames().firstOrNull() ?: "unknown" } catch (_: Throwable) { "unknown" }
        val endpointCount = try { NovaCallControlBridge.getAvailableEndpointNames().size } catch (_: Throwable) { 0 }
        return NovaCallBridgeSnapshot(
            muted = NovaCallControlBridge.isMuted(),
            speakerOn = NovaCallControlBridge.isSpeakerOn(),
            lastKnownState = NovaCallControlBridge.getLastKnownCallState(),
            endpointName = endpointName,
            endpointCount = endpointCount
        )
    }

    fun render(snapshot: NovaCallBridgeSnapshot): String {
        return buildString {
            append("CALL BRIDGE SNAPSHOT\n")
            append("- muted=").append(snapshot.muted).append('\n')
            append("- speakerOn=").append(snapshot.speakerOn).append('\n')
            append("- lastKnownState=").append(snapshot.lastKnownState).append('\n')
            append("- endpointName=").append(snapshot.endpointName).append('\n')
            append("- endpointCount=").append(snapshot.endpointCount).append('\n')
        }
    }
}
