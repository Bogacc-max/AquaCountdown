import 'dart:math';
import 'package:flutter/material.dart';

class BottleThemeData {
  final String id;
  final String displayName;
  final double waveAmplitude1;
  final double waveAmplitude2;

  const BottleThemeData({
    required this.id,
    required this.displayName,
    this.waveAmplitude1 = 7.0,
    this.waveAmplitude2 = 4.0,
  });

  Path buildCupPath(double l, double t, double r, double b) {
    final narrowing = (r - l) * 0.07;
    const radius = 14.0;
    return Path()
      ..moveTo(l + radius, t)
      ..lineTo(r - radius, t)
      ..quadraticBezierTo(r, t, r, t + radius)
      ..lineTo(r - narrowing, b - radius)
      ..quadraticBezierTo(r - narrowing, b, r - narrowing - radius, b)
      ..lineTo(l + narrowing + radius, b)
      ..quadraticBezierTo(l + narrowing, b, l + narrowing, b - radius)
      ..lineTo(l, t + radius)
      ..quadraticBezierTo(l, t, l + radius, t)
      ..close();
  }

  Color colorForLevel(int remainingMl) {
    if (remainingMl <= 0) return const Color(0xFF26C6DA);
    if (remainingMl <= 250) return const Color(0xFFFFD54F);
    if (remainingMl <= 500) return const Color(0xFF26C6DA);
    if (remainingMl <= 1000) return const Color(0xFF00BCD4);
    if (remainingMl <= 2000) return const Color(0xFF039BE5);
    if (remainingMl <= 3000) return const Color(0xFF0288D1);
    return const Color(0xFF0277BD);
  }

  Color get glowColor => const Color(0xFFFFD54F);

  static BottleThemeData fromId(String id) => switch (id) {
        'modern' => const ModernBottleTheme(),
        'nature' => const NatureBottleTheme(),
        'minimal' || 'premium' => const MinimalBottleTheme(),
        _ => const BottleThemeData(id: 'classic', displayName: 'Klasik'),
      };

  static List<BottleThemeData> get all => const [
        BottleThemeData(id: 'classic', displayName: 'Klasik'),
        ModernBottleTheme(),
        NatureBottleTheme(),
        MinimalBottleTheme(),
      ];
}

class ModernBottleTheme extends BottleThemeData {
  const ModernBottleTheme()
      : super(
          id: 'modern',
          displayName: 'Modern',
          waveAmplitude1: 5.0,
          waveAmplitude2: 3.0,
        );

  @override
  Path buildCupPath(double l, double t, double r, double b) {
    final w = r - l;
    final h = b - t;
    final neckW = w * 0.4;
    final neckH = h * 0.12;
    final neckL = l + (w - neckW) / 2;
    final neckR = neckL + neckW;
    const radius = 20.0;

    return Path()
      ..moveTo(neckL + 4, t)
      ..lineTo(neckR - 4, t)
      ..quadraticBezierTo(neckR, t, neckR, t + 4)
      ..lineTo(neckR, t + neckH)
      ..lineTo(r - radius, t + neckH + 10)
      ..quadraticBezierTo(r, t + neckH + 10, r, t + neckH + 10 + radius)
      ..lineTo(r - 2, b - radius)
      ..quadraticBezierTo(r - 2, b, r - 2 - radius, b)
      ..lineTo(l + 2 + radius, b)
      ..quadraticBezierTo(l + 2, b, l + 2, b - radius)
      ..lineTo(l, t + neckH + 10 + radius)
      ..quadraticBezierTo(l, t + neckH + 10, neckL, t + neckH)
      ..lineTo(neckL, t + 4)
      ..quadraticBezierTo(neckL, t, neckL + 4, t)
      ..close();
  }

  @override
  Color colorForLevel(int remainingMl) {
    if (remainingMl <= 0) return const Color(0xFF80DEEA);
    if (remainingMl <= 250) return const Color(0xFFFFAB40);
    if (remainingMl <= 500) return const Color(0xFF4DD0E1);
    if (remainingMl <= 1000) return const Color(0xFF26C6DA);
    if (remainingMl <= 2000) return const Color(0xFF00ACC1);
    if (remainingMl <= 3000) return const Color(0xFF0097A7);
    return const Color(0xFF00838F);
  }
}

class NatureBottleTheme extends BottleThemeData {
  const NatureBottleTheme()
      : super(
          id: 'nature',
          displayName: 'Doğal',
          waveAmplitude1: 9.0,
          waveAmplitude2: 5.0,
        );

  @override
  Path buildCupPath(double l, double t, double r, double b) {
    final w = r - l;
    final h = b - t;
    final cx = (l + r) / 2;

    return Path()
      ..moveTo(cx, t)
      ..cubicTo(r + w * 0.1, t + h * 0.15, r + w * 0.05, t + h * 0.45, r - w * 0.02, t + h * 0.55)
      ..cubicTo(r + w * 0.02, t + h * 0.7, r - w * 0.05, t + h * 0.9, cx, b)
      ..cubicTo(l + w * 0.05, t + h * 0.9, l - w * 0.02, t + h * 0.7, l + w * 0.02, t + h * 0.55)
      ..cubicTo(l - w * 0.05, t + h * 0.45, l - w * 0.1, t + h * 0.15, cx, t)
      ..close();
  }

  @override
  Color colorForLevel(int remainingMl) {
    if (remainingMl <= 0) return const Color(0xFF81C784);
    if (remainingMl <= 250) return const Color(0xFFFFD54F);
    if (remainingMl <= 500) return const Color(0xFF66BB6A);
    if (remainingMl <= 1000) return const Color(0xFF4CAF50);
    if (remainingMl <= 2000) return const Color(0xFF43A047);
    if (remainingMl <= 3000) return const Color(0xFF388E3C);
    return const Color(0xFF2E7D32);
  }

  @override
  Color get glowColor => const Color(0xFFA5D6A7);
}

class MinimalBottleTheme extends BottleThemeData {
  const MinimalBottleTheme()
      : super(
          id: 'minimal',
          displayName: 'Minimal',
          waveAmplitude1: 10.0,
          waveAmplitude2: 6.0,
        );

  @override
  Path buildCupPath(double l, double t, double r, double b) {
    final cx = (l + r) / 2;
    final cy = (t + b) / 2;
    final radius = min(r - l, b - t) / 2;
    return Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: radius));
  }

  @override
  Color colorForLevel(int remainingMl) {
    if (remainingMl <= 0) return const Color(0xFF90CAF9);
    if (remainingMl <= 250) return const Color(0xFFFFCC80);
    if (remainingMl <= 500) return const Color(0xFF64B5F6);
    if (remainingMl <= 1000) return const Color(0xFF42A5F5);
    if (remainingMl <= 2000) return const Color(0xFF2196F3);
    if (remainingMl <= 3000) return const Color(0xFF1E88E5);
    return const Color(0xFF1565C0);
  }
}
