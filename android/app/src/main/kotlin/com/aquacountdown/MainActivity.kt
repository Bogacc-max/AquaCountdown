package com.aquacountdown

import android.app.Activity
import android.app.WallpaperManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * AquaCountdown Ana Activity
 *
 * Flutter ↔ Native Kotlin köprüsünü MethodChannel üzerinden kurar.
 * - "aquacountdown/wallpaper" kanalı: Live Wallpaper yönetimi
 * - "aquacountdown/bubble"   kanalı: Floating Bubble yönetimi
 * - "aquacountdown/water"    kanalı: Su verisi senkronizasyonu
 * - "aquacountdown/events"   kanalı: Native→Flutter event stream
 */
class MainActivity : FlutterActivity() {

    companion object {
        const val CHANNEL_WALLPAPER = "aquacountdown/wallpaper"
        const val CHANNEL_BUBBLE = "aquacountdown/bubble"
        const val CHANNEL_WATER = "aquacountdown/water"
        const val EVENT_CHANNEL = "aquacountdown/events"
        const val REQUEST_OVERLAY_PERMISSION = 1001
        const val REQUEST_WALLPAPER = 1002
    }

    private lateinit var prefs: SharedPreferences

    // EventChannel stream handler — Native'den Flutter'a olay akışı
    private var eventSink: EventChannel.EventSink? = null

    // Native'den gelen su ekleme eventlerini Flutter'a ilet
    private val waterAddedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val amountMl = intent?.getIntExtra("amount_ml", 0) ?: return
            val remainingMl = intent.getIntExtra("remaining_ml", 0)
            eventSink?.success(mapOf(
                "type" to "water_added",
                "amount_ml" to amountMl,
                "remaining_ml" to remainingMl
            ))
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        prefs = getSharedPreferences(WaterWallpaperService.PREFS_NAME, MODE_PRIVATE)

