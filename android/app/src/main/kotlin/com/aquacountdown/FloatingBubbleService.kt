package com.aquacountdown

import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import android.view.*
import android.view.animation.DecelerateInterpolator
import android.widget.FrameLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import kotlin.math.abs

/**
 * AquaCountdown Yüzen Buton Servisi
 *
 * Foreground Service olarak çalışır, ekranın sağ alt köşesinde
 * dairesel bir buton gösterir. Kullanıcı bu butona basarak
 * uygulamayı açmadan su kaydı ekleyebilir.
 *
 * Gerekli izin: SYSTEM_ALERT_WINDOW
 */
class FloatingBubbleService : Service() {

    companion object {
        const val NOTIFICATION_ID = 1001
        const val CHANNEL_ID = "aquacountdown_bubble"
        const val CHANNEL_NAME = "Su Takibi Aktif"
        const val ACTION_ADD_WATER = "com.aquacountdown.ADD_WATER"
        const val ACTION_SHOW_BUBBLE = "com.aquacountdown.SHOW_BUBBLE"
        const val ACTION_HIDE_BUBBLE = "com.aquacountdown.HIDE_BUBBLE"
        const val EXTRA_AMOUNT_ML = "amount_ml"
    }

    private lateinit var windowManager: WindowManager
    private lateinit var bubbleView: View
    private lateinit var radialMenuView: View
    private lateinit var prefs: SharedPreferences

    // Ekran boyutları
    private var screenWidth = 0
    private var screenHeight = 0

    // Butonun ekrandaki konumu
    private var bubbleX = 16
    private var bubbleY = 200

    // Sürükleme takibi
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var initialBubbleX = 0
    private var initialBubbleY = 0
    private var isDragging = false
    private var isLongPress = false

    // Nefes animasyonu
    private var breathAnimator: ValueAnimator? = null

