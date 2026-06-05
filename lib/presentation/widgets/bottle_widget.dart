import 'dart:math';
import 'package:flutter/material.dart';
import 'bottle_theme.dart';

/// AquaCountdown Bardak Widget
///
/// CustomPainter + AnimationController kullanarak:
/// - Gerçek zamanlı su seviyesi (0.0 – 1.0)
/// - Dalga animasyonu
/// - Dinamik renk geçişi (seviyeye göre)
/// - Parıltı efekti (düşük seviye)
class BottleWidget extends StatefulWidget {
  /// Su doluluk oranı (0.0 = boş, 1.0 = tamamen dolu)
  final double fillRatio;

  /// Kalan miktar (ml) — etiket için
  final int remainingMl;

  /// Toplam hedef (ml)
  final int targetMl;

  /// Birim ('ml' veya 'oz')
  final String unit;

  /// Widget boyutu
  final double size;

  /// Tamamlandı kutlaması
  final bool showCelebration;

  /// Bardak teması
  final String themeId;

  /// Splash efekti göster
  final bool showSplash;

  const BottleWidget({
    super.key,
    required this.fillRatio,
    required this.remainingMl,
    required this.targetMl,
    this.unit = 'ml',
    this.size = 280,
    this.showCelebration = false,
    this.themeId = 'classic',
    this.showSplash = false,
  });

  @override
  State<BottleWidget> createState() => _BottleWidgetState();
}

class _BottleWidgetState extends State<BottleWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Dalga animasyon kontrolcüsü
  late AnimationController _waveController;
  // Su seviyesi geçiş kontrolcüsü
  late AnimationController _levelController;
  late Animation<double> _levelAnimation;
  // Parıltı animasyonu
  late AnimationController _glowController;
  // Splash efekti
  late AnimationController _splashController;

  double _previousFill = 1.0;

  @override
  void initState() {
    super.initState();

    _previousFill = widget.fillRatio;
    WidgetsBinding.instance.addObserver(this);

    // Sürekli dönen dalga animasyonu
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Su seviyesi değişiminde smooth geçiş (800ms)
    _levelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _levelAnimation = Tween<double>(
      begin: widget.fillRatio,
      end: widget.fillRatio,
    ).animate(CurvedAnimation(
      parent: _levelController,
      curve: Curves.easeOutCubic,
    ));

    // Parıltı animasyonu (düşük seviyede devreye girer)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void didUpdateWidget(BottleWidget old) {
    super.didUpdateWidget(old);
    if (old.fillRatio != widget.fillRatio) {
      _levelAnimation = Tween<double>(
        begin: _previousFill,
        end: widget.fillRatio,
      ).animate(CurvedAnimation(
        parent: _levelController,
        curve: Curves.easeOutCubic,
      ));
      _levelController.forward(from: 0);
      _previousFill = widget.fillRatio;
    }
    if (widget.showSplash && !old.showSplash) {
      _splashController.forward(from: 0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _waveController.stop();
      _glowController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _waveController.repeat();
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveController.dispose();
    _levelController.dispose();
    _glowController.dispose();
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semanticLabel = widget.remainingMl <= 0
        ? 'Günlük su hedefi tamamlandı'
        : '${widget.remainingMl} mililitre su kaldı, hedef ${widget.targetMl} mililitre';

    return Semantics(
      label: semanticLabel,
      value: '${(widget.fillRatio * 100).round()} yüzde dolu',
      child: AnimatedBuilder(
      animation: Listenable.merge([
        _waveController,
        _levelAnimation,
        _glowController,
        _splashController,
      ]),
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size * 1.5,
          child: CustomPaint(
            isComplex: true,
            willChange: true,
            painter: _BottlePainter(
              fillRatio: _levelAnimation.value,
              wavePhase: _waveController.value * 2 * pi,
              remainingMl: widget.remainingMl,
              targetMl: widget.targetMl,
              unit: widget.unit,
              glowIntensity: widget.remainingMl <= 500
                  ? _glowController.value
                  : 0.0,
              themeData: BottleThemeData.fromId(widget.themeId),
              splashProgress: _splashController.value,
            ),
          ),
        );
      },
    ),
    );
  }
}

// ─────────────────────────────────────────────────────
// CUSTOM PAINTER
// ─────────────────────────────────────────────────────

class _BottlePainter extends CustomPainter {
  final double fillRatio;
  final double wavePhase;
  final int remainingMl;
  final int targetMl;
  final String unit;
  final double glowIntensity;
  final BottleThemeData themeData;
  final double splashProgress;

