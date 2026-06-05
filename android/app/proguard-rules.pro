# Flutter / AquaCountdown ProGuard kuralları

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# AquaCountdown native sınıfları (spesifik)
-keep class com.aquacountdown.MainActivity { *; }
-keep class com.aquacountdown.FloatingBubbleService { *; }
-keep class com.aquacountdown.WaterWallpaperService { *; }
-keep class com.aquacountdown.WaterWidgetProvider { *; }
-keep class com.aquacountdown.BootReceiver { *; }

# Kotlin Metadata
-keep class kotlin.Metadata { *; }
-keepclassmembers class **$WhenMappings { <fields>; }
-dontwarn kotlin.**

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# WorkManager
-keep class androidx.work.** { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# sqflite
-keep class io.flutter.plugins.sqflite.** { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Health / Google Fit
-keep class com.google.android.gms.fitness.** { *; }
-dontwarn com.google.android.gms.fitness.**

# Genel Android
-keepattributes *Annotation*
-keepattributes Signature
-dontwarn sun.misc.**
-dontwarn com.google.android.play.core.**
