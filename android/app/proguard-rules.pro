# Flutter / AquaCountdown ProGuard kuralları

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Isar
-keep class dev.isar.** { *; }
-keep class com.isar.** { *; }

# AquaCountdown native sınıfları
-keep class com.aquacountdown.** { *; }

# Kotlin
-keep class kotlin.** { *; }
-keepclassmembers class **$WhenMappings { *; }

# Home Widget
-keep class es.antonborri.home_widget.** { *; }

# WorkManager / Room — R8 full mode için kapsamlı kurallar
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.work.Worker { *; }
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

# Room: _Impl sınıfları reflection ile bulunur — isim korunmalı
-keep class * extends androidx.room.RoomDatabase { *; }
-keepnames class * extends androidx.room.RoomDatabase
-keep @androidx.room.Database class * { *; }
-keep @androidx.room.Dao class * { *; }
-keep @androidx.room.Entity class * { *; }

# R8 conditional: RoomDatabase alt sınıfı varsa _Impl ve _Impl$ da koru
-if class * extends androidx.room.RoomDatabase
-keep class <1>_Impl { *; }
-if class * extends androidx.room.RoomDatabase
-keep class <1>_Impl$* { *; }

# sqflite
-keep class io.flutter.plugins.sqflite.** { *; }

# Genel Android
-keepattributes *Annotation*
-keepattributes Signature
-dontwarn sun.misc.**

# Flutter Play Core (deferred components) — bu uygulama kullanmıyor
-dontwarn com.google.android.play.core.**