    // Uzun basma zamanlayıcı
    private val longPressRunnable = Runnable {
        isLongPress = true
        vibrateDevice(50L)
        showRadialMenu()
    }
    private val longPressHandler = android.os.Handler(android.os.Looper.getMainLooper())

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(WaterWallpaperService.PREFS_NAME, MODE_PRIVATE)
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            windowManager.currentWindowMetrics.bounds
        } else {
            @Suppress("DEPRECATION")
            val dm = android.util.DisplayMetrics()
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.getMetrics(dm)
            android.graphics.Rect(0, 0, dm.widthPixels, dm.heightPixels)
        }
        screenWidth = display.width()
        screenHeight = display.height()

        createNotificationChannel()
        startForeground(NOTIFICATION_ID, buildNotification())
        createBubble()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_ADD_WATER -> {
                val amount = intent.getIntExtra(EXTRA_AMOUNT_ML, 200)
                addWaterFromNotification(amount)
            }
            ACTION_SHOW_BUBBLE -> bubbleView.visibility = View.VISIBLE
            ACTION_HIDE_BUBBLE -> bubbleView.visibility = View.GONE
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        breathAnimator?.cancel()
        longPressHandler.removeCallbacks(longPressRunnable)
        if (::bubbleView.isInitialized) {
            try { windowManager.removeView(bubbleView) } catch (_: Exception) {}
        }
    }

    // ─────────────────────────────────────────────────────────
    // BUBBLE OLUŞTURMA
    // ─────────────────────────────────────────────────────────

    /**
     * Yüzen baloncuğu oluştur ve ekrana yerleştir
     */
    private fun createBubble() {
        bubbleView = LayoutInflater.from(this)
            .inflate(R.layout.floating_bubble, null)

        // Ayarlardan boyut ve opaklık oku
        val sizeKey = prefs.getString("bubbleSize", "M") ?: "M"
        val bubbleDp = when (sizeKey) { "S" -> 48; "L" -> 80; else -> 64 }
        val bubbleSize = dp(bubbleDp)
        val opacity = prefs.getFloat("bubbleOpacity", 0.9f)

        val params = WindowManager.LayoutParams(
            bubbleSize,
            bubbleSize,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        )

        // Varsayılan: sağ alt köşe
        params.gravity = Gravity.BOTTOM or Gravity.END
        params.x = dp(16)
        params.y = dp(100)

        bubbleView.alpha = opacity
        bubbleView.setOnTouchListener(BubbleTouchListener(params))
        windowManager.addView(bubbleView, params)

        startBreathAnimation()
    }

    // ─────────────────────────────────────────────────────────
    // DOKUNMA MANTIĞI
    // ─────────────────────────────────────────────────────────

    inner class BubbleTouchListener(
        private val params: WindowManager.LayoutParams
    ) : View.OnTouchListener {

        private var clickCount = 0
        private var lastClickTime = 0L
        private val doubleClickThreshold = 300L

        override fun onTouch(v: View, event: MotionEvent): Boolean {
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    isDragging = false
                    isLongPress = false
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    initialBubbleX = params.x
                    initialBubbleY = params.y

                    // Uzun basma başlat
                    longPressHandler.postDelayed(longPressRunnable, 500L)
                    return true
                }

                MotionEvent.ACTION_MOVE -> {
                    val dx = abs(event.rawX - initialTouchX)
                    val dy = abs(event.rawY - initialTouchY)

                    if (dx > dp(5) || dy > dp(5)) {
                        isDragging = true
                        longPressHandler.removeCallbacks(longPressRunnable)
                    }

                    if (isDragging) {
                        params.x = (initialBubbleX - (event.rawX - initialTouchX)).toInt()
                        params.y = (initialBubbleY - (event.rawY - initialTouchY)).toInt()
                        try { windowManager.updateViewLayout(bubbleView, params) }
                        catch (_: Exception) {}
                    }
                    return true
                }

                MotionEvent.ACTION_UP -> {
                    longPressHandler.removeCallbacks(longPressRunnable)

                    if (isDragging) {
                        // Sağ kenara kaydırıldıysa yarı gizle
                        if (params.x < dp(-32)) {
                            params.x = dp(-44)
                            try { windowManager.updateViewLayout(bubbleView, params) }
                            catch (_: Exception) {}
                        }
                    } else if (!isLongPress) {
                        // Çift dokunuş → uygulamayı aç
                        val now = System.currentTimeMillis()
                        if (now - lastClickTime < doubleClickThreshold) {
                            clickCount = 0
                            openMainApp()
                        } else {
                            clickCount++
                            lastClickTime = now
                            // Tek dokunuş → su ekle
                            v.postDelayed({
                                if (clickCount == 1) {
                                    onBubbleClick()
                                }
                                clickCount = 0
                            }, doubleClickThreshold)
                        }
                    }
                    isDragging = false
                    isLongPress = false
                    return true
                }
            }
            return false
        }
    }

    /**
     * Tek dokunuş: varsayılan miktarda su ekle (200ml)
     */
    private fun onBubbleClick() {
        val defaultAmount = prefs.getInt("default_glass_size_ml", 200)
        addWater(defaultAmount)
        vibrateDevice(30L)
        animateBubbleClick()
    }

    // ─────────────────────────────────────────────────────────
    // RADYAL MENÜ (Uzun basma)
    // ─────────────────────────────────────────────────────────

    private fun showRadialMenu() {
        // Radyal menü mevcut değilse oluştur
        if (!::radialMenuView.isInitialized) {
            createRadialMenu()
        }
        radialMenuView.visibility = View.VISIBLE

        // Animasyonla aç
        radialMenuView.alpha = 0f
        radialMenuView.animate().alpha(1f).setDuration(200).start()
    }

    private fun createRadialMenu() {
        radialMenuView = LayoutInflater.from(this)
            .inflate(R.layout.radial_menu, null)

        val params = WindowManager.LayoutParams(
            dp(280),
            dp(280),
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.BOTTOM or Gravity.END
        params.x = dp(0)
        params.y = dp(80)

        val amounts = listOf(100, 200, 330, 500)
        val buttonIds = listOf(
            R.id.btn_100ml, R.id.btn_200ml, R.id.btn_330ml, R.id.btn_500ml
        )

        buttonIds.forEachIndexed { index, id ->
            radialMenuView.findViewById<View>(id)?.setOnClickListener {
                addWater(amounts[index])
                hideRadialMenu()
            }
        }

        radialMenuView.setOnClickListener { hideRadialMenu() }

        windowManager.addView(radialMenuView, params)
    }

    private fun hideRadialMenu() {
        if (::radialMenuView.isInitialized) {
            radialMenuView.animate()
                .alpha(0f).setDuration(150)
                .withEndAction { radialMenuView.visibility = View.GONE }
                .start()
        }
    }

    // ─────────────────────────────────────────────────────────
    // SU EKLEME
    // ─────────────────────────────────────────────────────────

    /**
     * Su kaydı ekle ve SharedPreferences + Flutter'a bildir
     */
    private fun addWater(amountMl: Int) {
        val currentRemaining = prefs.getInt(WaterWallpaperService.KEY_REMAINING_ML, 2500)
        val newRemaining = (currentRemaining - amountMl).coerceAtLeast(0)

        // Her tap'ı ayrı kayıt olarak JSON dizisine ekle
        val existing = prefs.getString("pending_intakes_json", "[]") ?: "[]"
        val entry = """{"amount_ml":$amountMl,"timestamp":${System.currentTimeMillis()}}"""
        val updated = if (existing == "[]") "[$entry]"
            else "${existing.dropLast(1)},$entry]"

        prefs.edit()
            .putInt(WaterWallpaperService.KEY_REMAINING_ML, newRemaining)
            .putString("pending_intakes_json", updated)
            .apply()

        // Bildirimi güncelle
        updateNotification(newRemaining)

        // Flutter'a broadcast gönder
        val broadcastIntent = Intent("com.aquacountdown.WATER_ADDED")
        broadcastIntent.putExtra("amount_ml", amountMl)
        broadcastIntent.putExtra("remaining_ml", newRemaining)
        sendBroadcast(broadcastIntent)
    }

    private fun addWaterFromNotification(amount: Int) {
        addWater(amount)
        vibrateDevice(30L)
    }

    private fun openMainApp() {
        val intent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        if (intent != null) startActivity(intent)
    }

    // ─────────────────────────────────────────────────────────
    // ANİMASYONLAR
    // ─────────────────────────────────────────────────────────

    /**
     * Nefes alma animasyonu (idle state)
     */
    private fun startBreathAnimation() {
        breathAnimator = ValueAnimator.ofFloat(1f, 1.05f).apply {
            duration = 2000L
            repeatMode = ValueAnimator.REVERSE
            repeatCount = ValueAnimator.INFINITE
            interpolator = DecelerateInterpolator()
            addUpdateListener { anim ->
                val scale = anim.animatedValue as Float
                bubbleView.scaleX = scale
                bubbleView.scaleY = scale
            }
            start()
        }
    }

    /**
     * Tıklama animasyonu (kısa sıkışma efekti)
     */
    private fun animateBubbleClick() {
        breathAnimator?.pause()
        bubbleView.animate()
            .scaleX(0.85f).scaleY(0.85f).setDuration(100)
            .withEndAction {
                bubbleView.animate()
                    .scaleX(1f).scaleY(1f).setDuration(200)
                    .withEndAction { breathAnimator?.resume() }
                    .start()
            }.start()
    }

    // ─────────────────────────────────────────────────────────
    // BİLDİRİM
    // ─────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID, CHANNEL_NAME,
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "AquaCountdown su takibini aktif tutar"
                setShowBadge(false)
            }
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val remainingMl = prefs.getInt(WaterWallpaperService.KEY_REMAINING_ML, 2500)
        return buildNotificationForAmount(remainingMl)
    }

    private fun buildNotificationForAmount(remainingMl: Int): Notification {
        val displayText = if (remainingMl >= 1000) {
            "%.1f L kaldı".format(remainingMl / 1000f)
        } else {
            "$remainingMl ml kaldı"
        }

        val openIntent = PendingIntent.getActivity(
            this, 0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val addWaterIntent = PendingIntent.getService(
            this, 1,
            Intent(this, FloatingBubbleService::class.java).apply {
                action = ACTION_ADD_WATER
                putExtra(EXTRA_AMOUNT_ML, 200)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("💧 Su takibi aktif")
            .setContentText(displayText)
            .setSmallIcon(R.drawable.ic_water_drop)
            .setContentIntent(openIntent)
            .addAction(R.drawable.ic_water_drop, "+ 200ml Ekle", addWaterIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun updateNotification(remainingMl: Int) {
        val nm = getSystemService(NotificationManager::class.java)
        nm.notify(NOTIFICATION_ID, buildNotificationForAmount(remainingMl))
    }

    // ─────────────────────────────────────────────────────────
    // YARDIMCI
    // ─────────────────────────────────────────────────────────

    private fun dp(value: Int): Int {
        return (value * resources.displayMetrics.density).toInt()
    }

    private fun vibrateDevice(durationMs: Long) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vm = getSystemService(VibratorManager::class.java)
                vm.defaultVibrator.vibrate(
                    VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE)
                )
            } else {
                @Suppress("DEPRECATION")
                val vibrator = getSystemService(VIBRATOR_SERVICE) as Vibrator
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    vibrator.vibrate(
                        VibrationEffect.createOneShot(durationMs, VibrationEffect.DEFAULT_AMPLITUDE)
                    )
                } else {
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(durationMs)
                }
            }
        } catch (_: Exception) {
            // Titreşim mevcut değilse görmezden gel
        }
    }
}
