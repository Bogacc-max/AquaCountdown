# Flutter / AquaCountdown ProGuard kuralları

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# AquaCountdown — yalnızca lifecycle/reflection için gerekli metotlar
-keep class com.aquacountdown.MainActivity {
    public <init>();
    public void configureFlutterEngine(io.flutter.embedding.engine.FlutterEngine);
}
-keep class com.aquacountdown.FloatingBubbleService {
    public <init>();
    public int onStartCommand(android.content.Intent, int, int);
}
-keep class com.aquacountdown.WaterWallpaperService {
    public <init>();
    public android.service.wallpaper.WallpaperService$Engine onCreateEngine();
}
-keep class com.aquacountdown.WaterWidgetProvider {
    public <init>();
    public void onUpdate(android.content.Context, android.appwidget.AppWidgetManager, int[]);
    public void onReceive(android.content.Context, android.content.Intent);
}
-keep class com.aquacountdown.BootReceiver {
    public <init>();
    public void onReceive(android.content.Context, android.content.Intent);
}

# Kotlin Metadata (R8 reflection)
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
-dontwarn com.google.android.gms.ads.**

# Health / Google Fit
-keep class com.google.android.gms.fitness.** { *; }
-dontwarn com.google.android.gms.fitness.**

# Genel Android
-keepattributes *Annotation*
-keepattributes Signature
-dontwarn sun.misc.**
-dontwarn com.google.android.play.core.**

# Obfuscation sıkılaştırma
-repackageclasses 'a'
-allowaccessmodification
-optimizationpasses 5
