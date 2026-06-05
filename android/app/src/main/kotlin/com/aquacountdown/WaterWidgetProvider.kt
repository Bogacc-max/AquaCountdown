package com.aquacountdown

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Ana ekran widget'ı — kalan su miktarını gösterir ve hızlı ekleme sağlar.
 *
 * Layout: res/layout/water_widget_layout.xml
 * Info:   res/xml/water_widget_info.xml
 */
class WaterWidgetProvider : AppWidgetProvider() {

    companion object {
        const val ACTION_WIDGET_ADD_WATER = "com.aquacountdown.WIDGET_ADD_WATER"
        const val EXTRA_AMOUNT_ML = "amount_ml"
        private const val DEFAULT_ADD_AMOUNT = 250

        /** Tüm widget örneklerini yeniden çizer. Flutter tarafından da çağrılabilir. */
        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, WaterWidgetProvider::class.java)
            )
            if (ids.isNotEmpty()) {
                val provider = WaterWidgetProvider()
                provider.onUpdate(context, manager, ids)
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_WIDGET_ADD_WATER) {
            val amount = intent.getIntExtra(EXTRA_AMOUNT_ML, DEFAULT_ADD_AMOUNT)
                .coerceIn(1, 2000)
            handleAddWater(context, amount)
        }
    }

    // -------------------------------------------------------------------------
    // Internal helpers
    // -------------------------------------------------------------------------

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val prefs = context.getSharedPreferences(
            WaterWallpaperService.PREFS_NAME,
            Context.MODE_PRIVATE
        )

        val remainingMl = prefs.getInt("remaining_ml", 2000)
        val targetMl    = prefs.getInt("target_ml", 2000)

        val views = RemoteViews(context.packageName, R.layout.water_widget_layout)

        // Kalan miktarı göster
        val remainingText = formatMl(remainingMl)
        views.setTextViewText(R.id.widget_remaining_text, remainingText)

        // Alt bilgi: "X / Y ml kaldı"
        val subtitleText = "$remainingMl / $targetMl ml"
        views.setTextViewText(R.id.widget_subtitle_text, subtitleText)

        // İlerleme rengi — hedefe yaklaştıkça renk değişir
        val progressRatio = if (targetMl > 0) remainingMl.toFloat() / targetMl else 0f
        val iconColor = when {
            progressRatio > 0.6f -> 0xFF0288D1.toInt()   // mavi
            progressRatio > 0.3f -> 0xFF00BCD4.toInt()   // açık mavi
            progressRatio > 0.1f -> 0xFF26C6DA.toInt()   // cyan
            else                 -> 0xFFFFD54F.toInt()   // altın — çok az kaldı
        }
        views.setInt(R.id.widget_icon, "setColorFilter", iconColor)

        // Dokunma → uygulamayı aç
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            val pendingIntent = PendingIntent.getActivity(
                context, 0, launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
        }

        // "+" butonu → 250 ml ekle
        val addIntent = Intent(context, WaterWidgetProvider::class.java).apply {
            action = ACTION_WIDGET_ADD_WATER
            putExtra(EXTRA_AMOUNT_ML, DEFAULT_ADD_AMOUNT)
        }
        val addPendingIntent = PendingIntent.getBroadcast(
            context, widgetId, addIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_add_button, addPendingIntent)

        appWidgetManager.updateAppWidget(widgetId, views)
    }

    /**
     * Widget'tan su ekle: SharedPreferences'ı güncelle, widget'ı yenile,
     * FloatingBubbleService ile aynı broadcast'i gönder ki MainActivity yakalasın.
     */
    private fun handleAddWater(context: Context, amountMl: Int) {
        val prefs = context.getSharedPreferences(
            WaterWallpaperService.PREFS_NAME,
            Context.MODE_PRIVATE
        )

        val currentRemaining = prefs.getInt("remaining_ml", 2000)
        val newRemaining = (currentRemaining - amountMl).coerceAtLeast(0)

        // Güvenli JSON dizisi oluşturma (JSONArray ile)
        try {
            val existingJson = prefs.getString("pending_intakes_json", "[]") ?: "[]"
            val jsonArray = org.json.JSONArray(existingJson)
            val newEntry = org.json.JSONObject().apply {
                put("amount_ml", amountMl)
                put("timestamp", System.currentTimeMillis())
            }
            jsonArray.put(newEntry)

            prefs.edit()
                .putInt("remaining_ml", newRemaining)
                .putString("pending_intakes_json", jsonArray.toString())
                .apply()
        } catch (e: Exception) {
            prefs.edit()
                .putInt("remaining_ml", newRemaining)
                .putString("pending_intakes_json",
                    """[{"amount_ml":$amountMl,"timestamp":${System.currentTimeMillis()}}]""")
                .apply()
        }

        // Flutter'a bildir (MainActivity'deki BroadcastReceiver yakalar)
        val broadcastIntent = Intent("com.aquacountdown.WATER_ADDED").apply {
            setPackage(context.packageName)
            putExtra("amount_ml", amountMl)
            putExtra("remaining_ml", newRemaining)
        }
        context.sendBroadcast(broadcastIntent)

        // Widget'ı hemen yenile
        updateAllWidgets(context)
    }

    // -------------------------------------------------------------------------
    // Formatting helpers
    // -------------------------------------------------------------------------

    private fun formatMl(ml: Int): String {
        return if (ml >= 1000) {
            val liters = ml / 1000.0
            if (liters == liters.toLong().toDouble()) {
                "${liters.toLong()} L"
            } else {
                String.format("%.1f L", liters)
            }
        } else {
            "$ml ml"
        }
    }
}
