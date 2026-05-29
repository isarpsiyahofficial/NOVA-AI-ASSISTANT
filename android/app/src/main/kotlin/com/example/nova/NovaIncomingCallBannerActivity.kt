package com.example.nova

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.*
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.Window
import android.view.WindowManager
import kotlin.math.abs
import kotlin.math.min

class NovaIncomingCallBannerActivity : Activity() {

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var bannerView: HiosIncomingBannerView

    private val refreshRunnable = object : Runnable {
        override fun run() {
            renderOrFinish()
            handler.postDelayed(this, 300)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        configureWindow()
        NovaCallControlBridge.initialize(applicationContext)
        bannerView = HiosIncomingBannerView(this, this)
        setContentView(bannerView)
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

    private fun renderOrFinish() {
        val state = NovaCallStateBridge.getState()
        if (state["isRinging"] != true) {
            finish()
            return
        }
        bannerView.invalidate()
    }

    private fun configureWindow() {
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        window.setBackgroundDrawable(android.graphics.drawable.ColorDrawable(Color.TRANSPARENT))
        window.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
        window.addFlags(
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
        )
        val params = window.attributes
        params.width = WindowManager.LayoutParams.MATCH_PARENT
        params.height = WindowManager.LayoutParams.WRAP_CONTENT
        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        // Android heads-up bildirimle çakışmaması için kompakt Nova banner aşağı alınır.
        params.y = dp(92)
        params.dimAmount = 0f
        window.attributes = params
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    companion object {
        fun launch(context: Context) {
            val intent = Intent(context, NovaIncomingCallBannerActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            context.startActivity(intent)
        }
    }
}

private class HiosIncomingBannerView(
    context: Context,
    private val activity: Activity
) : View(context) {

    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val iconPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private var downX = 0f
    private var downY = 0f
    private var dragDx = 0f
    private var trackingSlide = false
    private var lastNumberForName = ""
    private var resolvedNameCache = ""

    private fun ss(px: Float): Float = min(width / 1080f, 1f) * px
    private fun sx(px: Float): Float = width * (px / 1080f)

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val w = MeasureSpec.getSize(widthMeasureSpec)
        setMeasuredDimension(w, (w * 0.17f).toInt().coerceIn(dp(126), dp(156)))
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val state = NovaCallStateBridge.getState()
        val number = (state["number"] as? String).orEmpty()
        val caller = resolveCallerDisplayName(number, (state["callerDisplayName"] as? String).orEmpty())

        val box = RectF(sx(30f), ss(6f), width - sx(30f), height - ss(4f))
        val shader = LinearGradient(
            box.left,
            box.top,
            box.right,
            box.bottom,
            intArrayOf(Color.rgb(42, 7, 9), Color.rgb(94, 10, 12), Color.rgb(19, 4, 5)),
            floatArrayOf(0f, 0.58f, 1f),
            Shader.TileMode.CLAMP
        )
        paint.shader = shader
        canvas.drawRoundRect(box, ss(54f), ss(54f), paint)
        paint.shader = null
        iconPaint.style = Paint.Style.STROKE
        iconPaint.strokeWidth = ss(3f)
        iconPaint.color = Color.argb(150, 237, 44, 46)
        canvas.drawRoundRect(box, ss(54f), ss(54f), iconPaint)
        iconPaint.style = Paint.Style.FILL

        textPaint.textAlign = Paint.Align.LEFT
        textPaint.isSubpixelText = true
        textPaint.typeface = Typeface.create("sans-serif", Typeface.NORMAL)
        textPaint.color = Color.rgb(240, 215, 209)
        textPaint.textSize = ss(29f)
        canvas.drawText(number.ifBlank { "Gelen çağrı" }, box.left + ss(38f), box.top + ss(54f), textPaint)
        textPaint.typeface = Typeface.create("sans-serif", Typeface.BOLD)
        textPaint.color = Color.WHITE
        textPaint.textSize = ss(40f)
        canvas.drawText(caller, box.left + ss(38f), box.top + ss(106f), textPaint)

        val rejectX = width - ss(246f)
        val answerX = width - ss(84f)
        val cy = box.centerY()
        if (abs(dragDx) > ss(8f)) {
            paint.color = if (dragDx > 0f) Color.argb(82, 240, 215, 209) else Color.argb(86, 237, 44, 46)
            canvas.drawRoundRect(
                RectF(width - ss(330f), cy - ss(18f), width - ss(92f) + dragDx.coerceIn(-ss(120f), ss(120f)), cy + ss(18f)),
                ss(18f),
                ss(18f),
                paint
            )
        }
        paint.color = Color.rgb(237, 44, 46)
        canvas.drawCircle(rejectX, cy, ss(50f), paint)
        drawPhone(canvas, rejectX, cy, ss(46f), Color.WHITE, 135f)
        paint.color = Color.rgb(255, 246, 236)
        canvas.drawCircle(answerX, cy, ss(50f), paint)
        iconPaint.style = Paint.Style.STROKE
        iconPaint.strokeWidth = ss(3f)
        iconPaint.color = Color.argb(185, 237, 44, 46)
        canvas.drawCircle(answerX, cy, ss(50f), iconPaint)
        iconPaint.style = Paint.Style.FILL
        drawPhone(canvas, answerX, cy, ss(46f), Color.rgb(94, 10, 12), 0f)
    }

    private fun resolveCallerDisplayName(number: String, stateName: String): String {
        val cleanedNumber = number.trim()
        val cleanedStateName = stateName.trim()
        if (cleanedNumber == lastNumberForName && resolvedNameCache.isNotBlank()) {
            return resolvedNameCache
        }
        val resolved = NovaCallContactResolver.resolveDisplayName(
            context = context,
            rawNumber = cleanedNumber,
            telecomDisplayName = cleanedStateName
        ).trim().ifBlank { cleanedNumber.ifBlank { "Bilinmeyen" } }
        lastNumberForName = cleanedNumber
        resolvedNameCache = resolved
        return resolved
    }

    private fun drawPhone(canvas: Canvas, cx: Float, cy: Float, size: Float, color: Int, rotation: Float) {
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

    override fun onTouchEvent(event: MotionEvent): Boolean {
        val rejectX = width - ss(246f)
        val answerX = width - ss(84f)
        val cy = height / 2f
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downX = event.x
                downY = event.y
                dragDx = 0f
                trackingSlide = true
                return true
            }
            MotionEvent.ACTION_MOVE -> {
                if (trackingSlide) {
                    dragDx = event.x - downX
                    invalidate()
                }
                return true
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                val moved = dragDx
                trackingSlide = false
                dragDx = 0f
                if (event.actionMasked == MotionEvent.ACTION_CANCEL) {
                    invalidate()
                    return true
                }
                if (abs(moved) >= ss(96f)) {
                    if (moved > 0f) {
                        NovaCallAuthorityGuard.registerUserCallAction("answer")
                        NovaCallControlBridge.answerRingingCall()
                    } else {
                        NovaCallAuthorityGuard.registerUserCallAction("reject")
                        NovaCallControlBridge.rejectRingingCall()
                    }
                    activity.finish()
                    return true
                }
                if (distance(event.x, event.y, rejectX, cy) < ss(82f)) {
                    NovaCallAuthorityGuard.registerUserCallAction("reject")
                    NovaCallControlBridge.rejectRingingCall()
                    activity.finish()
                    return true
                }
                if (distance(event.x, event.y, answerX, cy) < ss(82f)) {
                    NovaCallAuthorityGuard.registerUserCallAction("answer")
                    NovaCallControlBridge.answerRingingCall()
                    activity.finish()
                    return true
                }
                NovaCallUiActivity.launch(activity)
                activity.finish()
                return true
            }
        }
        return true
    }

    private fun distance(x1: Float, y1: Float, x2: Float, y2: Float): Float {
        val dx = x1 - x2
        val dy = y1 - y2
        return kotlin.math.sqrt(dx * dx + dy * dy)
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
