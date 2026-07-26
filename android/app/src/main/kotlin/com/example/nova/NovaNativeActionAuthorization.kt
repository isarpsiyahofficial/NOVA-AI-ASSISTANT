package com.example.nova

import android.content.Context

/** Native authorization boundary shared by all device-action method channels. */
object NovaNativeActionAuthorization {
    data class Decision(
        val allowed: Boolean,
        val mode: String,
        val message: String,
    )

    fun authorize(
        context: Context,
        actionToken: String,
        localUiAction: Boolean,
        companionAction: Boolean,
    ): Decision {
        if (localUiAction) {
            return Decision(
                allowed = true,
                mode = "local_ui_presence",
                message = "Yerel kullanıcı etkileşimi doğrulandı.",
            )
        }

        if (NovaOwnerActionTokenStore.consume(actionToken)) {
            return Decision(
                allowed = true,
                mode = "owner_voice_single_use_token",
                message = "Sahip voiceprint eylem tokenı doğrulandı ve tüketildi.",
            )
        }

        if (companionAction) {
            val activeNumber = (NovaCallStateBridge.getState()["number"] as? String)
                .orEmpty()
                .trim()
            val companionDecision = NovaCallAuthorityGuard.canCompanionCallControl(
                context,
                activeNumber,
            )
            if (companionDecision.allowed) {
                return Decision(
                    allowed = true,
                    mode = "configured_companion_scope",
                    message = "Yönetilen kişi ve çağrı kapsamı yerel olarak doğrulandı.",
                )
            }
            return Decision(
                allowed = false,
                mode = "companion_scope_blocked",
                message = companionDecision.reason,
            )
        }

        return Decision(
            allowed = false,
            mode = "native_action_authority_missing",
            message = "Eylem için taze ve tek kullanımlık native yetki kanıtı bulunamadı.",
        )
    }
}
