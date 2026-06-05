import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/daily_record.dart';

class ShareService {
  static Future<void> shareStoryCard({
    required DailyRecord record,
    required int streak,
    required String unit,
  }) async {
    final imageBytes = await _generateStoryCard(
      record: record,
      streak: streak,
      unit: unit,
    );
    if (imageBytes == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/aquacountdown_story.png');
    await file.writeAsBytes(imageBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'AquaCountdown ile bugün ${_fmt(record.consumedMl, unit)} su içtim! 💧',
    );
  }

  static Future<Uint8List?> _generateStoryCard({
    required DailyRecord record,
    required int streak,
    required String unit,
  }) async {
    const width = 1080.0;
    const height = 1920.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, width, height));

    // Arkaplan gradyan
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A1929), Color(0xFF0D2137), Color(0xFF006064)],
      ).createShader(const Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), bgPaint);

    // Su damlası ikonu (büyük, üst ortada)
    final iconPainter = TextPainter(
      text: const TextSpan(text: '💧', style: TextStyle(fontSize: 120)),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(canvas, Offset((width - iconPainter.width) / 2, 350));

    // AquaCountdown başlığı
    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'AquaCountdown',
        style: TextStyle(
          color: Color(0xFF00BCD4),
          fontSize: 64,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(canvas, Offset((width - titlePainter.width) / 2, 520));

    // İlerleme yüzdesi
    final percentage = (record.progressRatio * 100).round();
    final percentPainter = TextPainter(
      text: TextSpan(
        text: '%$percentage',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 160,
          fontWeight: FontWeight.w900,
          letterSpacing: -4,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    percentPainter.paint(
        canvas, Offset((width - percentPainter.width) / 2, 700));

    // "tamamlandı" alt yazı
    final subPainter = TextPainter(
      text: const TextSpan(
        text: 'tamamlandı',
        style: TextStyle(
          color: Color(0x99FFFFFF),
          fontSize: 48,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    subPainter.paint(canvas, Offset((width - subPainter.width) / 2, 880));

    // İlerleme çubuğu
    const barY = 1000.0;
    const barH = 24.0;
    const barMargin = 120.0;
    final barWidth = width - barMargin * 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barMargin, barY, barWidth, barH),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0x30FFFFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barMargin, barY, barWidth * record.progressRatio, barH),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF00BCD4),
    );

    // İstatistikler
    final consumed = _fmt(record.consumedMl, unit);
    final target = _fmt(record.targetMl, unit);

    final statPainter = TextPainter(
      text: TextSpan(
        text: '$consumed / $target',
        style: const TextStyle(
          color: Color(0xB3FFFFFF),
          fontSize: 44,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    statPainter.paint(canvas, Offset((width - statPainter.width) / 2, 1080));

    // Streak
    if (streak > 0) {
      final streakPainter = TextPainter(
        text: TextSpan(
          text: '🔥 $streak günlük seri',
          style: const TextStyle(
            color: Color(0xFFFFD54F),
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      streakPainter.paint(
          canvas, Offset((width - streakPainter.width) / 2, 1180));
    }

    // Alt branding
    final brandPainter = TextPainter(
      text: const TextSpan(
        text: 'aquacountdown.app',
        style: TextStyle(
          color: Color(0x60FFFFFF),
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    brandPainter.paint(
        canvas, Offset((width - brandPainter.width) / 2, height - 120));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static String _fmt(int ml, String unit) {
    if (unit == 'oz') return '${(ml / 29.5735).toStringAsFixed(0)} oz';
    return ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1)} L' : '$ml ml';
  }
}
