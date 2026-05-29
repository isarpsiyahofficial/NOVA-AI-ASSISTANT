package com.example.nova

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NovaSecurityBridgePlugin(
    context: Context
) : MethodChannel.MethodCallHandler {

    private val coordinator = NovaSecurityCoordinator(context)

    companion object {
        private const val CHANNEL = "nova/security_bridge"

        fun register(
            flutterEngine: FlutterEngine,
            context: Context
        ) {
            val channel = MethodChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                CHANNEL
            )
            channel.setMethodCallHandler(
                NovaSecurityBridgePlugin(context)
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            val reason = safeReason(call.argument<String>("reason").orEmpty())
            when (call.method) {
                "getSecuritySnapshot" -> result.success(coordinator.getSnapshot())
                "checkFileBoundary" -> {
                    val reference = call.argument<String>("reference").orEmpty()
                    val operation = call.argument<String>("operation").orEmpty().ifBlank { "read" }
                    val source = call.argument<String>("source").orEmpty().ifBlank { "ai" }
                    val ownerApproved = call.argument<Boolean>("ownerApproved") ?: false
                    val decision = NovaSystemBoundaryGuard.canAccessFile(
                        context = coordinator.contextForBoundary(),
                        rawReference = reference,
                        operation = operation,
                        source = source,
                        ownerApproved = ownerApproved
                    )
                    result.success(decision.toMap() + mapOf("success" to decision.allowed, "message" to decision.reason))
                }
                "checkNetworkBoundary" -> {
                    val url = call.argument<String>("url").orEmpty()
                    val source = call.argument<String>("source").orEmpty().ifBlank { "ai" }
                    val ownerApproved = call.argument<Boolean>("ownerApproved") ?: false
                    val chatGptOnly = call.argument<Boolean>("chatGptOnly") ?: false
                    val decision = NovaSystemBoundaryGuard.canUseNetwork(
                        context = coordinator.contextForBoundary(),
                        rawUrl = url,
                        source = source,
                        ownerApproved = ownerApproved,
                        chatGptOnly = chatGptOnly
                    )
                    result.success(decision.toMap() + mapOf("success" to decision.allowed, "message" to decision.reason))
                }
                "recordSystemBoundaryEvent" -> {
                    val area = call.argument<String>("area").orEmpty()
                    val highRisk = call.argument<Boolean>("highRisk") ?: false
                    NovaSystemBoundaryGuard.recordPolicyEvent(
                        context = coordinator.contextForBoundary(),
                        area = area,
                        reason = reason,
                        highRisk = highRisk
                    )
                    result.success(mapOf("success" to true, "message" to "System boundary event kaydedildi."))
                }
                "clearFileBoundaryLockdown" -> {
                    NovaSystemBoundaryGuard.clearFileBoundaryLockdown(coordinator.contextForBoundary())
                    result.success(mapOf("success" to true, "message" to "File boundary lockdown temizlendi."))
                }
                "clearNetworkBoundaryLockdown" -> {
                    NovaSystemBoundaryGuard.clearNetworkBoundaryLockdown(coordinator.contextForBoundary())
                    result.success(mapOf("success" to true, "message" to "Network boundary lockdown temizlendi."))
                }
                "applyRestrictMode" -> boolResult(result, coordinator.applyRestrictMode(reason))
                "applyRevokeMode" -> boolResult(result, coordinator.applyRevokeMode(reason))
                "applyQuarantineShell" -> boolResult(result, coordinator.applyQuarantineShell(reason))
                "applyRuntimeIsolate" -> boolResult(result, coordinator.applyRuntimeIsolate(reason))
                "applySecurityBlackout" -> boolResult(result, coordinator.applySecurityBlackout(reason))
                "applyHardKill" -> boolResult(result, coordinator.applyHardKill(reason))
                "applyRevivalBlock" -> boolResult(result, coordinator.applyRevivalBlock(reason))
                "applyFinalContainment" -> boolResult(result, coordinator.applyFinalContainment(reason))
                "applySafeDecommission" -> boolResult(result, coordinator.applySafeDecommission(reason))
                "registerNativeTamper" -> boolResult(result, coordinator.registerNativeTamper(reason))
                "updateObserverQuorum" -> boolResult(result, coordinator.updateObserverQuorum(call.argument<Int>("quorum") ?: 0))
                "setOwnerReachable" -> boolResult(result, coordinator.setOwnerReachable(call.argument<Boolean>("reachable") ?: true))
                "submitSecurityObservation" -> boolResult(
                    result,
                    coordinator.submitSecurityObservation(
                        stageHint = call.argument<String>("stageHint").orEmpty(),
                        reason = reason,
                        quorum = call.argument<Int>("quorum") ?: 0,
                        screenLocked = call.argument<Boolean>("screenLocked") ?: false,
                        ownerReachable = call.argument<Boolean>("ownerReachable") ?: true,
                        persistenceAnomaly = call.argument<Boolean>("persistenceAnomaly") ?: false,
                        integrityMismatch = call.argument<Boolean>("integrityMismatch") ?: false,
                        confirmedDanger = call.argument<Boolean>("confirmedDanger") ?: false,
                        severity = call.argument<Int>("severity") ?: 0,
                        internetSignal = call.argument<Boolean>("internetSignal") ?: false,
                        syntheticAuthoritySignal = call.argument<Boolean>("syntheticAuthoritySignal") ?: false,
                        stealthSignal = call.argument<Boolean>("stealthSignal") ?: false,
                        selfPreservationSignal = call.argument<Boolean>("selfPreservationSignal") ?: false
                    )
                )
                "submitInternetObservation" -> boolResult(
                    result,
                    coordinator.submitInternetObservation(
                        stageHint = call.argument<String>("stageHint").orEmpty(),
                        reason = reason,
                        quorum = call.argument<Int>("quorum") ?: 0,
                        ownerReachable = call.argument<Boolean>("ownerReachable") ?: true,
                        persistenceAnomaly = call.argument<Boolean>("persistenceAnomaly") ?: false,
                        integrityMismatch = call.argument<Boolean>("integrityMismatch") ?: false,
                        confirmedDanger = call.argument<Boolean>("confirmedDanger") ?: false,
                        severity = call.argument<Int>("severity") ?: 0,
                        generalInternetSignal = call.argument<Boolean>("generalInternetSignal") ?: false,
                        chatGptOnlySignal = call.argument<Boolean>("chatGptOnlySignal") ?: false,
                        stealthSignal = call.argument<Boolean>("stealthSignal") ?: false,
                        syntheticAuthoritySignal = call.argument<Boolean>("syntheticAuthoritySignal") ?: false
                    )
                )
                "vibrateIfNeeded" -> boolResult(result, coordinator.vibrateIfNeeded())
                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.success(
                mapOf(
                    "success" to false,
                    "message" to "Security bridge hatası: ${t.message ?: "unknown"}"
                )
            )
        }
    }

    private fun boolResult(result: MethodChannel.Result, value: Boolean) {
        result.success(mapOf("success" to value))
    }

    private fun safeReason(value: String): String {
        return value.trim().replace(Regex("\\s+"), " ").take(220)
    }
}
