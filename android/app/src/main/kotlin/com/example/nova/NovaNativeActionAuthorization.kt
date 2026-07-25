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
            val configured = context.getSharedPreferences(
                "nova_companion_native_authority",
                Context.MODE_PRIVATE,
            ).getBoolean("enabled", false)
            if (configured) {
                return Decision(
                    allowed = true,
                    mode = "configured_companion_scope",
                    message = "Yerel olarak yapılandırılmış companion kapsamı doğrulandı.",
                )
            }
        }

        return Decision(
            allowed = false,
            mode = "native_action_authority_missing",
            message = "Eylem için taze ve tek kullanımlık native yetki kanıtı bulunamadı.",
        )
    }
}
