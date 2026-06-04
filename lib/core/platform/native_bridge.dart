import 'dart:async';
import 'package:flutter/services.dart';

/// Flutter ↔ Native (Android/iOS) MethodChannel köprüsü
/// Tüm native iletişim bu sınıf üzerinden geçer.
class NativeBridge {
  // Kanal adları — MainActivity.kt ile eşleşmeli
  static const _wallpaperChannel =
      MethodChannel('aquacountdown/wallpaper');
  static const _bubbleChannel =
      MethodChannel('aquacountdown/bubble');
  static const _waterChannel =
      MethodChannel('aquacountdown/water');
  static const _eventChannel =
      EventChannel('aquacountdown/events');

  static StreamSubscription? _eventSub;
  static final _eventController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Native'den Flutter'a event stream
  static Stream<Map<String, dynamic>> get nativeEvents =>
      _eventController.stream;

  /// Event kanalını başlat (app startup'ta çağır)
  static void initEventChannel() {
    _eventSub?.cancel();
    _eventSub = _eventChannel
        .receiveBroadcastStream()
        .cast<Map<Object?, Object?>>()
        .listen((event) {
      _eventController.add(Map<String, dynamic>.from(event));
    });
  }

  static void dispose() {
    _eventSub?.cancel();
    _eventController.close();
  }

  // ─────────────────────────────────────────────────────
  // WALLPAPER
  // ─────────────────────────────────────────────────────

  /// Live Wallpaper aktif mi?
  static Future<bool> isWallpaperSet() async {
    try {
      return await _wallpaperChannel.invokeMethod('isWallpaperSet') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Live Wallpaper seçici ekranını aç
  static Future<void> openWallpaperPicker() async {
    try {
      await _wallpaperChannel.invokeMethod('openWallpaperPicker');
    } on PlatformException catch (e) {
      throw Exception('Duvar kağıdı seçici açılamadı: ${e.message}');
    }
  }

  /// Wallpaper'a su verisi gönder
  static Future<void> updateWallpaperData({
    required int remainingMl,
    required int targetMl,
    String themeId = 'classic',
    String unit = 'ml',
  }) async {
    try {
      await _wallpaperChannel.invokeMethod('updateWallpaperData', {
        'remaining_ml': remainingMl,
        'target_ml': targetMl,
        'theme_id': themeId,
        'unit': unit,
      });
    } on PlatformException {
      // Wallpaper yoksa sessizce geç
    }
  }

  // ─────────────────────────────────────────────────────
  // FLOATING BUBBLE
  // ─────────────────────────────────────────────────────

  /// SYSTEM_ALERT_WINDOW izni var mı?
  static Future<bool> hasOverlayPermission() async {
    try {
      return await _bubbleChannel.invokeMethod('hasOverlayPermission') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// SYSTEM_ALERT_WINDOW iznini iste
  static Future<void> requestOverlayPermission() async {
    try {
      await _bubbleChannel.invokeMethod('requestOverlayPermission');
    } on PlatformException catch (e) {
      throw Exception('İzin isteği başarısız: ${e.message}');
    }
  }

  /// Floating bubble servisini başlat
  static Future<void> startBubble() async {
    try {
      await _bubbleChannel.invokeMethod('startBubble');
    } on PlatformException catch (e) {
      throw Exception('Yüzen buton başlatılamadı: ${e.message}');
    }
  }

  /// Floating bubble servisini durdur
  static Future<void> stopBubble() async {
    try {
      await _bubbleChannel.invokeMethod('stopBubble');
    } on PlatformException {
      // Zaten duruyorsa görmezden gel
    }
  }

  // ─────────────────────────────────────────────────────
  // WATER DATA SYNC
  // ─────────────────────────────────────────────────────

  /// Su verisini native katmana senkronize et
  /// (Wallpaper + Bubble servisini günceller)
  static Future<void> syncWaterData({
    required int remainingMl,
    required int targetMl,
    String unit = 'ml',
  }) async {
    try {
      await _waterChannel.invokeMethod('syncWaterData', {
        'remaining_ml': remainingMl,
        'target_ml': targetMl,
        'unit': unit,
      });
    } on PlatformException {
      // Sessizce geç
    }
  }

  /// Bubble servisi tarafından eklenen bekleyen kayıtları al
  static Future<Map<String, dynamic>?> getPendingIntakes() async {
    try {
      final result =
          await _waterChannel.invokeMethod<Map>('getPendingIntakes');
      if (result == null) return null;
      return Map<String, dynamic>.from(result);
    } on PlatformException {
      return null;
    }
  }
}
