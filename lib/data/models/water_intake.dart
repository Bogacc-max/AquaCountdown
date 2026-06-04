/// Her bir su içme kaydı
class WaterIntake {
  final int? id;
  final DateTime timestamp;
  final int amountMl;
  final String glassType;
  final DateTime? deletedAt;

  const WaterIntake({
    this.id,
    required this.timestamp,
    required this.amountMl,
    this.glassType = 'default',
    this.deletedAt,
  });

  factory WaterIntake.create({
    required int amountMl,
    String glassType = 'default',
    DateTime? timestamp,
  }) {
    return WaterIntake(
      amountMl: amountMl,
      glassType: glassType,
      timestamp: timestamp ?? DateTime.now(),
    );
  }

  factory WaterIntake.fromMap(Map<String, dynamic> map) {
    return WaterIntake(
      id: map['id'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      amountMl: map['amount_ml'] as int,
      glassType: map['glass_type'] as String? ?? 'default',
      deletedAt: map['deleted_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['deleted_at'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'amount_ml': amountMl,
      'glass_type': glassType,
      'deleted_at': deletedAt?.millisecondsSinceEpoch,
    };
  }

  WaterIntake copyWith({DateTime? deletedAt}) {
    return WaterIntake(
      id: id,
      timestamp: timestamp,
      amountMl: amountMl,
      glassType: glassType,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  /// Görüntü metni (200 ml / 0.2 L)
  String get displayText => amountMl >= 1000
      ? '${(amountMl / 1000).toStringAsFixed(1)} L'
      : '$amountMl ml';

  bool get isDeleted => deletedAt != null;
}
