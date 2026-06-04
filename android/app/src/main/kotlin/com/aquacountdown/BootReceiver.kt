package com.aquacountdown

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build

/**
 * Cihaz yeniden başladığında veya uygulama güncellendiğinde
 * FloatingBubble servisini otomatik olarak yeniden başlatır.
 *
 * Gerekli izin: RECEIVE_BOOT_COMPLETED (AndroidManifest.xml'de tanımlı)
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        // Sadece boot ve package replace eventlerini dinle
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_MY_PACKAGE_REPLACED
        ) return

        val prefs: SharedPreferences = context.getSharedPreferences(
            WaterWallpaperService.PREFS_NAME,
            Context.MODE_PRIVATE
        )

        // Kullanıcı daha önce yüzen butonu etkinleştirmişse yeniden başlat
        val bubbleEnabled = prefs.getBoolean("floating_bubble_enabled", false)
        if (bubbleEnabled) {
            startFloatingBubble(context)
        }
    }

    private fun startFloatingBubble(context: Context) {
        val serviceIntent = Intent(context, FloatingBubbleService::class.java)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (e: Exception) {
            // Servis başlatılamazsa sessizce geç (izin yoksa vb.)
        }
    }
}
