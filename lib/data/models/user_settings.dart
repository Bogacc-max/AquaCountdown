import 'package:flutter/material.dart';

/// Kullanıcı ayarları — SharedPreferences üzerinde saklanır
class UserSettings {
  // ─── Hedef ───────────────────────────────────────
  int dailyTargetMl;
  int defaultGlassSizeMl;

  // ─── Kullanıcı Profili ────────────────────────────
  String gender; // 'male' | 'female' | 'other'
  int weightKg;
  int ageYears;
  String activityLevel; // 'low' | 'medium' | 'high' | 'athlete'

  // ─── Bildirimler ─────────────────────────────────
  bool notificationsEnabled;
  int reminderIntervalMinutes;
  int wakeHour;
  int wakeMinute;
  int sleepHour;
  int sleepMinute;
  int? quietStartHour;
  int? quietStartMinute;
  int? quietEndHour;
  int? quietEndMinute;

  // ─── Görünüm ─────────────────────────────────────
  String themeMode; // 'light' | 'dark' | 'system'
  String bottleTheme; // 'classic' | 'modern' | 'nature' | 'premium'
  String unit; // 'ml' | 'oz'

  // ─── Native Özellikler ────────────────────────────
  bool wallpaperEnabled;
  bool floatingBubbleEnabled;
  double bubbleOpacity;
  String bubbleSize; // 'S' | 'M' | 'L'

  // ─── Uygulama ─────────────────────────────────────
  bool onboardingCompleted;
  bool soundEnabled;
  bool hapticEnabled;

  UserSettings({
    required this.dailyTargetMl,
    required this.defaultGlassSizeMl,
    required this.gender,
    required this.weightKg,
    required this.ageYears,
    required this.activityLevel,
    required this.notificationsEnabled,
    required this.reminderIntervalMinutes,
    required this.wakeHour,
    required this.wakeMinute,
    required this.sleepHour,
    required this.sleepMinute,
    this.quietStartHour,
    this.quietStartMinute,
    this.quietEndHour,
    this.quietEndMinute,
    required this.themeMode,
    required this.bottleTheme,
    required this.unit,
    required this.wallpaperEnabled,
    required this.floatingBubbleEnabled,
    required this.bubbleOpacity,
    required this.bubbleSize,
    required this.onboardingCompleted,
    required this.soundEnabled,
    required this.hapticEnabled,
  });

  factory UserSettings.defaults() {
    return UserSettings(
      dailyTargetMl: 2500,
      defaultGlassSizeMl: 200,
      gender: 'other',
      weightKg: 70,
      ageYears: 30,
      activityLevel: 'medium',
      notificationsEnabled: true,
      reminderIntervalMinutes: 60,
      wakeHour: 7,
      wakeMinute: 0,
      sleepHour: 23,
      sleepMinute: 0,
      themeMode: 'system',
      bottleTheme: 'classic',
      unit: 'ml',
      wallpaperEnabled: false,
      floatingBubbleEnabled: false,
      bubbleOpacity: 0.9,
      bubbleSize: 'M',
      onboardingCompleted: false,
      soundEnabled: true,
      hapticEnabled: true,
    );
  }

  static int calculateTarget({
    required int weightKg,
    required String activityLevel,
    required String gender,
  }) {
    double base = weightKg * 35.0;
    final bonus = switch (activityLevel) {
      'low' => 0,
      'medium' => 300,
      'high' => 600,
      'athlete' => 1000,
      _ => 300,
    };
    final genderFactor = gender == 'male' ? 1.0 : 0.9;
    return ((base * genderFactor) + bonus).round().clamp(1000, 6000);
  }

  TimeOfDay get wakeTime => TimeOfDay(hour: wakeHour, minute: wakeMinute);
  TimeOfDay get sleepTime => TimeOfDay(hour: sleepHour, minute: sleepMinute);

  UserSettings copy() => UserSettings(
        dailyTargetMl: dailyTargetMl,
        defaultGlassSizeMl: defaultGlassSizeMl,
        gender: gender,
        weightKg: weightKg,
        ageYears: ageYears,
        activityLevel: activityLevel,
        notificationsEnabled: notificationsEnabled,
        reminderIntervalMinutes: reminderIntervalMinutes,
        wakeHour: wakeHour,
        wakeMinute: wakeMinute,
        sleepHour: sleepHour,
        sleepMinute: sleepMinute,
        quietStartHour: quietStartHour,
        quietStartMinute: quietStartMinute,
        quietEndHour: quietEndHour,
        quietEndMinute: quietEndMinute,
        themeMode: themeMode,
        bottleTheme: bottleTheme,
        unit: unit,
        wallpaperEnabled: wallpaperEnabled,
        floatingBubbleEnabled: floatingBubbleEnabled,
        bubbleOpacity: bubbleOpacity,
        bubbleSize: bubbleSize,
        onboardingCompleted: onboardingCompleted,
        soundEnabled: soundEnabled,
        hapticEnabled: hapticEnabled,
      );
}
