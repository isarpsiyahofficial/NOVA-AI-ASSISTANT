package com.example.nova

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat

object NovaAuthorizedCallNotifier {
    private const val CHANNEL_ID = "nova_phone_calls_v3_silent"
    private const val CALL_NOTIFICATION_ID = 7301

    fun showIncomingRinging(
        context: Context,
        callerLabel: String,
        authorized: Boolean
    ) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        ensureChannel(manager)
        val launchIntent = buildLaunchIntent(context)
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentTitle(callerLabel.ifBlank { "Gelen çağrı" })
            .setContentText(if (authorized) "Seçili kişi arıyor. Nova devralma hazır." else "Gelen çağrı")
            .setContentIntent(launchIntent)
            .setFullScreenIntent(launchIntent, false)
            .addAction(buildAction(context, android.R.drawable.sym_action_call, "Cevapla", NovaCallActionReceiver.ACTION_ANSWER))
            .addAction(buildAction(context, android.R.drawable.ic_menu_close_clear_cancel, "Reddet", NovaCallActionReceiver.ACTION_REJECT))
            .addAction(buildAction(context, android.R.drawable.ic_dialog_email, "Mesaj", NovaCallActionReceiver.ACTION_QUICK_MESSAGE))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
        if (authorized) {
            builder.addAction(buildAction(context, android.R.drawable.ic_btn_speak_now, "Nova devralsın", NovaCallActionReceiver.ACTION_DEVRAL))
        }
        manager.notify(CALL_NOTIFICATION_ID, builder.build())
        NovaCallStateBridge.updateNotificationState(true)
    }

    fun showAuthorizedRinging(
        context: Context,
        callerLabel: String,
        shouldVibrate: Boolean = true
    ) {
        showIncomingRinging(context, callerLabel, authorized = true)
    }

    fun showActiveCall(
        context: Context,
        callerLabel: String,
        authorized: Boolean,
        isMuted: Boolean,
        isSpeakerOn: Boolean,
        isHolding: Boolean
    ) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        ensureChannel(manager)
        val muteTitle = if (isMuted) "Mikrofonu aç" else "Mikrofonu kapa"
        val speakerTitle = if (isSpeakerOn) "Hoparlörü kapat" else "Hoparlörü aç"
        val holdTitle = if (isHolding) "Devam et" else "Beklet"
        val launchIntent = buildLaunchIntent(context)
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentTitle(callerLabel.ifBlank { "Çağrı" })
            .setContentText(if (authorized) "Nova destekli çağrı aktif." else "Çağrı devam ediyor.")
            .setContentIntent(launchIntent)
            .addAction(buildAction(context, android.R.drawable.ic_btn_speak_now, muteTitle, NovaCallActionReceiver.ACTION_TOGGLE_MUTE))
            .addAction(buildAction(context, android.R.drawable.ic_lock_silent_mode_off, speakerTitle, NovaCallActionReceiver.ACTION_TOGGLE_SPEAKER))
            .addAction(buildAction(context, android.R.drawable.ic_media_pause, holdTitle, NovaCallActionReceiver.ACTION_TOGGLE_HOLD))
            .addAction(buildAction(context, android.R.drawable.ic_menu_call, "Çağrı ekranı", NovaCallActionReceiver.ACTION_SHOW_CALL_UI))
            .addAction(buildAction(context, android.R.drawable.ic_menu_close_clear_cancel, "Kapat", NovaCallActionReceiver.ACTION_DISCONNECT))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOnlyAlertOnce(true)
        if (authorized) {
            builder.addAction(buildAction(context, android.R.drawable.ic_dialog_info, "Kontrol bende", NovaCallActionReceiver.ACTION_RETURN_TO_USER))
        }
        manager.notify(CALL_NOTIFICATION_ID, builder.build())
        NovaCallStateBridge.updateNotificationState(true)
    }

    fun showAuthorizedActive(
        context: Context,
        callerLabel: String,
        isMuted: Boolean,
        isSpeakerOn: Boolean,
        isHolding: Boolean
    ) {
        showActiveCall(context, callerLabel, authorized = true, isMuted = isMuted, isSpeakerOn = isSpeakerOn, isHolding = isHolding)
    }

    fun dismiss(context: Context) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        manager.cancel(CALL_NOTIFICATION_ID)
        NovaCallStateBridge.updateNotificationState(false)
    }

    private fun buildAction(context: Context, icon: Int, title: String, action: String): NotificationCompat.Action {
        val intent = Intent(context, NovaCallActionReceiver::class.java).apply {
            this.action = action
            `package` = context.packageName
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            action.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Action.Builder(icon, title, pendingIntent).build()
    }

    private fun ensureChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val ringtoneUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
        val attributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val channel = NotificationChannel(CHANNEL_ID, "Nova Phone Calls", NotificationManager.IMPORTANCE_HIGH).apply {
            description = "Nova varsayılan telefon çağrı bildirimleri"
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            enableVibration(false)
            setSound(null, null)
        }
        manager.createNotificationChannel(channel)
    }

    private fun buildLaunchIntent(context: Context): PendingIntent {
        return try {
            val launchIntent = Intent(context, NovaCallUiActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            PendingIntent.getActivity(
                context,
                CALL_NOTIFICATION_ID,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } catch (_: Throwable) {
            PendingIntent.getActivity(
                context,
                CALL_NOTIFICATION_ID + 1,
                Intent(context, NovaCallUiActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }
}