        setupWallpaperChannel(flutterEngine)
        setupBubbleChannel(flutterEngine)
        setupWaterChannel(flutterEngine)
        setupEventChannel(flutterEngine)
    }

    // ─────────────────────────────────────────────────────────
    // WALLPAPER CHANNEL
    // ─────────────────────────────────────────────────────────

    private fun setupWallpaperChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_WALLPAPER)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isWallpaperSet" -> {
                        result.success(isWallpaperServiceSet())
                    }
                    "openWallpaperPicker" -> {
                        openLiveWallpaperPicker()
                        result.success(null)
                    }
                    "updateWallpaperData" -> {
                        val remaining = call.argument<Int>("remaining_ml") ?: 0
                        val target = call.argument<Int>("target_ml") ?: 2500
                        val theme = call.argument<String>("theme_id") ?: "classic"
                        val unit = call.argument<String>("unit") ?: "ml"
                        updateWallpaperData(remaining, target, theme, unit)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ─────────────────────────────────────────────────────────
    // BUBBLE CHANNEL
    // ─────────────────────────────────────────────────────────

    private fun setupBubbleChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_BUBBLE)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasOverlayPermission" -> {
                        result.success(
                            Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                                    Settings.canDrawOverlays(this)
                        )
                    }
                    "requestOverlayPermission" -> {
                        requestOverlayPermission()
                        result.success(null)
                    }
                    "startBubble" -> {
                        startFloatingBubble()
                        prefs.edit().putBoolean("floating_bubble_enabled", true).apply()
                        result.success(null)
                    }
                    "stopBubble" -> {
                        stopService(Intent(this, FloatingBubbleService::class.java))
                        prefs.edit().putBoolean("floating_bubble_enabled", false).apply()
                        result.success(null)
                    }
                    "showBubble" -> {
                        sendBubbleCommand(FloatingBubbleService.ACTION_SHOW_BUBBLE)
                        result.success(null)
                    }
                    "hideBubble" -> {
                        sendBubbleCommand(FloatingBubbleService.ACTION_HIDE_BUBBLE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ─────────────────────────────────────────────────────────
    // WATER CHANNEL
    // ─────────────────────────────────────────────────────────

    private fun setupWaterChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_WATER)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "syncWaterData" -> {
                        val remaining = call.argument<Int>("remaining_ml") ?: 0
                        val target = call.argument<Int>("target_ml") ?: 2500
                        val unit = call.argument<String>("unit") ?: "ml"
                        prefs.edit()
                            .putInt(WaterWallpaperService.KEY_REMAINING_ML, remaining)
                            .putInt(WaterWallpaperService.KEY_TARGET_ML, target)
                            .putString(WaterWallpaperService.KEY_UNIT, unit)
                            .apply()
                        result.success(null)
                    }
                    "getPendingIntakes" -> {
                        // Bubble servisi tarafından eklenen su kayıtlarını al
                        val lastAmount = prefs.getInt("last_intake_amount", 0)
                        val lastTime = prefs.getLong("last_intake_time", 0)
                        if (lastAmount > 0 && lastTime > 0) {
                            prefs.edit()
                                .remove("last_intake_amount")
                                .remove("last_intake_time")
                                .apply()
                            result.success(mapOf(
                                "amount_ml" to lastAmount,
                                "timestamp" to lastTime
                            ))
                        } else {
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ─────────────────────────────────────────────────────────
    // EVENT CHANNEL
    // ─────────────────────────────────────────────────────────

    private fun setupEventChannel(engine: FlutterEngine) {
        EventChannel(engine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    registerReceiver(
                        waterAddedReceiver,
                        IntentFilter("com.aquacountdown.WATER_ADDED")
                    )
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    try { unregisterReceiver(waterAddedReceiver) } catch (_: Exception) {}
                }
            })
    }

    // ─────────────────────────────────────────────────────────
    // YARDIMCI METOTLAR
    // ─────────────────────────────────────────────────────────

    private fun isWallpaperServiceSet(): Boolean {
        return try {
            val wm = WallpaperManager.getInstance(this)
            val info = wm.wallpaperInfo
            info?.packageName == packageName &&
                    info.serviceName.contains("WaterWallpaperService")
        } catch (e: Exception) {
            false
        }
    }

    private fun openLiveWallpaperPicker() {
        try {
            val intent = Intent(WallpaperManager.ACTION_CHANGE_LIVE_WALLPAPER).apply {
                putExtra(
                    WallpaperManager.EXTRA_LIVE_WALLPAPER_COMPONENT,
                    ComponentName(this@MainActivity, WaterWallpaperService::class.java)
                )
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivityForResult(intent, REQUEST_WALLPAPER)
        } catch (e: Exception) {
            // Alternatif: genel duvar kağıdı seçici
            startActivity(Intent(WallpaperManager.ACTION_LIVE_WALLPAPER_CHOOSER))
        }
    }

    private fun updateWallpaperData(
        remaining: Int, target: Int, theme: String, unit: String
    ) {
        prefs.edit()
            .putInt(WaterWallpaperService.KEY_REMAINING_ML, remaining)
            .putInt(WaterWallpaperService.KEY_TARGET_ML, target)
            .putString(WaterWallpaperService.KEY_THEME_ID, theme)
            .putString(WaterWallpaperService.KEY_UNIT, unit)
            .apply()
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, REQUEST_OVERLAY_PERMISSION)
        }
    }

    private fun startFloatingBubble() {
        val intent = Intent(this, FloatingBubbleService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun sendBubbleCommand(action: String) {
        val intent = Intent(this, FloatingBubbleService::class.java).apply {
            this.action = action
        }
        startService(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            REQUEST_OVERLAY_PERMISSION -> {
                val hasPermission = Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                        Settings.canDrawOverlays(this)
                eventSink?.success(mapOf(
                    "type" to "overlay_permission_result",
                    "granted" to hasPermission
                ))
            }
            REQUEST_WALLPAPER -> {
                val isSet = isWallpaperServiceSet()
                eventSink?.success(mapOf(
                    "type" to "wallpaper_result",
                    "set" to isSet
                ))
            }
        }
    }
}
