package com.example.nova

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.graphics.*
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.ContactsContract
import android.view.MotionEvent
import android.view.View
import android.view.Window
import android.view.WindowManager
import java.util.Locale
import java.util.concurrent.TimeUnit
import kotlin.math.abs
import kotlin.math.min
import kotlin.math.max

class NovaCallUiActivity : Activity() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var callView: HiosCallCanvasView
    private var proximityWakeLock: PowerManager.WakeLock? = null

    private val refreshRunnable = object : Runnable {
        override fun run() {
            callView.invalidate()
            updateProximityFromCanvas()
            finishIfIdle()
            handler.postDelayed(this, 350)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureWindow()
        NovaCallControlBridge.initialize(applicationContext)
        callView = HiosCallCanvasView(this, this)
        setContentView(callView)
        if (intent?.getBooleanExtra(EXTRA_SHOW_QUICK_MESSAGE, false) == true) {
            handler.postDelayed({ callView.showQuickReply() }, 160)
        }
    }

    override fun onResume() {
        super.onResume()
        handler.removeCallbacks(refreshRunnable)
        handler.post(refreshRunnable)
    }

    override fun onPause() {
        handler.removeCallbacks(refreshRunnable)
        super.onPause()
    }

    override fun onDestroy() {
        releaseProximityWakeLock()
        super.onDestroy()
    }

    private fun configureWindow() {
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility = View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
    }

    private fun updateProximityFromCanvas() {
        val state = NovaCallStateBridge.getState()
        val isActive = state["isActiveCall"] == true || state["state"] == "holding"
        val route = (state["currentAudioRoute"] as? String).orEmpty().ifBlank {
            if (state["isSpeakerOn"] == true) "speaker" else "earpiece"
        }
        val shouldUseProximity = isActive && !callView.isKeypadVisible() && route == "earpiece"
        if (shouldUseProximity) acquireProximityWakeLock() else releaseProximityWakeLock()
    }

    private fun acquireProximityWakeLock() {
        try {
            if (proximityWakeLock == null) {
                val powerManager = getSystemService(Context.POWER_SERVICE) as? PowerManager ?: return
                @Suppress("DEPRECATION")
                proximityWakeLock = powerManager.newWakeLock(PowerManager.PROXIMITY_SCREEN_OFF_WAKE_LOCK, "nova:call_ui_proximity").apply {
                    setReferenceCounted(false)
                }
            }
            proximityWakeLock?.let { if (!it.isHeld) it.acquire() }
        } catch (_: Throwable) {
            releaseProximityWakeLock()
        }
    }

    private fun releaseProximityWakeLock() {
        try {
            proximityWakeLock?.let { if (it.isHeld) it.release() }
        } catch (_: Throwable) {
        }
    }

    private fun finishIfIdle() {
        val state = NovaCallStateBridge.getState()
        val active = state["inCall"] == true || state["state"] == "dialing" || state["state"] == "connecting"
        if (!active) {
            releaseProximityWakeLock()
            finish()
        }
    }

    companion object {
        private const val EXTRA_SHOW_QUICK_MESSAGE = "nova.extra.SHOW_QUICK_MESSAGE"

        fun launchQuickMessage(context: Context) {
            val intent = Intent(context, NovaCallUiActivity::class.java).apply {
                putExtra(EXTRA_SHOW_QUICK_MESSAGE, true)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            context.startActivity(intent)
        }

        fun launch(context: Context) {
            val intent = Intent(context, NovaCallUiActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            context.startActivity(intent)
        }
    }
}

private class HiosCallCanvasView(
    context: Context,
    private val activity: Activity
) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val touchRegions = mutableListOf<Pair<RectF, () -> Unit>>()

    private val keypadBuffer = StringBuilder()
    private var quickReplyVisible = false
    private var keypadVisible = false
    private var morePageVisible = false
    private var localActiveStartedAt = 0L
    private var lastNumberForPhoto = ""
    private var contactBitmap: Bitmap? = null
    private var lastNumberForName = ""
    private var resolvedCallerNameCache = ""
    private var incomingDownX = 0f
    private var incomingDownY = 0f
    private var incomingDragDx = 0f
    private var incomingGestureTracking = false

    private fun sx(px: Float): Float = width * (px / 1080f)
    private fun sy(px: Float): Float = height * (px / 2400f)
    private fun ss(px: Float): Float = min(width / 1080f, height / 2400f) * px

    fun showQuickReply() {
        quickReplyVisible = true
        invalidate()
    }

    fun isKeypadVisible(): Boolean = keypadVisible

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        touchRegions.clear()
        val state = NovaCallStateBridge.getState()
        val stateLabel = (state["state"] as? String).orEmpty()
        val isRinging = state["isRinging"] == true
        val isActive = state["isActiveCall"] == true
        val isHolding = stateLabel == "holding"
        val isDialing = stateLabel == "dialing" || stateLabel == "connecting"
        val isMuted = state["isMuted"] == true
        val isSpeaker = state["isSpeakerOn"] == true
        val authorized = state["isAuthorizedManagedNumber"] == true
        val number = (state["number"] as? String).orEmpty()
        val stateName = (state["callerDisplayName"] as? String).orEmpty()
        val callerName = resolveCallerDisplayName(number, stateName)

        if ((isActive || isHolding) && localActiveStartedAt == 0L) localActiveStartedAt = System.currentTimeMillis()
        if (!isActive && !isHolding) localActiveStartedAt = 0L

        drawHiosBackground(canvas)

        when {
            keypadVisible -> drawKeypadScreen(canvas, callerName, number, isSpeaker)
            isRinging -> drawIncomingFullScreen(canvas, callerName, number, authorized)
            morePageVisible -> drawMorePage(canvas, callerName, number, authorized, isMuted, isSpeaker)
            isActive || isHolding || isDialing -> drawActiveCall(canvas, callerName, number, isMuted, isHolding, authorized, isSpeaker)
            else -> drawActiveCall(canvas, callerName, number, isMuted, isHolding, authorized, isSpeaker)
        }

        if (quickReplyVisible) {
            drawQuickReplySheet(canvas, number)
        }
    }

    private fun drawHiosBackground(canvas: Canvas) {
        val shader = RadialGradient(
            width * 0.50f,
            height * 0.40f,
            maxOf(width, height) * 0.88f,
            intArrayOf(Color.rgb(94, 10, 12), Color.rgb(42, 7, 9), Color.rgb(19, 4, 5)),
            floatArrayOf(0f, 0.58f, 1f),
            Shader.TileMode.CLAMP
        )
        paint.shader = shader
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        paint.shader = null
        paint.color = Color.argb(34, 237, 44, 46)
        canvas.drawCircle(width * 0.52f, height * 0.34f, width * 0.38f, paint)
        paint.color = Color.argb(28, 240, 215, 209)
        canvas.drawCircle(width * 0.18f, height * 0.14f, width * 0.20f, paint)
        paint.color = Color.argb(78, 0, 0, 0)
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
    }

    private fun drawContactHeader(
        canvas: Canvas,
        callerName: String,
        number: String,
        includePhoto: Boolean,
        active: Boolean,
        compactTop: Boolean = false
    ) {
        val nameY = if (compactTop) sy(470f) else if (active) sy(760f) else sy(800f)
        val photoCenterY = if (active) sy(520f) else sy(520f)
        if (includePhoto) {
            drawContactPhotoOrInitial(canvas, sx(540f), photoCenterY, ss(122f), callerName, number)
        }
        drawCenteredText(
            canvas,
            callerName,
            sx(540f),
            nameY,
            if (compactTop) ss(68f) else ss(72f),
            Color.WHITE,
            true,
            "sans-serif-light"
        )
        drawCenteredText(
            canvas,
            formatNumberLine(number),
            sx(540f),
            nameY + sy(102f),
            ss(42f),
            Color.rgb(240, 215, 209),
            false,
            "sans-serif-light"
        )
    }

    private fun drawIncomingFullScreen(canvas: Canvas, callerName: String, number: String, authorized: Boolean) {
        drawContactHeader(canvas, callerName, number, includePhoto = true, active = false)

        val redCx = sx(220f)
        val midCx = sx(540f)
        val greenCx = sx(860f)
        val iconCy = sy(1950f)
        val drag = incomingDragDx.coerceIn(-sx(265f), sx(265f))
        val dragAbs = abs(drag)
        if (dragAbs > ss(8f)) {
            paint.color = if (drag > 0f) Color.argb(72, 240, 215, 209) else Color.argb(78, 237, 44, 46)
            val guideLeft = min(midCx, midCx + drag) - ss(18f)
            val guideRight = max(midCx, midCx + drag) + ss(18f)
            canvas.drawRoundRect(
                RectF(guideLeft, iconCy - ss(18f), guideRight, iconCy + ss(18f)),
                ss(18f),
                ss(18f),
                paint
            )
        }
        drawPhoneGlyph(canvas, redCx, iconCy, ss(60f), Color.rgb(237, 44, 46), 135f)
        drawChevron(canvas, sx(380f), iconCy, ss(36f), Color.argb(188, 240, 215, 209), left = true)
        drawQuickReplyRing(canvas, midCx + drag, iconCy, ss(78f))
        drawChevron(canvas, sx(700f), iconCy, ss(36f), Color.argb(188, 240, 215, 209), left = false)
        drawPhoneGlyph(canvas, greenCx, iconCy, ss(64f), Color.rgb(255, 246, 236), 0f)

        drawCenteredText(canvas, "Kapat ve yanıtla", midCx, sy(2157f), ss(43f), Color.rgb(255, 246, 236), false, "sans-serif-light")
        strokePaint.color = Color.argb(170, 240, 215, 209)
        strokePaint.strokeWidth = ss(5f)
        strokePaint.style = Paint.Style.STROKE
        strokePaint.strokeCap = Paint.Cap.ROUND
        canvas.drawLine(midCx - ss(44f), sy(2212f), midCx + ss(44f), sy(2212f), strokePaint)
        strokePaint.style = Paint.Style.FILL

        addTouch(redCx, iconCy, ss(105f)) { NovaCallAuthorityGuard.registerUserCallAction("reject"); NovaCallControlBridge.rejectRingingCall(); invalidate() }
        addTouch(greenCx, iconCy, ss(105f)) { NovaCallAuthorityGuard.registerUserCallAction("answer"); NovaCallControlBridge.answerRingingCall(); invalidate() }
        addTouch(midCx, iconCy, ss(165f)) { NovaCallAuthorityGuard.registerUserCallAction("quick_message"); quickReplyVisible = true; invalidate() }
        addRectTouch(RectF(sx(300f), sy(1818f), sx(780f), sy(2252f))) {
            NovaCallAuthorityGuard.registerUserCallAction("quick_message")
            quickReplyVisible = true
            invalidate()
        }

        if (authorized) {
            drawSmallChip(canvas, sx(540f), sy(1015f), "Nova cevaplayabilir")
            addRectTouch(RectF(sx(340f), sy(970f), sx(740f), sy(1055f))) {
                NovaCallAuthorityGuard.registerUserCallAction("handoff")
                NovaCallControlBridge.answerRingingCall()
                NovaCallAuthorityGuard.registerUserCallAction("handoff")
                NovaCallControlBridge.handOverToNova()
                invalidate()
            }
        }
    }

    private fun drawActiveCall(
        canvas: Canvas,
        callerName: String,
        number: String,
        isMuted: Boolean,
        isHolding: Boolean,
        authorized: Boolean,
        isSpeaker: Boolean
    ) {
        drawContactHeader(canvas, callerName, number, includePhoto = true, active = true)
        drawHdAndTimer(canvas, sy(982f))
        val xs = floatArrayOf(sx(210f), sx(540f), sx(870f))
        val ys = floatArrayOf(sy(1390f), sy(1650f))
        val recording = NovaCallControlBridge.isCallRecording()
        drawControl(canvas, xs[0], ys[0], if (recording) "Kaydı durdur" else "Kayda başla", "record") {
            NovaCallAuthorityGuard.registerUserCallAction("record")
            val result = NovaCallControlBridge.toggleCallRecording()
            showToast(result["message"] as? String ?: "Kayıt durumu değiştirildi.")
            invalidate()
        }
        drawControl(canvas, xs[1], ys[0], if (isMuted) "Sesi aç" else "Sesi kapat", "mute") {
            NovaCallAuthorityGuard.registerUserCallAction("mute"); NovaCallControlBridge.toggleMuted(); invalidate()
        }
        drawControl(canvas, xs[2], ys[0], if (isHolding) "Devam et" else "Beklet", "pause") {
            NovaCallAuthorityGuard.registerUserCallAction("hold"); NovaCallControlBridge.toggleHold(); invalidate()
        }
        drawControl(canvas, xs[0], ys[1], "Net Arama", "net") {
            NovaCallAuthorityGuard.registerUserCallAction("net_call")
            val result = NovaCallControlBridge.openClearCallSettings()
            showToast(result["message"] as? String ?: "Çağrı/ağ ayarları açıldı.")
            invalidate()
        }
        drawControl(canvas, xs[1], ys[1], "Çağrı ekle", "plus") {
            NovaCallAuthorityGuard.registerUserCallAction("add_call"); activity.startActivity(NovaDialerActivity.keypadIntent(activity))
        }
        drawControl(canvas, xs[2], ys[1], "Diğer", "down") {
            morePageVisible = true
            invalidate()
        }
        if (authorized) {
            drawSmallChip(canvas, sx(540f), sy(1080f), "Nova hazır")
            addRectTouch(RectF(sx(360f), sy(1038f), sx(720f), sy(1112f))) {
                NovaCallAuthorityGuard.registerUserCallAction("handoff"); NovaCallControlBridge.handOverToNova()
                invalidate()
            }
        }
        drawBottomBar(canvas, isSpeakerOn = isSpeaker)
    }

    private fun drawMorePage(canvas: Canvas, callerName: String, number: String, authorized: Boolean, isMuted: Boolean, isSpeaker: Boolean) {
        drawContactHeader(canvas, callerName, number, includePhoto = false, active = true, compactTop = true)
        drawHdAndTimer(canvas, sy(690f))
        val xs = floatArrayOf(sx(210f), sx(540f), sx(870f))
        val y = sy(1450f)
        drawControl(canvas, xs[0], y, "Görüntülü Ar...", "video") {
            NovaCallAuthorityGuard.registerUserCallAction("video")
            val result = NovaCallControlBridge.requestVideoUpgrade()
            showToast(result["message"] as? String ?: "Görüntülü arama isteği gönderildi.")
            invalidate()
        }
        drawControl(canvas, xs[1], y, "Kişiler", "contacts") { activity.startActivity(NovaDialerActivity.contactsIntent(activity)) }
        drawControl(canvas, xs[2], y, "Diğer", "up") { morePageVisible = false; invalidate() }
        if (authorized) {
            drawControl(canvas, xs[1], sy(1710f), if (isMuted) "Kontrol bende" else "Nova devralsın", "more") {
                if (isMuted) {
                    NovaCallAuthorityGuard.registerUserCallAction("return_to_user")
                    NovaCallControlBridge.handOverToUser()
                } else {
                    NovaCallAuthorityGuard.registerUserCallAction("handoff")
                    NovaCallControlBridge.handOverToNova()
                }
                invalidate()
            }
        }
        drawBottomBar(canvas, isSpeakerOn = isSpeaker)
    }

    private fun drawKeypadScreen(canvas: Canvas, callerName: String, number: String, isSpeaker: Boolean) {
        drawContactHeader(canvas, callerName, number, includePhoto = false, active = true, compactTop = true)
        drawHdAndTimer(canvas, sy(690f))
        if (keypadBuffer.isNotEmpty()) {
            drawCenteredText(canvas, keypadBuffer.toString(), sx(540f), sy(790f), ss(42f), Color.WHITE, false, "sans-serif-light")
        }
        val xs = floatArrayOf(sx(210f), sx(540f), sx(870f))
        val ys = floatArrayOf(sy(1008f), sy(1238f), sy(1468f), sy(1698f))
        val entries = arrayOf(
            "1" to "♧", "2" to "ABC", "3" to "DEF",
            "4" to "GHI", "5" to "JKL", "6" to "MNO",
            "7" to "PQRS", "8" to "TUV", "9" to "WXYZ",
            "*" to "", "0" to "+", "#" to ""
        )
        entries.forEachIndexed { index, pair ->
            val col = index % 3
            val row = index / 3
            val cx = xs[col]
            val cy = ys[row]
            drawCenteredText(canvas, pair.first, cx, cy, ss(76f), Color.WHITE, false, "sans-serif-light")
            if (pair.second.isNotEmpty()) {
                drawCenteredText(canvas, pair.second, cx, cy + sy(54f), ss(30f), Color.argb(150, 236, 239, 244), false, "sans-serif")
            }
            addRectTouch(RectF(cx - ss(90f), cy - ss(85f), cx + ss(90f), cy + ss(85f))) {
                val digit = pair.first[0]
                keypadBuffer.append(digit)
                NovaCallAuthorityGuard.registerUserCallAction("dtmf"); NovaCallControlBridge.sendDtmfTone(digit)
                invalidate()
            }
        }
        drawBottomBar(canvas, keypadMode = true, isSpeakerOn = isSpeaker)
    }

    private fun drawBottomBar(canvas: Canvas, keypadMode: Boolean = false, isSpeakerOn: Boolean = false) {
        val cy = sy(2055f)
        val leftX = sx(210f)
        val midX = sx(540f)
        val rightX = sx(870f)
        if (isSpeakerOn) {
            paint.color = Color.argb(74, 237, 44, 46)
            canvas.drawCircle(leftX, cy, ss(64f), paint)
        }
        drawIcon(canvas, leftX, cy, "speaker", if (isSpeakerOn) Color.rgb(237, 44, 46) else Color.WHITE, ss(64f))
        addTouch(leftX, cy, ss(95f)) { NovaCallAuthorityGuard.registerUserCallAction("speaker"); NovaCallControlBridge.toggleSpeaker(); invalidate() }

        paint.color = Color.rgb(237, 44, 46)
        canvas.drawCircle(midX, cy, ss(92f), paint)
        drawPhoneGlyph(canvas, midX, cy + ss(2f), ss(66f), Color.WHITE, 135f)
        addTouch(midX, cy, ss(115f)) { NovaCallAuthorityGuard.registerUserCallAction("hangup"); NovaCallControlBridge.disconnectCurrentCall(); invalidate() }

        drawIcon(canvas, rightX, cy, "keypad", if (keypadMode) Color.rgb(237, 44, 46) else Color.WHITE, ss(66f))
        addTouch(rightX, cy, ss(95f)) {
            keypadVisible = !keypadVisible
            morePageVisible = false
            invalidate()
        }
    }

    private fun drawQuickReplySheet(canvas: Canvas, number: String) {
        paint.color = Color.argb(120, 0, 0, 0)
        canvas.drawRect(0f, 0f, width.toFloat(), height.toFloat(), paint)
        val sheet = RectF(sx(60f), sy(1152f), sx(1020f), sy(2256f))
        paint.color = Color.rgb(255, 248, 241)
        canvas.drawRoundRect(sheet, ss(48f), ss(48f), paint)
        drawLeftText(canvas, "Mesajla yanıtla", sheet.left + sx(50f), sheet.top + sy(105f), ss(43f), Color.rgb(138, 59, 59), true)
        val templates = arrayOf(
            "Üzgünüm, şu an konuşamam",
            "Şu an konuşamam. Lütfen bana\nmesaj atın.",
            "Yoldayım",
            "Toplantıdayım. Daha sonra\narayacağım.",
            "Özel"
        )
        val rowTops = floatArrayOf(1320f, 1495f, 1725f, 1888f, 2170f)
        templates.forEachIndexed { i, text ->
            val y = sy(rowTops[i])
            drawLeftMultiline(canvas, text, sheet.left + sx(50f), y, ss(48f), Color.rgb(42, 7, 9))
            addRectTouch(RectF(sheet.left, y - sy(80f), sheet.right, y + sy(if (text.contains("\n")) 140f else 90f))) {
                quickReplyVisible = false
                if (templates[i] == "Özel") {
                    openSms(number, "")
                } else {
                    NovaCallAuthorityGuard.registerUserCallAction("quick_message")
                    NovaCallControlBridge.rejectRingingCall()
                    openSms(number, templates[i].replace("\n", " "))
                }
                invalidate()
            }
        }
        addRectTouch(RectF(0f, 0f, width.toFloat(), sheet.top - sy(20f))) { quickReplyVisible = false; invalidate() }
    }

    private fun drawHdAndTimer(canvas: Canvas, baseline: Float) {
        val timer = if (localActiveStartedAt > 0L) formatDuration(System.currentTimeMillis() - localActiveStartedAt) else "00:00"
        val groupCenter = sx(540f)
        val hdRect = RectF(groupCenter - sx(104f), baseline - sy(38f), groupCenter - sx(48f), baseline + sy(10f))
        strokePaint.style = Paint.Style.STROKE
        strokePaint.strokeWidth = ss(4f)
        strokePaint.color = Color.rgb(240, 215, 209)
        canvas.drawRoundRect(hdRect, ss(6f), ss(6f), strokePaint)
        strokePaint.style = Paint.Style.FILL
        drawCenteredText(canvas, "HD", hdRect.centerX(), baseline, ss(34f), Color.rgb(240, 215, 209), true, "sans-serif")
        drawLeftText(canvas, timer, groupCenter - sx(32f), baseline + sy(2f), ss(52f), Color.WHITE, true)
    }

    private fun drawContactPhotoOrInitial(canvas: Canvas, cx: Float, cy: Float, radius: Float, callerName: String, number: String) {
        val bitmap = resolveContactBitmap(number)
        if (bitmap != null) {
            val save = canvas.save()
            val path = Path().apply { addCircle(cx, cy, radius, Path.Direction.CW) }
            canvas.clipPath(path)
            val src = Rect(0, 0, bitmap.width, bitmap.height)
            val side = min(bitmap.width, bitmap.height)
            val srcSquare = Rect((bitmap.width - side) / 2, (bitmap.height - side) / 2, (bitmap.width + side) / 2, (bitmap.height + side) / 2)
            val dst = RectF(cx - radius, cy - radius, cx + radius, cy + radius)
            canvas.drawBitmap(bitmap, srcSquare, dst, paint)
            canvas.restoreToCount(save)
        } else {
            paint.color = Color.rgb(183, 48, 47)
            canvas.drawCircle(cx, cy, radius, paint)
            drawCenteredText(canvas, callerInitial(callerName), cx, cy + radius * 0.34f, radius * 0.72f, Color.WHITE, true, "sans-serif")
        }
    }

    private fun resolveCallerDisplayName(number: String, stateName: String): String {
        val cleanedNumber = number.trim()
        val cleanedStateName = stateName.trim()
        if (cleanedNumber == lastNumberForName && resolvedCallerNameCache.isNotBlank()) {
            return resolvedCallerNameCache
        }
        val resolved = NovaCallContactResolver.resolveDisplayName(
            context = context,
            rawNumber = cleanedNumber,
            telecomDisplayName = cleanedStateName
        ).trim().ifBlank { cleanedNumber.ifBlank { "Bilinmeyen" } }
        lastNumberForName = cleanedNumber
        resolvedCallerNameCache = resolved
        return resolved
    }

    private fun resolveContactBitmap(number: String): Bitmap? {
        if (number.isBlank()) return null
        if (number == lastNumberForPhoto) return contactBitmap
        lastNumberForPhoto = number
        contactBitmap = null
        var cursor: Cursor? = null
        try {
            val lookupUri = Uri.withAppendedPath(ContactsContract.PhoneLookup.CONTENT_FILTER_URI, Uri.encode(number))
            cursor = context.contentResolver.query(
                lookupUri,
                arrayOf(ContactsContract.PhoneLookup.PHOTO_URI),
                null,
                null,
                null
            )
            if (cursor?.moveToFirst() == true) {
                val value = cursor?.getString(0).orEmpty()
                if (value.isNotBlank()) {
                    context.contentResolver.openInputStream(Uri.parse(value))?.use { stream ->
                        contactBitmap = BitmapFactory.decodeStream(stream)
                    }
                }
            }
        } catch (_: Throwable) {
            contactBitmap = null
        } finally {
            try { cursor?.close() } catch (_: Throwable) {}
        }
        return contactBitmap
    }

    private fun drawControl(canvas: Canvas, cx: Float, cy: Float, label: String, icon: String, action: () -> Unit) {
        drawIcon(canvas, cx, cy, icon, Color.rgb(255, 246, 236), ss(62f))
        drawCenteredText(canvas, label, cx, cy + sy(92f), ss(42f), Color.rgb(240, 215, 209), false, "sans-serif-light")
        addRectTouch(RectF(cx - ss(145f), cy - ss(78f), cx + ss(145f), cy + ss(135f)), action)
    }

    private fun drawIcon(canvas: Canvas, cx: Float, cy: Float, type: String, color: Int, size: Float) {
        iconPaint.color = color
        iconPaint.style = Paint.Style.STROKE
        iconPaint.strokeWidth = size * 0.075f
        iconPaint.strokeCap = Paint.Cap.ROUND
        iconPaint.strokeJoin = Paint.Join.ROUND
        when (type) {
            "speaker" -> {
                val p = Path()
                p.moveTo(cx - size * 0.36f, cy + size * 0.10f)
                p.lineTo(cx - size * 0.16f, cy + size * 0.10f)
                p.lineTo(cx + size * 0.10f, cy + size * 0.30f)
                p.lineTo(cx + size * 0.10f, cy - size * 0.30f)
                p.lineTo(cx - size * 0.16f, cy - size * 0.10f)
                p.lineTo(cx - size * 0.36f, cy - size * 0.10f)
                canvas.drawPath(p, iconPaint)
                canvas.drawArc(RectF(cx + size * 0.02f, cy - size * 0.34f, cx + size * 0.52f, cy + size * 0.34f), -42f, 84f, false, iconPaint)
            }
            "keypad" -> {
                iconPaint.style = Paint.Style.FILL
                for (r in 0..2) for (c in 0..2) {
                    canvas.drawCircle(cx + (c - 1) * size * 0.28f, cy + (r - 1) * size * 0.28f, size * 0.052f, iconPaint)
                }
                canvas.drawCircle(cx, cy + size * 0.56f, size * 0.052f, iconPaint)
            }
            "mute" -> {
                canvas.drawRoundRect(RectF(cx - size * 0.17f, cy - size * 0.34f, cx + size * 0.17f, cy + size * 0.14f), size * 0.12f, size * 0.12f, iconPaint)
                canvas.drawLine(cx - size * 0.36f, cy + size * 0.02f, cx + size * 0.36f, cy + size * 0.02f, iconPaint)
                canvas.drawLine(cx, cy + size * 0.16f, cx, cy + size * 0.38f, iconPaint)
                canvas.drawLine(cx - size * 0.18f, cy + size * 0.38f, cx + size * 0.18f, cy + size * 0.38f, iconPaint)
                canvas.drawLine(cx - size * 0.43f, cy - size * 0.43f, cx + size * 0.43f, cy + size * 0.43f, iconPaint)
            }
            "pause" -> {
                iconPaint.strokeWidth = size * 0.09f
                canvas.drawLine(cx - size * 0.18f, cy - size * 0.34f, cx - size * 0.18f, cy + size * 0.34f, iconPaint)
                canvas.drawLine(cx + size * 0.18f, cy - size * 0.34f, cx + size * 0.18f, cy + size * 0.34f, iconPaint)
            }
            "plus" -> {
                iconPaint.strokeWidth = size * 0.07f
                canvas.drawLine(cx - size * 0.38f, cy, cx + size * 0.38f, cy, iconPaint)
                canvas.drawLine(cx, cy - size * 0.38f, cx, cy + size * 0.38f, iconPaint)
            }
            "down" -> drawChevron(canvas, cx, cy, size * 0.60f, color, left = false, vertical = true)
            "up" -> drawChevron(canvas, cx, cy, size * 0.60f, color, left = false, vertical = true, up = true)
            "record" -> {
                iconPaint.style = Paint.Style.FILL
                val bars = floatArrayOf(0.24f, 0.44f, 0.60f, 0.44f, 0.24f)
                bars.forEachIndexed { i, h ->
                    val x = cx + (i - 2) * size * 0.16f
                    canvas.drawRoundRect(RectF(x - size * 0.035f, cy - size * h, x + size * 0.035f, cy + size * h), size * 0.02f, size * 0.02f, iconPaint)
                }
            }
            "net" -> {
                drawPhoneGlyph(canvas, cx - size * 0.02f, cy, size * 0.72f, color, -35f)
                iconPaint.style = Paint.Style.FILL
                canvas.drawCircle(cx + size * 0.38f, cy - size * 0.30f, size * 0.045f, iconPaint)
                canvas.drawCircle(cx + size * 0.50f, cy - size * 0.42f, size * 0.032f, iconPaint)
            }
            "video" -> {
                canvas.drawRoundRect(RectF(cx - size * 0.36f, cy - size * 0.22f, cx + size * 0.18f, cy + size * 0.22f), size * 0.08f, size * 0.08f, iconPaint)
                val p = Path()
                p.moveTo(cx + size * 0.18f, cy - size * 0.12f)
                p.lineTo(cx + size * 0.48f, cy - size * 0.30f)
                p.lineTo(cx + size * 0.48f, cy + size * 0.30f)
                p.lineTo(cx + size * 0.18f, cy + size * 0.12f)
                canvas.drawPath(p, iconPaint)
            }
            "contacts" -> {
                iconPaint.style = Paint.Style.FILL
                canvas.drawCircle(cx, cy - size * 0.16f, size * 0.16f, iconPaint)
                canvas.drawRoundRect(RectF(cx - size * 0.34f, cy + size * 0.08f, cx + size * 0.34f, cy + size * 0.40f), size * 0.16f, size * 0.16f, iconPaint)
            }
            else -> {
                iconPaint.style = Paint.Style.FILL
                for (i in 0..2) canvas.drawCircle(cx + (i - 1) * size * 0.22f, cy, size * 0.055f, iconPaint)
            }
        }
        iconPaint.style = Paint.Style.FILL
    }

    private fun drawPhoneGlyph(canvas: Canvas, cx: Float, cy: Float, size: Float, color: Int, rotation: Float) {
        val save = canvas.save()
        canvas.rotate(rotation, cx, cy)
        iconPaint.color = color
        iconPaint.style = Paint.Style.STROKE
        iconPaint.strokeWidth = size * 0.22f
        iconPaint.strokeCap = Paint.Cap.ROUND
        val r = RectF(cx - size * 0.48f, cy - size * 0.34f, cx + size * 0.48f, cy + size * 0.52f)
        canvas.drawArc(r, 205f, 130f, false, iconPaint)
        canvas.restoreToCount(save)
        iconPaint.style = Paint.Style.FILL
    }

    private fun drawQuickReplyRing(canvas: Canvas, cx: Float, cy: Float, r: Float) {
        strokePaint.style = Paint.Style.STROKE
        strokePaint.strokeCap = Paint.Cap.ROUND
        strokePaint.strokeWidth = ss(7f)
        strokePaint.color = Color.rgb(255, 246, 236)
        canvas.drawCircle(cx, cy, r, strokePaint)
        strokePaint.strokeWidth = ss(4f)
        strokePaint.color = Color.argb(176, 237, 44, 46)
        canvas.drawCircle(cx, cy, r * 0.70f, strokePaint)
        strokePaint.style = Paint.Style.FILL
    }

    private fun drawChevron(canvas: Canvas, cx: Float, cy: Float, size: Float, color: Int, left: Boolean, vertical: Boolean = false, up: Boolean = false) {
        iconPaint.color = color
        iconPaint.style = Paint.Style.STROKE
        iconPaint.strokeWidth = size * 0.12f
        iconPaint.strokeCap = Paint.Cap.ROUND
        iconPaint.strokeJoin = Paint.Join.ROUND
        val p = Path()
        if (vertical) {
            if (up) {
                p.moveTo(cx - size * 0.45f, cy + size * 0.20f)
                p.lineTo(cx, cy - size * 0.25f)
                p.lineTo(cx + size * 0.45f, cy + size * 0.20f)
            } else {
                p.moveTo(cx - size * 0.45f, cy - size * 0.20f)
                p.lineTo(cx, cy + size * 0.25f)
                p.lineTo(cx + size * 0.45f, cy - size * 0.20f)
            }
        } else if (left) {
            p.moveTo(cx + size * 0.25f, cy - size * 0.45f)
            p.lineTo(cx - size * 0.25f, cy)
            p.lineTo(cx + size * 0.25f, cy + size * 0.45f)
        } else {
            p.moveTo(cx - size * 0.25f, cy - size * 0.45f)
            p.lineTo(cx + size * 0.25f, cy)
            p.lineTo(cx - size * 0.25f, cy + size * 0.45f)
        }
        canvas.drawPath(p, iconPaint)
        iconPaint.style = Paint.Style.FILL
    }

    private fun drawSmallChip(canvas: Canvas, cx: Float, cy: Float, text: String) {
        textPaint.textSize = ss(28f)
        textPaint.typeface = Typeface.create("sans-serif", Typeface.NORMAL)
        val w = textPaint.measureText(text) + ss(42f)
        val rect = RectF(cx - w / 2f, cy - ss(28f), cx + w / 2f, cy + ss(22f))
        paint.color = Color.argb(64, 255, 255, 255)
        canvas.drawRoundRect(rect, ss(25f), ss(25f), paint)
        drawCenteredText(canvas, text, cx, cy + ss(10f), ss(27f), Color.WHITE, false, "sans-serif")
    }

    private fun drawCenteredText(canvas: Canvas, text: String, cx: Float, baseline: Float, size: Float, color: Int, bold: Boolean, family: String) {
        textPaint.color = color
        textPaint.textSize = size
        textPaint.textAlign = Paint.Align.CENTER
        textPaint.typeface = Typeface.create(family, if (bold) Typeface.BOLD else Typeface.NORMAL)
        textPaint.isSubpixelText = true
        canvas.drawText(text, cx, baseline, textPaint)
    }

    private fun drawLeftText(canvas: Canvas, text: String, x: Float, baseline: Float, size: Float, color: Int, bold: Boolean) {
        textPaint.color = color
        textPaint.textSize = size
        textPaint.textAlign = Paint.Align.LEFT
        textPaint.typeface = Typeface.create("sans-serif", if (bold) Typeface.BOLD else Typeface.NORMAL)
        textPaint.isSubpixelText = true
        canvas.drawText(text, x, baseline, textPaint)
    }

    private fun drawLeftMultiline(canvas: Canvas, text: String, x: Float, baseline: Float, size: Float, color: Int) {
        text.split("\n").forEachIndexed { index, line ->
            drawLeftText(canvas, line, x, baseline + index * size * 1.24f, size, color, false)
        }
    }

    private fun formatNumberLine(number: String): String {
        val base = formatPhoneForDisplay(number).ifBlank { "Bilinmeyen numara" }
        return if (number.isNotBlank()) "$base | Türkiye" else base
    }

    private fun formatPhoneForDisplay(raw: String): String {
        val value = raw.trim()
        if (value.isEmpty()) return ""
        val digits = value.filter { it.isDigit() }
        return when {
            value.startsWith("+90") && digits.length >= 12 -> {
                val national = digits.takeLast(10)
                "+90 ${national.substring(0, 3)} ${national.substring(3, 6)} ${national.substring(6, 8)} ${national.substring(8, 10)}"
            }
            value.startsWith("0") && digits.length == 11 -> {
                "${digits.substring(0, 4)} ${digits.substring(4, 7)} ${digits.substring(7, 9)} ${digits.substring(9, 11)}"
            }
            digits.length == 10 -> {
                "+90 ${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 8)} ${digits.substring(8, 10)}"
            }
            else -> value
        }
    }

    private fun formatDuration(elapsedMs: Long): String {
        val safe = elapsedMs.coerceAtLeast(0L)
        val minutes = TimeUnit.MILLISECONDS.toMinutes(safe)
        val seconds = TimeUnit.MILLISECONDS.toSeconds(safe) % 60
        return String.format(Locale.US, "%02d:%02d", minutes, seconds)
    }

    private fun callerInitial(value: String): String =
        value.trim().firstOrNull { it.isLetterOrDigit() }?.uppercaseChar()?.toString() ?: "?"

    private fun openSms(number: String, body: String) {
        val smsIntent = Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:${Uri.encode(number)}"))
        if (body.isNotBlank()) smsIntent.putExtra("sms_body", body)
        runCatching { activity.startActivity(smsIntent) }
    }

    private fun showToast(text: String) {
        android.widget.Toast.makeText(context, text, android.widget.Toast.LENGTH_SHORT).show()
    }

    private fun addTouch(cx: Float, cy: Float, radius: Float, action: () -> Unit) {
        addRectTouch(RectF(cx - radius, cy - radius, cx + radius, cy + radius), action)
    }

    private fun addRectTouch(rect: RectF, action: () -> Unit) {
        touchRegions.add(rect to action)
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                incomingDownX = event.x
                incomingDownY = event.y
                incomingDragDx = 0f
                val state = NovaCallStateBridge.getState()
                incomingGestureTracking = state["isRinging"] == true && event.y in sy(1760f)..sy(2268f)
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                if (incomingGestureTracking) {
                    incomingDragDx = event.x - incomingDownX
                    invalidate()
                }
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                val x = event.x
                val y = event.y
                val dragged = incomingDragDx
                val tracking = incomingGestureTracking
                incomingGestureTracking = false
                incomingDragDx = 0f
                if (tracking && event.actionMasked == MotionEvent.ACTION_UP && abs(dragged) >= sx(155f)) {
                    if (dragged > 0f) {
                        NovaCallAuthorityGuard.registerUserCallAction("answer")
                        NovaCallControlBridge.answerRingingCall()
                    } else {
                        NovaCallAuthorityGuard.registerUserCallAction("reject")
                        NovaCallControlBridge.rejectRingingCall()
                    }
                    invalidate()
                    return true
                }
                invalidate()
                if (event.actionMasked == MotionEvent.ACTION_CANCEL) return true
                for (i in touchRegions.indices.reversed()) {
                    val pair = touchRegions[i]
                    if (pair.first.contains(x, y)) {
                        pair.second.invoke()
                        return true
                    }
                }
                return true
            }
        }
        return true
    }
}