  _BottlePainter({
    required this.fillRatio,
    required this.wavePhase,
    required this.remainingMl,
    required this.targetMl,
    required this.unit,
    required this.glowIntensity,
    required this.themeData,
    required this.splashProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Bardak boyutu ve konumu
    final cupW = w * 0.78;
    final cupH = h * 0.72;
    final cupLeft = (w - cupW) / 2;
    final cupTop = h * 0.04;
    final cupRight = cupLeft + cupW;
    final cupBottom = cupTop + cupH;

    final cupPath = themeData.buildCupPath(cupLeft, cupTop, cupRight, cupBottom);

    // ── Arkaplan (boş bardak) ──
    final bgPaint = Paint()
      ..color = const Color(0x15006064)
      ..style = PaintingStyle.fill;
    canvas.drawPath(cupPath, bgPaint);

    // ── Su dolgu ──
    if (fillRatio > 0) {
      canvas.save();
      canvas.clipPath(cupPath);
      _drawWater(canvas, size, cupLeft, cupTop, cupRight, cupBottom);
      canvas.restore();
    }

    // ── Splash efekti ──
    if (splashProgress > 0 && splashProgress < 1 && fillRatio > 0) {
      canvas.save();
      canvas.clipPath(cupPath);
      _drawSplash(canvas, cupLeft, cupTop, cupRight, cupBottom);
      canvas.restore();
    }

    // ── Cam kenarı ──
    _drawGlassBorder(canvas, cupPath, cupLeft, cupRight);

    // ── Cam yansıması ──
    _drawReflection(canvas, cupLeft, cupTop, cupBottom);

    // ── Parıltı efekti (düşük seviye) ──
    if (glowIntensity > 0) {
      _drawGlow(canvas, cupLeft, cupTop, cupRight, cupBottom);
    }

    // ── Alt metin (kalan miktar) ──
    _drawLabels(canvas, size, cupBottom);
  }

  /// Su katmanı + dalga yüzeyi
  void _drawWater(
    Canvas canvas,
    Size size,
    double l, double t, double r, double b,
  ) {
    final cupH = b - t;
    final waterY = b - cupH * fillRatio;
    final waterColor = themeData.colorForLevel(remainingMl);

    final waterPath = Path()..moveTo(l, b)..lineTo(r, b)..lineTo(r, waterY);

    // Çift dalga sinüs
    final steps = 80;
    final width = r - l;
    for (int i = steps; i >= 0; i--) {
      final x = l + (width * i / steps);
      final rel = (x - l) / width;
      final wave1 = sin(wavePhase + rel * 2 * pi) * themeData.waveAmplitude1;
      final wave2 = sin(wavePhase * 0.7 + rel * 3 * pi) * themeData.waveAmplitude2;
      waterPath.lineTo(x, waterY + wave1 + wave2);
    }
    waterPath.close();

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          waterColor.withOpacity(0.85),
          waterColor,
        ],
      ).createShader(Rect.fromLTRB(l, waterY, r, b))
      ..style = PaintingStyle.fill;

    canvas.drawPath(waterPath, paint);
  }

  /// Cam kenar efekti
  void _drawGlassBorder(
      Canvas canvas, Path cupPath, double l, double r) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.15),
          Colors.white.withOpacity(0.45),
          Colors.white.withOpacity(0.15),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTRB(l, 0, r, 10))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(cupPath, paint);
  }

  /// Sol üst yansıma şeridi
  void _drawReflection(
      Canvas canvas, double l, double t, double b) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTRB(l + 8, t + 16, l + 22, b * 0.55))
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(l + 10, t + 18)
      ..lineTo(l + 20, t + 18)
      ..lineTo(l + 16, b * 0.52)
      ..lineTo(l + 8, b * 0.52)
      ..close();
    canvas.drawPath(path, paint);
  }

  /// Düşük seviye altın parıltı
  void _drawGlow(
    Canvas canvas,
    double l, double t, double r, double b,
  ) {
    final cx = (l + r) / 2;
    final cy = (t + b) / 2;
    final paint = Paint()
      ..color = themeData.glowColor.withOpacity(glowIntensity * 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(
      Offset(cx, cy),
      (r - l) * 0.55,
      paint,
    );
  }

  void _drawSplash(Canvas canvas, double l, double t, double r, double b) {
    final cupH = b - t;
    final waterY = b - cupH * fillRatio;
    final cx = (l + r) / 2;
    final maxRadius = (r - l) * 0.4;
    final opacity = (1.0 - splashProgress) * 0.5;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (splashProgress + i * 0.15).clamp(0.0, 1.0);
      final radius = maxRadius * ringProgress;
      final ringOpacity = (opacity * (1.0 - i * 0.25)).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx, waterY),
        radius,
        Paint()
          ..color = Colors.white.withOpacity(ringOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5 - i * 0.5,
      );
    }
  }

  /// Bardak altı etiketler: "2.5 L" ve "kaldı"
  void _drawLabels(Canvas canvas, Size size, double cupBottom) {
    final displayValue = _formatAmount(remainingMl);
    final cx = size.width / 2;

    // Büyük sayı
    final bigPainter = TextPainter(
      text: TextSpan(
        text: displayValue,
        style: TextStyle(
          color: Colors.white,
          fontSize: size.width * 0.18,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
            )
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    bigPainter.paint(
      canvas,
      Offset(cx - bigPainter.width / 2, cupBottom + size.height * 0.04),
    );

    // "kaldı" alt yazısı
    final subPainter = TextPainter(
      text: TextSpan(
        text: 'kaldı',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: size.width * 0.075,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    subPainter.paint(
      canvas,
      Offset(
        cx - subPainter.width / 2,
        cupBottom + size.height * 0.04 + bigPainter.height + 4,
      ),
    );
  }

  String _formatAmount(int ml) {
    if (unit == 'oz') {
      final oz = ml / 29.5735;
      return '${oz.toStringAsFixed(1)} oz';
    }
    if (ml >= 1000) return '${(ml / 1000).toStringAsFixed(1)} L';
    return '$ml ml';
  }

  @override
  bool shouldRepaint(_BottlePainter old) =>
      old.fillRatio != fillRatio ||
      old.wavePhase != wavePhase ||
      old.remainingMl != remainingMl ||
      old.glowIntensity != glowIntensity ||
      old.themeData.id != themeData.id ||
      old.splashProgress != splashProgress;
}
