package com.aquacountdown

import android.content.SharedPreferences
import android.graphics.*
import android.os.Handler
import android.os.Looper
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import kotlin.math.*

/**
 * AquaCountdown Live Wallpaper Servisi
 * Ekranın ortasında gerçek zamanlı su seviyesini gösteren bardak çizer.
 * SharedPreferences üzerinden Flutter ile veri alışverişi yapar.
 */
class WaterWallpaperService : WallpaperService() {

    companion object {
        const val PREFS_NAME = "aquacountdown_prefs"
        const val KEY_REMAINING_ML = "remaining_ml"
        const val KEY_TARGET_ML = "target_ml"
        const val KEY_THEME_ID = "theme_id"
        const val KEY_UNIT = "unit"
        // Animasyon frame hızı (ms) — pil dostu 30fps
        const val FRAME_INTERVAL_MS = 33L
    }

    override fun onCreateEngine(): Engine = WaterEngine()

    inner class WaterEngine : Engine(),
        SharedPreferences.OnSharedPreferenceChangeListener {

        private val handler = Handler(Looper.getMainLooper())
        private lateinit var prefs: SharedPreferences

        // Mevcut su yüksekliği (0.0 = boş, 1.0 = dolu)
        private var waterLevel = 1.0f
        private var targetWaterLevel = 1.0f

        // Dalga animasyonu için faz değerleri
        private var wavePhase1 = 0f
        private var wavePhase2 = PI.toFloat() / 2

        // Renk geçişi
        private var currentColor = Color.parseColor("#0277BD")
        private var targetColor = Color.parseColor("#0277BD")

        // Parıltı animasyonu (düşük seviye için)
        private var glowAlpha = 0f
        private var glowIncreasing = true

        // Veriler
        private var remainingMl = 2500
        private var targetMl = 2500
        private var unit = "ml"

        // Paint nesneleri — her frame'de yeni oluşturmamak için
        private val glassPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val waterPaint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            textAlign = Paint.Align.CENTER
            isFakeBoldText = true
        }
        private val subtextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(200, 255, 255, 255)
            textAlign = Paint.Align.CENTER
        }
        private val glowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.FILL
        }
        private val borderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 3f
            color = Color.argb(100, 255, 255, 255)
        }

        private var visible = false

        private val drawRunnable = object : Runnable {
            override fun run() {
                if (visible) {
                    updateAnimation()
                    drawFrame()
                    handler.postDelayed(this, FRAME_INTERVAL_MS)
                }
            }
        }

        override fun onCreate(surfaceHolder: SurfaceHolder) {
            super.onCreate(surfaceHolder)
            // SharedPreferences'i dinle
            prefs = applicationContext.getSharedPreferences(PREFS_NAME, MODE_PRIVATE)
            prefs.registerOnSharedPreferenceChangeListener(this)
            loadData()
        }

        override fun onDestroy() {
            super.onDestroy()
            handler.removeCallbacks(drawRunnable)
            prefs.unregisterOnSharedPreferenceChangeListener(this)
        }

        override fun onVisibilityChanged(visible: Boolean) {
            this.visible = visible
            if (visible) {
                loadData()
                handler.post(drawRunnable)
            } else {
                handler.removeCallbacks(drawRunnable)
            }
        }

        override fun onSurfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            super.onSurfaceChanged(holder, format, width, height)
            drawFrame()
        }

        override fun onSharedPreferenceChanged(sp: SharedPreferences?, key: String?) {
            // Flutter veri değiştirdiğinde yenile
            if (key == KEY_REMAINING_ML || key == KEY_TARGET_ML || key == KEY_THEME_ID) {
                loadData()
            }
        }

        /**
         * SharedPreferences'tan Flutter'dan gelen veriyi yükle
         */
        private fun loadData() {
            remainingMl = prefs.getInt(KEY_REMAINING_ML, 2500)
            targetMl = prefs.getInt(KEY_TARGET_ML, 2500).coerceAtLeast(1)
            unit = prefs.getString(KEY_UNIT, "ml") ?: "ml"

            targetWaterLevel = (remainingMl.toFloat() / targetMl.toFloat()).coerceIn(0f, 1f)
            targetColor = getColorForLevel(targetWaterLevel, remainingMl)
        }

        /**
         * Her frame'de animasyon durumunu güncelle
         */
        private fun updateAnimation() {
            // Su seviyesini hedef seviyeye doğru yavaşça hareket ettir (smooth geçiş)
            waterLevel += (targetWaterLevel - waterLevel) * 0.05f

            // Dalga fazlarını ilerlet
            wavePhase1 += 0.04f
            wavePhase2 += 0.03f
            if (wavePhase1 > 2 * PI) wavePhase1 -= 2 * PI.toFloat()
            if (wavePhase2 > 2 * PI) wavePhase2 -= 2 * PI.toFloat()

            // Renk geçişi (smooth)
            currentColor = blendColors(currentColor, targetColor, 0.03f)

            // Parıltı animasyonu (düşük seviye uyarısı)
            if (remainingMl <= 500) {
                glowAlpha = if (glowIncreasing) {
                    val next = glowAlpha + 0.02f
                    if (next >= 1f) { glowIncreasing = false; 1f } else next
                } else {
                    val next = glowAlpha - 0.02f
                    if (next <= 0f) { glowIncreasing = true; 0f } else next
                }
            } else {
                glowAlpha = 0f
            }
        }

        /**
         * Canvas'a bardak ve su seviyesini çiz
         */
        private fun drawFrame() {
            val holder = surfaceHolder
            var canvas: Canvas? = null
            try {
                canvas = holder.lockCanvas()
                if (canvas == null) return
                drawWallpaper(canvas)
            } finally {
                if (canvas != null) {
                    try { holder.unlockCanvasAndPost(canvas) }
                    catch (e: Exception) { /* İstisna yut */ }
                }
            }
        }

        private fun drawWallpaper(canvas: Canvas) {
            val w = canvas.width.toFloat()
            val h = canvas.height.toFloat()

            // Arkaplan (koyu gradyan)
            val bgPaint = Paint()
            val bgShader = LinearGradient(
                0f, 0f, 0f, h,
                Color.parseColor("#0A1929"),
                Color.parseColor("#0D2137"),
                Shader.TileMode.CLAMP
            )
            bgPaint.shader = bgShader
            canvas.drawRect(0f, 0f, w, h, bgPaint)

            // Bardak boyutu: genişliğin %50'si, dikey ortalanmış
            val cupWidth = w * 0.50f
            val cupHeight = cupWidth * 1.6f
            val cupLeft = (w - cupWidth) / 2f
            val cupTop = (h - cupHeight) / 2f - h * 0.05f // hafif yukarı kaydır
            val cupRight = cupLeft + cupWidth
            val cupBottom = cupTop + cupHeight

            // Bardak gövdesi klipi
            val cupPath = buildCupPath(cupLeft, cupTop, cupRight, cupBottom)
            canvas.save()
            canvas.clipPath(cupPath)

            // Su dolgu
            drawWater(canvas, cupLeft, cupTop, cupRight, cupBottom)

            canvas.restore()

            // Bardak kenarı (cam efekti)
            glassPaint.apply {
                style = Paint.Style.STROKE
                strokeWidth = 4f
                shader = LinearGradient(
                    cupLeft, 0f, cupRight, 0f,
                    intArrayOf(
                        Color.argb(40, 255, 255, 255),
                        Color.argb(120, 255, 255, 255),
                        Color.argb(40, 255, 255, 255)
                    ),
                    null, Shader.TileMode.CLAMP
                )
            }
            canvas.drawPath(cupPath, glassPaint)

            // İç yansıma efekti
            drawGlassReflection(canvas, cupLeft, cupTop, cupBottom)

            // Bardak üzerindeki metin (kalan miktar)
            drawWaterText(canvas, w, cupBottom)

            // Düşük seviye parıltısı
            if (glowAlpha > 0f) {
                drawLowLevelGlow(canvas, cupLeft, cupTop, cupRight, cupBottom)
            }
        }

        /**
         * Bardak şeklinin Path'ini oluştur (altı biraz daha dar, hafif trapezoid)
         */
        private fun buildCupPath(left: Float, top: Float, right: Float, bottom: Float): Path {
            val path = Path()
            val narrowing = (right - left) * 0.08f
            val cornerRadius = 12f
            // Bardak şekli: üstten geniş, alttan hafif dar
            path.moveTo(left + cornerRadius, top)
            path.lineTo(right - cornerRadius, top)
            path.quadTo(right, top, right, top + cornerRadius)
            path.lineTo(right - narrowing, bottom - cornerRadius)
            path.quadTo(right - narrowing, bottom, right - narrowing - cornerRadius, bottom)
            path.lineTo(left + narrowing + cornerRadius, bottom)
            path.quadTo(left + narrowing, bottom, left + narrowing, bottom - cornerRadius)
            path.lineTo(left, top + cornerRadius)
            path.quadTo(left, top, left + cornerRadius, top)
            path.close()
            return path
        }

        /**
         * Su katmanını dalgalanmayla çiz
         */
        private fun drawWater(
            canvas: Canvas,
            left: Float, top: Float, right: Float, bottom: Float
        ) {
            val cupHeight = bottom - top
            val waterSurfaceY = bottom - (cupHeight * waterLevel)

            if (waterLevel <= 0f) return

            val waterPath = Path()
            val width = right - left

            // Alt düz alan
            waterPath.moveTo(left, bottom)
            waterPath.lineTo(right, bottom)
            waterPath.lineTo(right, waterSurfaceY)

            // Dalga yüzeyi (çift sinüs dalgası)
            val steps = 60
            for (i in steps downTo 0) {
                val x = left + (width * i / steps)
                val relX = x - left
                val wave1 = sin(wavePhase1 + relX * 0.025f) * 8f
                val wave2 = sin(wavePhase2 + relX * 0.04f) * 5f
                waterPath.lineTo(x, waterSurfaceY + wave1 + wave2)
            }
            waterPath.close()

            // Su gradyan rengi
            waterPaint.shader = LinearGradient(
                0f, waterSurfaceY, 0f, bottom,
                intArrayOf(
                    Color.argb(220, Color.red(currentColor), Color.green(currentColor), Color.blue(currentColor)),
                    Color.argb(255, Color.red(currentColor), Color.green(currentColor), Color.blue(currentColor))
                ),
                null, Shader.TileMode.CLAMP
            )
            canvas.drawPath(waterPath, waterPaint)
        }

        /**
         * Cam yansıma efekti (sol üst köşede ince şerit)
         */
        private fun drawGlassReflection(
            canvas: Canvas,
            left: Float, top: Float, bottom: Float
        ) {
            val reflPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                shader = LinearGradient(
                    left, top, left + 20f, bottom * 0.6f,
                    Color.argb(60, 255, 255, 255),
                    Color.argb(0, 255, 255, 255),
                    Shader.TileMode.CLAMP
                )
                style = Paint.Style.FILL
            }
            val reflPath = Path().apply {
                moveTo(left + 8f, top + 20f)
                lineTo(left + 18f, top + 20f)
                lineTo(left + 14f, bottom * 0.5f)
                lineTo(left + 6f, bottom * 0.5f)
                close()
            }
            canvas.drawPath(reflPath, reflPaint)
        }

        /**
         * Bardağın altına kalan miktar yazısını çiz
         */
        private fun drawWaterText(canvas: Canvas, screenWidth: Float, cupBottom: Float) {
            val centerX = screenWidth / 2f
            val displayValue = if (unit == "oz") {
                val oz = remainingMl / 29.5735f
                String.format("%.1f oz", oz)
            } else if (remainingMl >= 1000) {
                String.format("%.1f L", remainingMl / 1000f)
            } else {
                "$remainingMl ml"
            }

            textPaint.textSize = screenWidth * 0.12f
            canvas.drawText(displayValue, centerX, cupBottom + screenWidth * 0.15f, textPaint)

            subtextPaint.textSize = screenWidth * 0.055f
            canvas.drawText("kaldı", centerX, cupBottom + screenWidth * 0.22f, subtextPaint)
        }

        /**
         * Düşük su seviyesi parıltı animasyonu
         */
        private fun drawLowLevelGlow(
            canvas: Canvas,
            left: Float, top: Float, right: Float, bottom: Float
        ) {
            val alpha = (glowAlpha * 60).toInt()
            glowPaint.color = Color.argb(alpha, 255, 213, 79)
            val cx = (left + right) / 2f
            val cy = (top + bottom) / 2f
            val radius = (right - left) * 0.6f
            canvas.drawCircle(cx, cy, radius, glowPaint)
        }

        /**
         * Su seviyesine göre renk döndür
         */
        private fun getColorForLevel(level: Float, remainingMl: Int): Int {
            return when {
                remainingMl <= 0 -> Color.parseColor("#26C6DA")
                remainingMl <= 250 -> Color.parseColor("#FFD54F")
                remainingMl <= 500 -> Color.parseColor("#26C6DA")
                remainingMl <= 1000 -> Color.parseColor("#00BCD4")
                remainingMl <= 2000 -> Color.parseColor("#039BE5")
                remainingMl <= 3000 -> Color.parseColor("#0288D1")
                else -> Color.parseColor("#0277BD")
            }
        }

        /**
         * İki rengi smooth geçişle karıştır
         */
        private fun blendColors(from: Int, to: Int, ratio: Float): Int {
            val r = ratio.coerceIn(0f, 1f)
            return Color.argb(
                (Color.alpha(from) + (Color.alpha(to) - Color.alpha(from)) * r).toInt(),
                (Color.red(from) + (Color.red(to) - Color.red(from)) * r).toInt(),
                (Color.green(from) + (Color.green(to) - Color.green(from)) * r).toInt(),
                (Color.blue(from) + (Color.blue(to) - Color.blue(from)) * r).toInt()
            )
        }
    }
}
