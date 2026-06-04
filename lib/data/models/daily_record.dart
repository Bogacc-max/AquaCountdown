import 'water_intake.dart';

/// Günlük su takip kaydı
class DailyRecord {
  final String dateKey; // "YYYY-MM-DD"
  int consumedMl;
  int targetMl;
  List<WaterIntake> intakes;

  DailyRecord({
    required this.dateKey,
    required this.consumedMl,
    required this.targetMl,
    List<WaterIntake>? intakes,
  }) : intakes = intakes ?? [];

  factory DailyRecord.forToday({required int targetMl}) {
    final now = DateTime.now();
    return DailyRecord(
      dateKey: _formatDate(now),
      consumedMl: 0,
      targetMl: targetMl,
    );
  }

  factory DailyRecord.fromMap(Map<String, dynamic> map) {
    return DailyRecord(
      dateKey: map['date_key'] as String,
      consumedMl: map['consumed_ml'] as int,
      targetMl: map['target_ml'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date_key': dateKey,
      'consumed_ml': consumedMl,
      'target_ml': targetMl,
    };
  }

  /// Kalan miktar (0'ın altına düşmez)
  int get remainingMl => (targetMl - consumedMl).clamp(0, targetMl);

  /// Hedef tamamlandı mı?
  bool get goalReached => consumedMl >= targetMl;

  /// İlerleme yüzdesi (0.0 – 1.0)
  double get progressRatio =>
      targetMl > 0 ? (consumedMl / targetMl).clamp(0.0, 1.0) : 0.0;

  /// Görüntü metni: "1.5 L / 2.5 L"
  String get progressText {
    final consumed = consumedMl >= 1000
        ? '${(consumedMl / 1000).toStringAsFixed(1)} L'
        : '$consumedMl ml';
    final target = targetMl >= 1000
        ? '${(targetMl / 1000).toStringAsFixed(1)} L'
        : '$targetMl ml';
    return '$consumed / $target';
  }

  DateTime get date {
    final parts = dateKey.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static String formatDate(DateTime dt) => _formatDate(dt);

  /// Tarih karşılaştırması için normalize
  static DateTime normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
