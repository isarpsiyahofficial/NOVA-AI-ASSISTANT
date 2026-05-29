package com.example.nova

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class NovaCallActionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        NovaCallControlBridge.initialize(context.applicationContext)
        when (intent?.action) {
            ACTION_ANSWER -> { NovaCallAuthorityGuard.registerUserCallAction("answer"); NovaCallControlBridge.answerRingingCall() }
            ACTION_REJECT -> { NovaCallAuthorityGuard.registerUserCallAction("reject"); NovaCallControlBridge.rejectRingingCall() }
            ACTION_DEVRAL -> { NovaCallAuthorityGuard.registerUserCallAction("handoff"); NovaCallControlBridge.handOverToNova() }
            ACTION_RETURN_TO_USER -> { NovaCallAuthorityGuard.registerUserCallAction("return_to_user"); NovaCallControlBridge.handOverToUser() }
            ACTION_TOGGLE_MUTE -> { NovaCallAuthorityGuard.registerUserCallAction("mute"); NovaCallControlBridge.toggleMuted() }
            ACTION_TOGGLE_SPEAKER -> { NovaCallAuthorityGuard.registerUserCallAction("speaker"); NovaCallControlBridge.toggleSpeaker() }
            ACTION_TOGGLE_HOLD -> { NovaCallAuthorityGuard.registerUserCallAction("hold"); NovaCallControlBridge.toggleHold() }
            ACTION_DISCONNECT -> { NovaCallAuthorityGuard.registerUserCallAction("hangup"); NovaCallControlBridge.disconnectCurrentCall() }
            ACTION_SHOW_CALL_UI -> NovaCallControlBridge.showInCallScreen()
            ACTION_QUICK_MESSAGE -> { NovaCallAuthorityGuard.registerUserCallAction("quick_message"); NovaCallUiActivity.launchQuickMessage(context) }
        }
    }

    companion object {
        const val ACTION_ANSWER = "com.example.nova.call.ACTION_ANSWER"
        const val ACTION_REJECT = "com.example.nova.call.ACTION_REJECT"
        const val ACTION_DEVRAL = "com.example.nova.call.ACTION_DEVRAL"
        const val ACTION_RETURN_TO_USER = "com.example.nova.call.ACTION_RETURN_TO_USER"
        const val ACTION_TOGGLE_MUTE = "com.example.nova.call.ACTION_TOGGLE_MUTE"
        const val ACTION_TOGGLE_SPEAKER = "com.example.nova.call.ACTION_TOGGLE_SPEAKER"
        const val ACTION_TOGGLE_HOLD = "com.example.nova.call.ACTION_TOGGLE_HOLD"
        const val ACTION_DISCONNECT = "com.example.nova.call.ACTION_DISCONNECT"
        const val ACTION_SHOW_CALL_UI = "com.example.nova.call.ACTION_SHOW_CALL_UI"
        const val ACTION_QUICK_MESSAGE = "com.example.nova.call.ACTION_QUICK_MESSAGE"
    }
}
