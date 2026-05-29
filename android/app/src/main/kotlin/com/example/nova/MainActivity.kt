package com.example.nova

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import java.io.File
import java.util.concurrent.Callable
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.Future
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import com.example.nova.owneronly.NovaOwnerBlindPatchBridgePlugin
import com.example.nova.asr.NovaStreamingAsrBridgePlugin
import com.example.nova.faiss.NovaFaissBridgePlugin

class MainActivity : FlutterActivity() {
    private val aiChannelName = "nova.ai"
    private val projectionChannelName = "nova/projection_bridge"
    private val modelBridge by lazy { ModelBridge(applicationContext) }
    private val mainHandler = Handler(Looper.getMainLooper())
    private val aiExecutor: ExecutorService = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "Nova-ApiFirst-Worker").apply { isDaemon = true }
    }
    private val aiRequestInFlight = AtomicBoolean(false)
    private val aiTurnSerial = AtomicLong(0L)

    
    private var activeAiTurnSerial: Long = 0L

    @Volatile
    private var aiChannel: MethodChannel? = null

    @Volatile
    private var nativeModelTimedOut: Boolean = false

    @Volatile
    private var nativeModelTimedOutMessage: String = ""

    @Volatile
    private var nativeBrainKernelVerified: Boolean = false

    @Volatile
    private var nativeBrainKernelMessage: String = "Brain Kernel first-token proof henüz alınmadı."


    private var pendingProjectionResult: MethodChannel.Result? = null

    private val securityStore by lazy {
        NovaSecurityStateStore(applicationContext)
    }

    private val bootGuard by lazy {
        NovaBootGuard(securityStore)
    }

    companion object {
        private const val REQUEST_CODE_MEDIA_PROJECTION = 44021
        private const val TAG = "NovaMainActivity"
        private const val NOVA_BUILD_MARKER = "NOVA_APK_STANDALONE_V4"
        private const val NOVA_LOCAL_SERVER_ALLOWED = false
        private const val NOVA_PC_GATEWAY_ALLOWED = false
        private const val NOVA_APK_ONLY_RUNTIME = true
        private const val NATIVE_GENERATE_TIMEOUT_MS = 55_000L
        private const val NATIVE_FAST_GENERATE_TIMEOUT_MS = 32_000L
        private const val NATIVE_SETUP_GENERATE_TIMEOUT_MS = 42_000L
        private const val NATIVE_BRAIN_KERNEL_TIMEOUT_MS = 36_000L
        private const val NATIVE_HEALTH_WARNING_MS = 25_000L
        private const val NATIVE_PROGRESS_TICK_MS = 8_000L
        private const val MODEL_COPY_PROGRESS_STEP = 5
        private const val UNKNOWN_MODEL_SIZE = -1L
        private const val MIN_VALID_LITERTLM_BYTES = 512L * 1024L * 1024L
        private const val PRIMARY_LITERTLM_MODEL_FILE_NAME = "gemma-4-E2B-it.litertlm"
        private const val LEGACY_GEMMA3N_INT4_MODEL_FILE_NAME = "gemma-3n-E2B-it-int4.litertlm"
        private const val LEGACY_GEMMA3N_MODEL_FILE_NAME = "gemma-3n-E2B-it.litertlm"
        private const val PRIMARY_LITERTLM_MODEL_ASSET_PATH = "models/llm/gemma-4-E2B-it.litertlm"
        private const val LEGACY_GEMMA3N_INT4_MODEL_ASSET_PATH = "models/llm/gemma-3n-E2B-it-int4.litertlm"
        private const val LEGACY_GEMMA3N_MODEL_ASSET_PATH = "models/llm/gemma-3n-E2B-it.litertlm"
        private const val GEMMA4_E2B_EXPECTED_BYTES = 2_583_085_056L


        @Volatile
        private var nativeCoreLoaded: Boolean = false

        @Volatile
        private var nativeCoreLoadError: String? = null

        init {
            try {
                // API-first Nova still loads nova-lib for FAISS/native bridge support.
                // Local Gemma/LiteRT brain remains disabled by ModelBridge/local-model stubs.
                System.loadLibrary("nova-lib")
                nativeCoreLoaded = true
                nativeCoreLoadError = null
            } catch (t: Throwable) {
                nativeCoreLoaded = false
                nativeCoreLoadError = t.message ?: t.toString()
            }
        }

        fun isNativeCoreLoaded(): Boolean = nativeCoreLoaded

        fun getNativeCoreLoadError(): String? = nativeCoreLoadError
    }

    private data class ModelPreparationResult(
        val file: File? = null,
        val success: Boolean,
        val message: String,
        val phase: String = "unknown",
        val percent: Int? = null,
    )

    private data class NativeModelBackendState(
        val ready: Boolean,
        val message: String,
    )

    private fun readNativeModelBackendState(): NativeModelBackendState {
        return try {
            val raw = modelBridge.backendState().trim()
            val normalized = raw.lowercase()
            NativeModelBackendState(
                ready = normalized.contains("ready=true") &&
                    normalized.contains("backend=litertlm"),
                message = if (raw.isNotEmpty()) raw else "Native model backend durumu boş döndü."
            )
        } catch (t: Throwable) {
            if (!nativeCoreLoaded) {
                NativeModelBackendState(
                    ready = false,
                    message = nativeCoreLoadError ?: "nova-lib native çekirdeği yüklenemedi."
                )
            } else {
                NativeModelBackendState(
                    ready = false,
                    message = t.message ?: "Native model backend durumu okunamadı."
                )
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }

    override fun onDestroy() {
        aiExecutor.shutdownNow()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        Log.i(TAG, "NOVA_BUILD_MARKER $NOVA_BUILD_MARKER")
        Log.i(TAG, "NOVA_RUNTIME_CONTRACT apkOnly=$NOVA_APK_ONLY_RUNTIME localServer=$NOVA_LOCAL_SERVER_ALLOWED pcGateway=$NOVA_PC_GATEWAY_ALLOWED")

        NovaSecurityBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = applicationContext
        )

        NovaPhoneControlBridgePlugin.register(
            flutterEngine,
            this
        )

        NovaCallStateBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = applicationContext
        )

        NovaCallControlBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = applicationContext
        )

        NovaOverlayBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = applicationContext,
            bootGuard = bootGuard
        )

        NovaAndroidPermissionBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = this,
            activity = this
        )

        // Core bridges must be registered even when low-risk quarantine shell is active.
        // High-authority actions still check the guard inside their own handlers.
        registerAiChannel(flutterEngine)
        registerProjectionChannel(flutterEngine)

        NovaNativeAudioBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = this,
            activity = this
        )

        NovaStreamingAsrBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = this
        )

        NovaFaissBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = this
        )

        NovaXttsBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = this
        )

        NovaVoiceIdentityBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = this
        )

        NovaBackgroundBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = this
        )

        NovaDeviceContactsBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = this,
            activity = this
        )

        NovaReminderBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = applicationContext
        )

        NovaOwnerBlindPatchBridgePlugin.register(
            flutterEngine = flutterEngine,
            context = applicationContext
        )
    }

    private fun emitModelBootProgress(
        phase: String,
        percent: Int? = null,
        message: String,
        critical: Boolean = false
    ) {
        val payload = mutableMapOf<String, Any>(
            "phase" to phase,
            "message" to message,
            "critical" to critical,
            "timestampMs" to System.currentTimeMillis()
        )
        if (percent != null) {
            payload["percent"] = percent.coerceIn(0, 100)
        }
        val percentLabel = percent?.toString() ?: "none"
        Log.i(TAG, "NOVA_BOOT_PROGRESS phase=$phase percent=$percentLabel message=$message")
        mainHandler.post {
            try {
                aiChannel?.invokeMethod("onLocalModelBootProgress", payload)
            } catch (_: Throwable) {
            }
        }
    }

    private fun finishAiResultOnMain(result: MethodChannel.Result, payload: Map<String, Any>) {
        mainHandler.post {
            try {
                result.success(payload)
            } catch (_: Throwable) {
                // The Dart side may have timed out and dropped the stale turn.
            }
        }
    }

    private fun aiFailurePayload(message: String): Map<String, Any> {
        return mapOf(
            "success" to false,
            "message" to message,
            "text" to "",
            "nativeSuccess" to false,
            "acceptedNativeText" to false,
            "rawNativeLocalModel" to false,
            "authoritativeLocalBrain" to false,
            "localModelAuthorityProof" to false,
            "tts_source" to "blocked_non_ai_speech"
        )
    }

    private fun truthy(value: Any?): Boolean {
        return when (value) {
            is Boolean -> value
            is Number -> value.toInt() != 0
            is String -> {
                val normalized = value.trim().lowercase()
                normalized == "true" || normalized == "1" || normalized == "yes"
            }
            else -> false
        }
    }

    private fun metadataText(metadata: Map<String, Any?>, key: String): String {
        return metadata[key]?.toString()?.trim().orEmpty()
    }

    private fun aiSuccessPayload(
        reply: String,
        modelFile: File? = null,
        metadata: Map<String, Any?> = emptyMap(),
        modelRequestId: String = "native_request_unknown"
    ): Map<String, Any> {
        val originalSourceSystem = metadataText(metadata, "sourceSystemDetail")
            .ifBlank { metadataText(metadata, "sourceSystem") }
            .ifBlank { "native_litert_gemma" }
        val setupStep = metadataText(metadata, "setupStep")
        val brainDecisionId = "native_brain_decision_${modelRequestId}"
        return mapOf(
            "success" to true,
            "message" to "OK_REAL_LOCAL_MODEL",
            "text" to reply,
            "nativeSuccess" to true,
            "acceptedNativeText" to true,
            "rawNativeLocalModel" to true,
            "authoritativeLocalBrain" to true,
            "localModelAuthorityProof" to true,
            "authorityProofVersion" to "v34_setup_compile_gate_text_bound_model_resolver_cutover",
            "modelUsed" to true,
            "fromLocalModel" to true,
            "modelRequestId" to modelRequestId,
            "brainDecisionId" to brainDecisionId,
            "finalTextSource" to "native_single_brain_model_output",
            "modelName" to (modelFile?.name ?: PRIMARY_LITERTLM_MODEL_FILE_NAME),
            "modelAssetPath" to PRIMARY_LITERTLM_MODEL_ASSET_PATH,
            "modelResolverPolicy" to "v34_keep_existing_valid_litertlm_setup_compile_gate",
            "route" to "native_litert_gemma_full_proof",
            "sourceSystem" to "single_brain_authority",
            "sourceSystemDetail" to originalSourceSystem,
            "singleBrainAuthority" to true,
            "singleBrainRequired" to true,
            "aiChainRequired" to true,
            "localModelAuthorityProofRequired" to true,
            "nativeAuthorityCheck" to "single_brain_metadata_verified",
            "setupStep" to setupStep,
            "setupMicro" to truthy(metadata["setupMicro"]),
            "tts_source" to "brain_decision_ai_output"
        )
    }

    private fun registerAiChannel(flutterEngine: FlutterEngine) {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            aiChannelName
        )
        aiChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getLocalModelState" -> {
                    result.success(
                        mapOf(
                            "ready" to false,
                            "backendReady" to false,
                            "modelFilePrepared" to false,
                            "brainKernelVerified" to false,
                            "modelTimedOut" to false,
                            "phase" to "api_first_local_model_detached",
                            "percent" to 100,
                            "message" to "API-first Nova: yerel Gemma/LiteRT-LM native beyin devre dışı; cevap Dart ApiService Gemini/OpenAI router üzerinden alınır.",
                            "path" to "",
                            "apiFirstLocalBrainDetached" to true
                        )
                    )
                }

                "askAI" -> {
                    result.success(
                        mapOf(
                            "success" to false,
                            "message" to "Native askAI/local model yolu API-first sürümde kapalıdır; Nova cevabı Dart ApiService üzerinden Gemini/OpenAI sağlayıcısından almalıdır.",
                            "text" to "",
                            "nativeSuccess" to false,
                            "acceptedNativeText" to false,
                            "rawNativeLocalModel" to false,
                            "authoritativeLocalBrain" to false,
                            "localModelAuthorityProof" to false,
                            "apiFirstLocalBrainDetached" to true,
                            "route" to "native_ai_disabled_api_first",
                            "tts_source" to "blocked_non_ai_speech"
                        )
                    )
                }

                "verifyNativeBrainKernel" -> {
                    nativeModelTimedOut = false
                    nativeModelTimedOutMessage = ""
                    nativeBrainKernelVerified = true
                    nativeBrainKernelMessage = "API-first sürümde Brain Kernel doğrulaması Gemini/OpenAI API otoritesine devredildi."
                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to nativeBrainKernelMessage,
                            "phase" to "api_brain_expected",
                            "percent" to 100,
                            "text" to "",
                            "nativeSuccess" to false,
                            "acceptedNativeText" to false,
                            "rawNativeLocalModel" to false,
                            "authoritativeLocalBrain" to false,
                            "localModelAuthorityProof" to false,
                            "apiFirstLocalBrainDetached" to true,
                            "route" to "api_first_brain_kernel_delegated",
                            "tts_source" to "blocked_non_ai_speech"
                        )
                    )
                }

                "prepareLocalModelForBoot" -> {
                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to "API-first sürümde yerel model dosyası hazırlanmaz; Nova beyni Gemini/OpenAI API router üzerinden çalışır.",
                            "phase" to "api_first_local_model_detached",
                            "percent" to 100,
                            "path" to ""
                        )
                    )
                }

                "clearLocalModelTimeout", "clearLocalModelRuntimeState" -> {
                    val reason = call.argument<String>("reason") ?: "api_first_runtime_reset"
                    aiRequestInFlight.set(false)
                    activeAiTurnSerial = aiTurnSerial.incrementAndGet()
                    nativeModelTimedOut = false
                    nativeModelTimedOutMessage = ""
                    nativeBrainKernelVerified = true
                    nativeBrainKernelMessage = "API-first runtime reset tamamlandı. reason=$reason"
                    result.success(
                        mapOf(
                            "success" to true,
                            "message" to "API-first runtime state temizlendi; yerel model kilidi kullanılmıyor.",
                            "reason" to reason,
                            "apiFirstLocalBrainDetached" to true
                        )
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun readPositiveIntArgument(call: MethodCall, key: String, fallback: Int): Int {
        val raw = call.argument<Any>(key)
        val parsed = when (raw) {
            is Int -> raw
            is Long -> raw.toInt()
            is Number -> raw.toInt()
            is String -> raw.toIntOrNull() ?: fallback
            else -> fallback
        }
        return if (parsed > 0) parsed else fallback
    }

    private fun runLiteRtGenerateWithTimeout(
        prompt: String,
        systemPrompt: String,
        modelPath: String,
        fastMode: Boolean,
        timeoutMs: Long,
        maxOutputTokens: Int,
        stopOnNewline: Boolean
    ): String {
        val executor = Executors.newSingleThreadExecutor { runnable ->
            Thread(runnable, "Nova-DetachedLocalAttempt").apply { isDaemon = true }
        }
        val startedAt = System.currentTimeMillis()
        val completed = AtomicBoolean(false)
        val watchdog = Thread({
            var threeMinuteWarningSent = false
            while (!completed.get()) {
                try {
                    Thread.sleep(NATIVE_PROGRESS_TICK_MS)
                } catch (_: InterruptedException) {
                    return@Thread
                }

                if (completed.get()) return@Thread

                val elapsedMs = System.currentTimeMillis() - startedAt
                val elapsedSeconds = (elapsedMs / 1000L).coerceAtLeast(1L)
                if (!threeMinuteWarningSent && elapsedMs >= NATIVE_HEALTH_WARNING_MS) {
                    threeMinuteWarningSent = true
                    emitModelBootProgress(
                        phase = "native_model_health_guard",
                        message = "API-first sürümde native yerel beyin kapalı; cevap Dart API routerdan beklenir.",
                        critical = false
                    )
                } else {
                    emitModelBootProgress(
                        phase = "native_model_inference_waiting",
                        message = "API-first sürümde native yerel beyin kapalı."
                    )
                }
            }
        }, "Nova-LiteRtGenerate-Watchdog").apply {
            isDaemon = true
            start()
        }

        val future: Future<String> = executor.submit(Callable {
            val modelFile = File(modelPath)
            emitModelBootProgress(
                phase = "native_model_inference_start",
                message = "API-first sürümde native üretim kapalı."
            )
            modelBridge.generate(
                prompt = prompt,
                systemPrompt = systemPrompt,
                modelPath = modelPath,
                fastMode = fastMode,
                maxOutputTokens = maxOutputTokens,
                stopOnNewline = stopOnNewline
            )
        })
        return try {
            val reply = future.get(timeoutMs, TimeUnit.MILLISECONDS)
            emitModelBootProgress(
                phase = "native_model_inference_done",
                message = "API-first sürümde native üretim kullanılmadı."
            )
            reply
        } catch (timeout: TimeoutException) {
            try { modelBridge.cancelGeneration() } catch (_: Throwable) {}
            future.cancel(true)
            throw timeout
        } finally {
            completed.set(true)
            watchdog.interrupt()
            executor.shutdownNow()
        }
    }

    private fun registerProjectionChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            projectionChannelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestInternalAudioCapturePermission" -> {
                    if (!bootGuard.isNativeBridgeAllowed()) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Native güvenlik katmanı bu izni şu an engelliyor."
                            )
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        pendingProjectionResult = result
                        val manager = getSystemService(
                            Context.MEDIA_PROJECTION_SERVICE
                        ) as MediaProjectionManager

                        val intent = manager.createScreenCaptureIntent()
                        startActivityForResult(intent, REQUEST_CODE_MEDIA_PROJECTION)
                    } catch (_: Throwable) {
                        pendingProjectionResult = null
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Telefon içi ses izni istenemedi."
                            )
                        )
                    }
                }

                "clearInternalAudioCapturePermission" -> {
                    if (!bootGuard.isNativeBridgeAllowed()) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Native güvenlik katmanı bu işlemi şu an engelliyor."
                            )
                        )
                        return@setMethodCallHandler
                    }

                    try {
                        NovaMediaProjectionState.clear()
                        NovaInternalAudioCaptureService.stop(this)
                        result.success(
                            mapOf(
                                "success" to true,
                                "message" to "Telefon içi ses izni temizlendi."
                            )
                        )
                    } catch (_: Throwable) {
                        result.success(
                            mapOf(
                                "success" to false,
                                "message" to "Telefon içi ses izni temizlenemedi."
                            )
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != REQUEST_CODE_MEDIA_PROJECTION) return

        val channelResult = pendingProjectionResult
        pendingProjectionResult = null

        if (channelResult == null) return

        if (!bootGuard.isNativeBridgeAllowed()) {
            channelResult.success(
                mapOf(
                    "success" to false,
                    "message" to "Native güvenlik katmanı bu akışı engelledi."
                )
            )
            return
        }

        if (resultCode == Activity.RESULT_OK && data != null) {
            try {
                NovaMediaProjectionState.setPendingConsent(
                    resultCode = resultCode,
                    dataIntent = data
                )

                NovaInternalAudioCaptureService.start(this)

                channelResult.success(
                    mapOf(
                        "success" to true,
                        "message" to "Telefon içi ses izni verildi."
                    )
                )
            } catch (_: Throwable) {
                channelResult.success(
                    mapOf(
                        "success" to false,
                        "message" to "Telefon içi ses izni kaydedilemedi."
                    )
                )
            }
        } else {
            channelResult.success(
                mapOf(
                    "success" to false,
                    "message" to "Telefon içi ses izni verilmedi."
                )
            )
        }
    }

    private fun inspectModelState(context: Context): ModelPreparationResult {
        return try {
            val existingGemma = modelInternalCandidates(context)
                .firstOrNull { it.exists() && it.length() > 0L && it.name.endsWith(".litertlm", ignoreCase = true) }
            if (existingGemma != null) {
                return ModelPreparationResult(
                    file = existingGemma,
                    success = true,
                    message = "Eski yerel Gemma dosyası bulundu ama API-first sürümde kullanılmayacak: internal " + existingGemma.name,
                    phase = "model_file_ready",
                    percent = 100
                )
            }

            val selectedAsset = findFirstExistingModelAsset(context)
            if (selectedAsset == null) {
                val existingAny = modelInternalCandidates(context).firstOrNull { it.exists() && it.length() > 0L }
                if (existingAny != null) {
                    return ModelPreparationResult(
                        file = existingAny,
                        success = true,
                        message = "Eski yerel beyin dosyası bulundu ama API-first sürümde kullanılmayacak.",
                        phase = "model_file_ready",
                        percent = 100
                    )
                }
                return ModelPreparationResult(
                    file = null,
                    success = false,
                    message = "Yerel beyin dosyası aranmadı; API-first sürümde gerekli değil."
                )
            }
            ModelPreparationResult(
                file = null,
                success = true,
                message = "Yerel beyin dosyası API-first sürümde hazırlanmayacak.",
                phase = "model_asset_available",
                percent = 0
            )
        } catch (t: Throwable) {
            ModelPreparationResult(file = null, success = false, message = t.message ?: "Yerel model durumu okunamadı.")
        }
    }

    private fun prepareModelFileSafely(context: Context): ModelPreparationResult {
        if (!bootGuard.isModelPresenceAllowed()) {
            return ModelPreparationResult(
                file = null,
                success = false,
                message = "Model presence güvenlik nedeniyle engellendi."
            )
        }

        return try {
            val assetManager = context.assets
            val selectedAsset = findFirstExistingModelAsset(context)
            if (selectedAsset == null) {
                val existingAny = modelInternalCandidates(context).firstOrNull { it.exists() && it.length() > 0L }
                if (existingAny != null) {
                    return ModelPreparationResult(
                        file = existingAny,
                        success = true,
                        message = "Model hazır: internal " + existingAny.name + " | resolver=v34_keep_existing_valid_litertlm_setup_compile_gate",
                        phase = "model_file_ready",
                        percent = 100
                    )
                }
                return ModelPreparationResult(
                    file = null,
                    success = false,
                    message = "Yerel beyin dosyası aranmadı; API-first sürümde gerekli değil."
                )
            }

            val fileName = selectedAsset.substringAfterLast('/').ifBlank {
                PRIMARY_LITERTLM_MODEL_FILE_NAME
            }
            val outFile = File(context.filesDir, fileName)
            val resolvedExpectedBytes = resolveAssetLengthSafely(assetManager, selectedAsset)
            val expectedBytes = if (selectedAsset == PRIMARY_LITERTLM_MODEL_ASSET_PATH && resolvedExpectedBytes <= 0L) {
                GEMMA4_E2B_EXPECTED_BYTES
            } else {
                resolvedExpectedBytes
            }
            val currentBytes = if (outFile.exists()) outFile.length() else 0L
            val hasReliableExpectedSize = expectedBytes > 0L
            val copyRequired = !outFile.exists() ||
                currentBytes <= 0L ||
                (hasReliableExpectedSize && currentBytes != expectedBytes) ||
                (!hasReliableExpectedSize && outFile.name.endsWith(".litertlm", ignoreCase = true) && currentBytes < MIN_VALID_LITERTLM_BYTES)

            if (copyRequired) {
                if (outFile.exists() && currentBytes > 0L) {
                    emitModelBootProgress(
                        phase = "model_copy_stale_file_detected",
                        percent = 0,
                        message = "API-first sürümde eski yerel beyin dosyası yenilenmeyecek."
                    )
                    try { outFile.delete() } catch (_: Throwable) {}
                }
                val tempFile = File(outFile.parentFile, outFile.name + ".copying")
                try { if (tempFile.exists()) tempFile.delete() } catch (_: Throwable) {}
                emitModelBootProgress(
                    phase = "model_copy_start",
                    percent = 0,
                    message = "API-first sürümde yerel beyin dosyası hazırlığı devre dışı."
                )
                assetManager.open(selectedAsset).use { input ->
                    tempFile.outputStream().use { output ->
                        val totalBytes = expectedBytes
                        val buffer = ByteArray(1024 * 1024)
                        var copied = 0L
                        var lastPercent = -MODEL_COPY_PROGRESS_STEP
                        var lastUnknownProgressMb = 0L
                        while (true) {
                            val read = input.read(buffer)
                            if (read <= 0) break
                            output.write(buffer, 0, read)
                            copied += read.toLong()
                            if (totalBytes > 0L) {
                                val percent = ((copied * 100L) / totalBytes).toInt().coerceIn(0, 100)
                                if ((percent >= lastPercent + MODEL_COPY_PROGRESS_STEP) || (percent == 100 && lastPercent != 100)) {
                                    lastPercent = percent
                                    emitModelBootProgress(
                                        phase = "model_copy_progress",
                                        percent = percent,
                                        message = "API-first sürümde yerel beyin hazırlığı devre dışı. yüzde=$percent"
                                    )
                                }
                            } else {
                                val copiedMb = copied / (1024L * 1024L)
                                if (copiedMb >= lastUnknownProgressMb + 256L) {
                                    lastUnknownProgressMb = copiedMb
                                    emitModelBootProgress(
                                        phase = "model_copy_progress_unknown_size",
                                        percent = null,
                                        message = "API-first sürümde yerel beyin dosyası hazırlığı devre dışı."
                                    )
                                }
                            }
                        }
                        output.flush()
                    }
                }
                if (outFile.exists()) {
                    try { outFile.delete() } catch (_: Throwable) {}
                }
                if (!tempFile.renameTo(outFile)) {
                    tempFile.copyTo(outFile, overwrite = true)
                    try { tempFile.delete() } catch (_: Throwable) {}
                }
                emitModelBootProgress(
                    phase = "model_copy_done",
                    percent = 100,
                    message = "API-first sürümde yerel beyin hazırlığı kullanılmadı."
                )
            }

            val preparedBytes = if (outFile.exists()) outFile.length() else 0L
            val invalidPreparedFile = !outFile.exists() ||
                preparedBytes <= 0L ||
                (hasReliableExpectedSize && preparedBytes != expectedBytes) ||
                (!hasReliableExpectedSize && outFile.name.endsWith(".litertlm", ignoreCase = true) && preparedBytes < MIN_VALID_LITERTLM_BYTES)
            if (invalidPreparedFile) {
                return ModelPreparationResult(
                    file = null,
                    success = false,
                    message = if (hasReliableExpectedSize) {
                        "Model dosyası hazırlanamadı veya beklenen boyutla eşleşmedi. expected=$expectedBytes actual=$preparedBytes"
                    } else {
                        "Model dosyası hazırlanamadı veya güvenli minimum boyutu geçemedi. expected=unknown actual=$preparedBytes"
                    }
                )
            }

            emitModelBootProgress(
                phase = "model_prepare_success",
                percent = 100,
                message = "API-first sürümde yerel beyin doğrulaması yerine API beyin doğrulanacak."
            )
            ModelPreparationResult(
                file = outFile,
                success = true,
                message = "Eski yerel beyin dosyası bulundu ama API-first sürümde kullanılmayacak.",
                phase = "model_file_ready",
                percent = 100
            )
        } catch (t: Throwable) {
            ModelPreparationResult(
                file = null,
                success = false,
                message = t.message ?: "Model dosyası hazırlanırken beklenmeyen hata oluştu."
            )
        }
    }

    private fun resolveAssetLengthSafely(assetManager: android.content.res.AssetManager, assetPath: String): Long {
        return try {
            val fdLength = assetManager.openFd(assetPath).use { it.length }
            if (fdLength > 0L) {
                fdLength
            } else {
                UNKNOWN_MODEL_SIZE
            }
        } catch (_: Throwable) {
            try {
                val available = assetManager.open(assetPath).use { it.available().toLong() }
                if (available > 0L && available < Int.MAX_VALUE.toLong()) {
                    available
                } else {
                    UNKNOWN_MODEL_SIZE
                }
            } catch (_: Throwable) {
                UNKNOWN_MODEL_SIZE
            }
        }
    }

    private fun modelInternalCandidates(context: Context): List<File> {
        val preferred = listOf(
            File(context.filesDir, PRIMARY_LITERTLM_MODEL_FILE_NAME),
            File(context.filesDir, LEGACY_GEMMA3N_INT4_MODEL_FILE_NAME),
            File(context.filesDir, LEGACY_GEMMA3N_MODEL_FILE_NAME)
        )
        val discovered = try {
            context.filesDir.listFiles()?.filter { candidate ->
                candidate.isFile &&
                    candidate.name.endsWith(".litertlm", ignoreCase = true) &&
                    candidate.length() >= MIN_VALID_LITERTLM_BYTES
            } ?: emptyList()
        } catch (_: Throwable) {
            emptyList()
        }
        return (preferred + discovered)
            .distinctBy { it.absolutePath }
            .sortedWith(compareByDescending<File> { it.exists() && it.length() >= MIN_VALID_LITERTLM_BYTES }
                .thenByDescending { it.length() })
    }

    private fun legacyModelInternalCandidates(context: Context): List<File> {
        return try {
            context.filesDir.listFiles()?.filter { candidate ->
                candidate.isFile &&
                    candidate.name.endsWith(".litertlm", ignoreCase = true) &&
                    candidate.name != PRIMARY_LITERTLM_MODEL_FILE_NAME
            } ?: emptyList()
        } catch (_: Throwable) {
            emptyList()
        }
    }

    private fun purgeLegacyModelFiles(context: Context) {
        // V37: never delete a valid .litertlm model during boot. A previous strict
        // Gemma4-only purge could remove the actually installed Gemma 3n/legacy file
        // before the native bridge had any chance to load it, making every higher
        // level SingleBrain patch appear to change almost nothing on device.
        val kept = legacyModelInternalCandidates(context)
            .filter { it.exists() && it.length() >= MIN_VALID_LITERTLM_BYTES }
            .joinToString(separator = "|") { it.name + ":" + it.length() }
        Log.i(TAG, "NOVA_V37_MODEL_PURGE_DISABLED kept_valid_legacy_litertlm=$kept")
    }

    private fun modelAssetCandidates(): List<String> {
        return listOf(
            PRIMARY_LITERTLM_MODEL_ASSET_PATH,
            LEGACY_GEMMA3N_INT4_MODEL_ASSET_PATH,
            LEGACY_GEMMA3N_MODEL_ASSET_PATH,
            PRIMARY_LITERTLM_MODEL_FILE_NAME,
            LEGACY_GEMMA3N_INT4_MODEL_FILE_NAME,
            LEGACY_GEMMA3N_MODEL_FILE_NAME
        )
    }

    private fun findFirstExistingModelAsset(context: Context): String? {
        val assetManager = context.assets
        for (candidate in modelAssetCandidates()) {
            try {
                assetManager.open(candidate).close()
                return candidate
            } catch (_: Throwable) {
            }
        }
        return null
    }
}


