package com.example.nova

import android.animation.Animator
import android.animation.AnimatorSet
import android.animation.ObjectAnimator
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.animation.AccelerateDecelerateInterpolator
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.core.graphics.toColorInt
import kotlin.math.cos
import kotlin.math.roundToInt
import kotlin.math.sin

// NOVA_APK_LOCAL_OVERLAY_V2
class NovaOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var rootView: FrameLayout? = null
    private var orbContainer: FrameLayout? = null
    private var auraView: View? = null
    private var shellView: View? = null
    private var cloudView: View? = null
    private var coreGlowView: View? = null
    private var coreView: View? = null
    private val petalViews = mutableListOf<View>()
    private val orbitViews = mutableListOf<View>()
    private var titleView: TextView? = null
    private var statusView: TextView? = null
    private var progressBar: ProgressBar? = null
    private var params: WindowManager.LayoutParams? = null

    private var pulseAnimator: AnimatorSet? = null
    private var rotationAnimator: ObjectAnimator? = null
    private var orbitAnimator: AnimatorSet? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager
        createOverlayIfAllowed()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.getStringExtra(EXTRA_ACTION).orEmpty()

        when (action) {
            ACTION_SHOW_IDLE -> showState(
                title = "Nova",
                status = "Pasif • Dengede",
                palette = OverlayPalette(
                    core = "#F2FBFF",
                    glow = "#00E5FF",
                    shell = "#6C5CE7",
                    cloud = "#050912"
                ),
                pulseMode = PulseMode.IDLE,
                showProgress = false,
                progress = 0f
            )

            ACTION_SHOW_LISTENING -> showState(
                title = "Nova",
                status = "Aktif • Dinliyor",
                palette = OverlayPalette(
                    core = "#F2FBFF",
                    glow = "#00D084",
                    shell = "#00E5FF",
                    cloud = "#081827"
                ),
                pulseMode = PulseMode.LISTENING,
                showProgress = false,
                progress = 0f
            )

            ACTION_SHOW_SPEAKING -> showState(
                title = "Nova",
                status = "Konuşuyor • Enerji akışı",
                palette = OverlayPalette(
                    core = "#F2FBFF",
                    glow = "#00E5FF",
                    shell = "#6C5CE7",
                    cloud = "#050912"
                ),
                pulseMode = PulseMode.SPEAKING,
                showProgress = false,
                progress = 0f
            )

            ACTION_SHOW_SLEEPING -> showState(
                title = "Nova",
                status = "Pasif • Beklemede",
                palette = OverlayPalette(
                    core = "#9CB3C9",
                    glow = "#6C5CE7",
                    shell = "#081827",
                    cloud = "#050912"
                ),
                pulseMode = PulseMode.SLEEPING,
                showProgress = false,
                progress = 0f
            )

            ACTION_SHOW_CLONE_PROGRESS -> {
                val title = intent?.getStringExtra(EXTRA_TITLE).orEmpty()
                val status = intent?.getStringExtra(EXTRA_STATUS).orEmpty()
                val progress = intent?.getFloatExtra(EXTRA_PROGRESS, -1f) ?: -1f
                val textOpacity = intent?.getFloatExtra(EXTRA_TEXT_OPACITY, 0.98f) ?: 0.98f
                val shellOpacity = intent?.getFloatExtra(EXTRA_SHELL_OPACITY, 0.55f) ?: 0.55f
                val emotionLabel = intent?.getStringExtra(EXTRA_EMOTION_LABEL).orEmpty()
                val showEmotionChip = intent?.getBooleanExtra(EXTRA_SHOW_EMOTION_CHIP, false) ?: false

                showState(
                    title = if (title.isBlank()) "Nova" else title,
                    status = if (status.isBlank()) "Ses Klonlama" else status,
                    palette = OverlayPalette(
                        core = "#F2FBFF",
                        glow = "#00E5FF",
                        shell = "#6C5CE7",
                        cloud = "#050912"
                    ),
                    pulseMode = PulseMode.CLONE,
                    showProgress = true,
                    progress = progress,
                    textOpacity = textOpacity,
                    shellOpacity = shellOpacity,
                    emotionLabel = emotionLabel,
                    showEmotionChip = showEmotionChip
                )
            }

            ACTION_HIDE -> hideOverlay()
            ACTION_REMOVE -> {
                removeOverlay()
                stopSelf()
            }
        }

        return START_STICKY
    }

    override fun onDestroy() {
        cancelAnimations()
        removeOverlay()
        super.onDestroy()
    }

    private fun createOverlayIfAllowed() {
        if (!Settings.canDrawOverlays(this)) return
        if (rootView != null) return

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        params = WindowManager.LayoutParams(
            dp(178),
            WindowManager.LayoutParams.WRAP_CONTENT,
            type,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = 14
            y = 64
        }

        val root = FrameLayout(this).apply {
            alpha = 0f
            clipChildren = false
            clipToPadding = false
            setPadding(0, dp(6), 0, dp(10))
        }

        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            clipChildren = false
            clipToPadding = false
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER_HORIZONTAL
            )
        }

        val orb = FrameLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(dp(118), dp(118))
            clipChildren = false
            clipToPadding = false
        }

        val aura = View(this).apply {
            layoutParams = FrameLayout.LayoutParams(dp(106), dp(106), Gravity.CENTER)
            background = buildSoftCircle("#00E5FF".toColorInt(), 38)
            alpha = 0.48f
        }

        val shell = View(this).apply {
            layoutParams = FrameLayout.LayoutParams(dp(92), dp(92), Gravity.CENTER)
            background = buildSoftCircle("#6C5CE7".toColorInt(), 24)
            alpha = 0.55f
        }

        val cloud = View(this).apply {
            layoutParams = FrameLayout.LayoutParams(dp(72), dp(72), Gravity.CENTER)
            background = buildCloudCircle("#050912".toColorInt())
            alpha = 0.92f
        }

        val petals = mutableListOf<View>()
        repeat(6) { index ->
            val petal = View(this).apply {
                layoutParams = FrameLayout.LayoutParams(dp(90), dp(44), Gravity.CENTER)
                background = buildPetalDrawable("#6C5CE7".toColorInt())
                alpha = 0.58f
                rotation = index * 60f
                translationX = ((cos(Math.toRadians((index * 60).toDouble())) * dp(8))).toFloat()
                translationY = ((sin(Math.toRadians((index * 60).toDouble())) * dp(8))).toFloat()
            }
            petals += petal
            orb.addView(petal)
        }

        val coreGlow = View(this).apply {
            layoutParams = FrameLayout.LayoutParams(dp(44), dp(44), Gravity.CENTER)
            background = buildSoftCircle("#00D084".toColorInt(), 86)
            alpha = 0.96f
        }

        val core = View(this).apply {
            layoutParams = FrameLayout.LayoutParams(dp(24), dp(24), Gravity.CENTER)
            background = buildCoreDrawable("#F2FBFF".toColorInt())
            alpha = 1f
        }

        val orbits = mutableListOf<View>()
        val orbitConfigs = listOf(
            OrbitSpec(34, 0.0, 0.70f),
            OrbitSpec(30, 55.0, 0.58f),
            OrbitSpec(28, 118.0, 0.64f),
            OrbitSpec(24, 192.0, 0.52f),
            OrbitSpec(22, 264.0, 0.42f)
        )
        orbitConfigs.forEach { spec ->
            val dot = View(this).apply {
                layoutParams = FrameLayout.LayoutParams(dp(spec.sizeDp), dp(spec.sizeDp), Gravity.CENTER)
                background = buildOrbitDrawable("#9CB3C9".toColorInt(), spec.alpha)
                alpha = spec.alpha
            }
            placeOrbit(dot, spec.angleDeg)
            orbits += dot
            orb.addView(dot)
        }

        orb.addView(aura)
        orb.addView(shell)
        orb.addView(cloud)
        orb.addView(coreGlow)
        orb.addView(core)

        val labelCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(12), dp(6), dp(12), dp(8))
            background = buildLabelBackground()
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dp(2)
            }
        }

        val title = TextView(this).apply {
            text = "Nova"
            setTextColor(Color.WHITE)
            setTypeface(typeface, Typeface.BOLD)
            textSize = 11.5f
            gravity = Gravity.CENTER
            alpha = 0.98f
        }

        val status = TextView(this).apply {
            text = "Pasif • Dengede"
            setTextColor("#9CB3C9".toColorInt())
            textSize = 9.8f
            gravity = Gravity.CENTER
            alpha = 0.92f
        }

        val progress = ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal).apply {
            max = 100
            progress = 0
            isIndeterminate = false
            visibility = View.GONE
            alpha = 0.90f
            layoutParams = LinearLayout.LayoutParams(dp(104), dp(5)).apply {
                topMargin = dp(7)
            }
        }

        labelCard.addView(title)
        labelCard.addView(status)
        labelCard.addView(progress)

        content.addView(orb)
        content.addView(labelCard)
        root.addView(content)

        rootView = root
        orbContainer = orb
        auraView = aura
        shellView = shell
        cloudView = cloud
        coreGlowView = coreGlow
        coreView = core
        petalViews.clear()
        petalViews.addAll(petals)
        orbitViews.clear()
        orbitViews.addAll(orbits)
        titleView = title
        statusView = status
        progressBar = progress

        try {
            windowManager?.addView(root, params)
        } catch (_: Throwable) {
            rootView = null
            orbContainer = null
            auraView = null
            shellView = null
            cloudView = null
            coreGlowView = null
            coreView = null
            petalViews.clear()
            orbitViews.clear()
            titleView = null
            statusView = null
            progressBar = null
            params = null
        }
    }

    private fun showState(
        title: String,
        status: String,
        palette: OverlayPalette,
        pulseMode: PulseMode,
        showProgress: Boolean,
        progress: Float,
        textOpacity: Float = 0.98f,
        shellOpacity: Float = 0.55f,
        emotionLabel: String = "",
        showEmotionChip: Boolean = false
    ) {
        if (!Settings.canDrawOverlays(this)) return
        if (rootView == null) createOverlayIfAllowed()

        val root = rootView ?: return
        val aura = auraView ?: return
        val shell = shellView ?: return
        val cloud = cloudView ?: return
        val coreGlow = coreGlowView ?: return
        val core = coreView ?: return
        val titleText = titleView ?: return
        val statusText = statusView ?: return
        val bar = progressBar ?: return

        titleText.text = title
        statusText.text = if (showEmotionChip && emotionLabel.isNotBlank()) "$status • $emotionLabel" else status
        titleText.alpha = textOpacity.coerceIn(0.72f, 1.0f)
        statusText.alpha = (textOpacity * 0.96f).coerceIn(0.68f, 1.0f)

        aura.background = buildSoftCircle(palette.glow.toColorInt(), 34)
        shell.background = buildSoftCircle(palette.shell.toColorInt(), 22)
        shell.alpha = shellOpacity.coerceIn(0.44f, 0.92f)
        cloud.background = buildCloudCircle(palette.cloud.toColorInt())
        coreGlow.background = buildSoftCircle(palette.glow.toColorInt(), 82)
        core.background = buildCoreDrawable(palette.core.toColorInt())

        petalViews.forEachIndexed { index, view ->
            view.background = buildPetalDrawable(
                if (index % 2 == 0) palette.shell.toColorInt() else palette.glow.toColorInt()
            )
            view.alpha = if (pulseMode == PulseMode.SLEEPING) 0.38f else 0.58f
        }
        orbitViews.forEachIndexed { index, view ->
            val alpha = (0.34f + (index * 0.08f)).coerceAtMost(0.72f)
            view.background = buildOrbitDrawable(palette.core.toColorInt(), alpha)
            view.alpha = alpha
        }

        if (showProgress) {
            bar.visibility = View.VISIBLE
            if (progress < 0f) {
                bar.isIndeterminate = true
            } else {
                bar.isIndeterminate = false
                bar.progress = (progress.coerceIn(0f, 1f) * 100f).roundToInt()
            }
        } else {
            bar.visibility = View.GONE
            bar.isIndeterminate = false
            bar.progress = 0
        }

        root.animate().alpha(0.92f).setDuration(140).start()
        startAmbientMotion(pulseMode)
    }

    private fun startAmbientMotion(mode: PulseMode) {
        cancelAnimations()

        val orb = orbContainer ?: return
        val aura = auraView ?: return
        val shell = shellView ?: return
        val cloud = cloudView ?: return
        val coreGlow = coreGlowView ?: return
        val core = coreView ?: return

        val config = when (mode) {
            PulseMode.IDLE -> MotionConfig(1.025f, 1.055f, 3200L, 14000L, 0.010f)
            PulseMode.LISTENING -> MotionConfig(1.055f, 1.095f, 1900L, 9800L, 0.020f)
            PulseMode.SPEAKING -> MotionConfig(1.075f, 1.12f, 1350L, 7600L, 0.030f)
            PulseMode.SLEEPING -> MotionConfig(1.012f, 1.035f, 4200L, 17000L, 0.006f)
            PulseMode.CLONE -> MotionConfig(1.05f, 1.09f, 2100L, 9400L, 0.018f)
        }

        val animators = mutableListOf<Animator>()
        animators += ObjectAnimator.ofFloat(core, View.SCALE_X, 1f, config.coreScale, 1f)
        animators += ObjectAnimator.ofFloat(core, View.SCALE_Y, 1f, config.coreScale, 1f)
        animators += ObjectAnimator.ofFloat(coreGlow, View.SCALE_X, 1f, config.glowScale, 1f)
        animators += ObjectAnimator.ofFloat(coreGlow, View.SCALE_Y, 1f, config.glowScale, 1f)
        animators += ObjectAnimator.ofFloat(aura, View.ALPHA, 0.38f, 0.78f, 0.38f)
        animators += ObjectAnimator.ofFloat(shell, View.ALPHA, 0.24f, 0.54f, 0.24f)
        animators += ObjectAnimator.ofFloat(cloud, View.SCALE_X, 1f, 1.03f, 1f)
        animators += ObjectAnimator.ofFloat(cloud, View.SCALE_Y, 1f, 1.03f, 1f)

        petalViews.forEachIndexed { index, view ->
            val shift = if (index % 2 == 0) config.petalDrift else -config.petalDrift
            animators += ObjectAnimator.ofFloat(view, View.ROTATION, view.rotation, view.rotation + (10f * shift), view.rotation)
            animators += ObjectAnimator.ofFloat(view, View.SCALE_X, 1f, 1.05f + shift, 1f)
            animators += ObjectAnimator.ofFloat(view, View.SCALE_Y, 1f, 1.05f + shift, 1f)
        }

        pulseAnimator = AnimatorSet().apply {
            playTogether(animators)
            duration = config.pulseDuration
            interpolator = AccelerateDecelerateInterpolator()
        }
        pulseAnimator?.start()
        pulseAnimator?.addListener(loopingRestart { startAmbientMotion(mode) })

        rotationAnimator = ObjectAnimator.ofFloat(orb, View.ROTATION, 0f, 360f).apply {
            duration = config.rotationDuration
            repeatCount = ObjectAnimator.INFINITE
            interpolator = null
            start()
        }

        val orbitAnimators = mutableListOf<Animator>()
        orbitViews.forEachIndexed { index, view ->
            val baseScale = 1f + (index * 0.03f)
            orbitAnimators += ObjectAnimator.ofFloat(view, View.SCALE_X, 1f, baseScale + config.petalDrift, 1f)
            orbitAnimators += ObjectAnimator.ofFloat(view, View.SCALE_Y, 1f, baseScale + config.petalDrift, 1f)
            orbitAnimators += ObjectAnimator.ofFloat(view, View.ALPHA, view.alpha, (view.alpha + 0.16f).coerceAtMost(0.92f), view.alpha)
        }
        orbitAnimator = AnimatorSet().apply {
            playTogether(orbitAnimators)
            duration = (config.pulseDuration * 0.9f).roundToInt().toLong()
            interpolator = AccelerateDecelerateInterpolator()
        }
        orbitAnimator?.start()
        orbitAnimator?.addListener(loopingRestart { startOrbitPulse(mode) })
    }

    private fun startOrbitPulse(mode: PulseMode) {
        orbitAnimator?.removeAllListeners()
        orbitAnimator?.cancel()
        val config = when (mode) {
            PulseMode.IDLE -> MotionConfig(1.025f, 1.055f, 3200L, 14000L, 0.010f)
            PulseMode.LISTENING -> MotionConfig(1.055f, 1.095f, 1900L, 9800L, 0.020f)
            PulseMode.SPEAKING -> MotionConfig(1.075f, 1.12f, 1350L, 7600L, 0.030f)
            PulseMode.SLEEPING -> MotionConfig(1.012f, 1.035f, 4200L, 17000L, 0.006f)
            PulseMode.CLONE -> MotionConfig(1.05f, 1.09f, 2100L, 9400L, 0.018f)
        }
        val orbitAnimators = mutableListOf<Animator>()
        orbitViews.forEachIndexed { index, view ->
            val baseScale = 1f + (index * 0.02f)
            orbitAnimators += ObjectAnimator.ofFloat(view, View.SCALE_X, 1f, baseScale + config.petalDrift, 1f)
            orbitAnimators += ObjectAnimator.ofFloat(view, View.SCALE_Y, 1f, baseScale + config.petalDrift, 1f)
            orbitAnimators += ObjectAnimator.ofFloat(view, View.ALPHA, view.alpha, (view.alpha + 0.18f).coerceAtMost(0.92f), view.alpha)
        }
        orbitAnimator = AnimatorSet().apply {
            playTogether(orbitAnimators)
            duration = (config.pulseDuration * 0.92f).roundToInt().toLong()
            interpolator = AccelerateDecelerateInterpolator()
        }
        orbitAnimator?.start()
        orbitAnimator?.addListener(loopingRestart { startOrbitPulse(mode) })
    }

    private fun loopingRestart(onEnd: () -> Unit): Animator.AnimatorListener {
        return object : Animator.AnimatorListener {
            override fun onAnimationStart(animation: Animator) = Unit
            override fun onAnimationCancel(animation: Animator) = Unit
            override fun onAnimationRepeat(animation: Animator) = Unit
            override fun onAnimationEnd(animation: Animator) {
                if (rootView != null) onEnd()
            }
        }
    }

    private fun cancelAnimations() {
        pulseAnimator?.removeAllListeners()
        pulseAnimator?.cancel()
        pulseAnimator = null

        rotationAnimator?.cancel()
        rotationAnimator = null

        orbitAnimator?.removeAllListeners()
        orbitAnimator?.cancel()
        orbitAnimator = null

        rootView?.rotation = 0f
        listOf(auraView, shellView, cloudView, coreGlowView, coreView).forEach { view ->
            view?.scaleX = 1f
            view?.scaleY = 1f
            view?.alpha = view?.alpha ?: 1f
        }
        petalViews.forEachIndexed { index, view ->
            view.scaleX = 1f
            view.scaleY = 1f
            view.rotation = index * 60f
        }
        orbitViews.forEach { view ->
            view.scaleX = 1f
            view.scaleY = 1f
        }
    }

    private fun hideOverlay() {
        cancelAnimations()
        rootView?.animate()?.alpha(0f)?.setDuration(150)?.start()
    }

    private fun removeOverlay() {
        cancelAnimations()
        val view = rootView ?: return
        try {
            windowManager?.removeView(view)
        } catch (_: Throwable) {
        } finally {
            rootView = null
            orbContainer = null
            auraView = null
            shellView = null
            cloudView = null
            coreGlowView = null
            coreView = null
            petalViews.clear()
            orbitViews.clear()
            titleView = null
            statusView = null
            progressBar = null
            params = null
        }
    }

    private fun placeOrbit(view: View, angleDeg: Double) {
        val radius = dp(24)
        view.translationX = (cos(Math.toRadians(angleDeg)) * radius).toFloat()
        view.translationY = (sin(Math.toRadians(angleDeg)) * radius).toFloat()
    }

    private fun buildSoftCircle(color: Int, alpha: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            gradientType = GradientDrawable.RADIAL_GRADIENT
            gradientRadius = dp(58).toFloat()
            colors = intArrayOf(
                applyAlpha(color, alpha),
                applyAlpha(color, (alpha * 0.42f).roundToInt()),
                applyAlpha(color, 0)
            )
        }
    }

    private fun buildCloudCircle(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            colors = intArrayOf(
                applyAlpha(color, 228),
                applyAlpha(color, 205),
                applyAlpha("#050912".toColorInt(), 240)
            )
            gradientType = GradientDrawable.RADIAL_GRADIENT
            gradientRadius = dp(44).toFloat()
        }
    }

    private fun buildCoreDrawable(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            colors = intArrayOf(
                applyAlpha(Color.WHITE, 255),
                applyAlpha(color, 250),
                applyAlpha("#6C5CE7".toColorInt(), 220)
            )
            gradientType = GradientDrawable.RADIAL_GRADIENT
            gradientRadius = dp(18).toFloat()
        }
    }

    private fun buildPetalDrawable(color: Int): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dp(30).toFloat()
            colors = intArrayOf(
                applyAlpha(color, 0),
                applyAlpha(color, 120),
                applyAlpha(color, 170),
                applyAlpha(color, 28)
            )
            orientation = GradientDrawable.Orientation.LEFT_RIGHT
        }
    }

    private fun buildOrbitDrawable(color: Int, alpha: Float): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            colors = intArrayOf(
                applyAlpha(Color.WHITE, 210),
                applyAlpha(color, (alpha * 255).roundToInt()),
                applyAlpha(color, 12)
            )
            gradientType = GradientDrawable.RADIAL_GRADIENT
            gradientRadius = dp(18).toFloat()
        }
    }

    private fun buildLabelBackground(): GradientDrawable {
        return GradientDrawable().apply {
            shape = GradientDrawable.RECTANGLE
            cornerRadius = dp(18).toFloat()
            colors = intArrayOf(
                "#1A00E5FF".toColorInt(),
                "#246C5CE7".toColorInt()
            )
            orientation = GradientDrawable.Orientation.TOP_BOTTOM
            setStroke(dp(1), "#5500E5FF".toColorInt())
        }
    }

    private fun applyAlpha(color: Int, alpha: Int): Int {
        return Color.argb(
            alpha.coerceIn(0, 255),
            Color.red(color),
            Color.green(color),
            Color.blue(color)
        )
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).roundToInt()

    private data class OverlayPalette(
        val core: String,
        val glow: String,
        val shell: String,
        val cloud: String
    )

    private data class MotionConfig(
        val coreScale: Float,
        val glowScale: Float,
        val pulseDuration: Long,
        val rotationDuration: Long,
        val petalDrift: Float
    )

    private data class OrbitSpec(
        val sizeDp: Int,
        val angleDeg: Double,
        val alpha: Float
    )

    private enum class PulseMode {
        IDLE,
        LISTENING,
        SPEAKING,
        SLEEPING,
        CLONE,
    }

    companion object {
        const val EXTRA_ACTION = "nova_overlay_action"
        const val EXTRA_TITLE = "nova_overlay_title"
        const val EXTRA_STATUS = "nova_overlay_status"
        const val EXTRA_PROGRESS = "nova_overlay_progress"
        const val EXTRA_TEXT_OPACITY = "nova_overlay_text_opacity"
        const val EXTRA_SHELL_OPACITY = "nova_overlay_shell_opacity"
        const val EXTRA_EMOTION_LABEL = "nova_overlay_emotion_label"
        const val EXTRA_SHOW_EMOTION_CHIP = "nova_overlay_show_emotion_chip"

        const val ACTION_SHOW_IDLE = "show_idle"
        const val ACTION_SHOW_LISTENING = "show_listening"
        const val ACTION_SHOW_SPEAKING = "show_speaking"
        const val ACTION_SHOW_SLEEPING = "show_sleeping"
        const val ACTION_SHOW_CLONE_PROGRESS = "show_clone_progress"
        const val ACTION_HIDE = "hide"
        const val ACTION_REMOVE = "remove"
    }
}