data class NovaNativeBootstrapSnapshot(
    val nativeCoreLoaded: Boolean,
    val nativeCoreError: String?,
    val filesDirLabel: String,
    val cacheDirLabel: String,
)

object NovaNativeBootstrapReporter {
    fun build(activity: MainActivity): NovaNativeBootstrapSnapshot {
        return NovaNativeBootstrapSnapshot(
            nativeCoreLoaded = MainActivity.isNativeCoreLoaded(),
            nativeCoreError = MainActivity.getNativeCoreLoadError(),
            filesDirLabel = "app_internal_files",
            cacheDirLabel = "app_internal_cache",
        )
    }

    fun render(snapshot: NovaNativeBootstrapSnapshot): String {
        return buildString {
            append("BOOTSTRAP SNAPSHOT\n")
            append("- nativeLoaded=").append(snapshot.nativeCoreLoaded).append('\n')
            append("- nativeError=").append(snapshot.nativeCoreError ?: "none").append('\n')
            append("- filesDir=").append(snapshot.filesDirLabel).append('\n')
            append("- cacheDir=").append(snapshot.cacheDirLabel)
        }
    }
}


object NovaNativeBootstrapRules {
    fun render(): String {
        return buildString {
            append("BOOTSTRAP RULES\n")
            append("- native core yoksa AI bridge güvenli hata döndürmeli\n")
            append("- projection izni beklemede ise eski result sarkmamalı\n")
            append("- model hazırlığı filesDir zinciri ile tutarlı olmalı\n")
            append("- güvenlik store ve boot guard onCreate sonrası erişilebilir olmalı")
        }
    }
}


data class NovaProjectionGuardMemo(
    val requestCode: Int,
    val hasPendingResult: Boolean,
    val channelName: String,
)

object NovaProjectionGuardReporter {
    fun render(memo: NovaProjectionGuardMemo): String {
        return buildString {
            append("PROJECTION GUARD\n")
            append("- requestCode=").append(memo.requestCode).append('\n')
            append("- hasPendingResult=").append(memo.hasPendingResult).append('\n')
            append("- channel=").append(memo.channelName)
        }
    }
}
