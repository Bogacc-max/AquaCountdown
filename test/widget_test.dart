import 'package:flutter_test/flutter_test.dart';
import 'package:aquacountdown/data/models/daily_record.dart';
import 'package:aquacountdown/data/models/water_intake.dart';
import 'package:aquacountdown/data/models/user_settings.dart';

void main() {
  group('DailyRecord', () {
    test('remainingMl clamps to 0', () {
      final record = DailyRecord(
        dateKey: '2025-06-01',
        consumedMl: 3000,
        targetMl: 2500,
      );
      expect(record.remainingMl, 0);
    });

    test('progressRatio clamps to 1.0', () {
      final record = DailyRecord(
        dateKey: '2025-06-01',
        consumedMl: 3000,
        targetMl: 2500,
      );
      expect(record.progressRatio, 1.0);
    });

    test('goalReached is true when consumed >= target', () {
      final record = DailyRecord(
        dateKey: '2025-06-01',
        consumedMl: 2500,
        targetMl: 2500,
      );
      expect(record.goalReached, true);
    });

    test('formatDate produces correct format', () {
      final date = DateTime(2025, 1, 5);
      expect(DailyRecord.formatDate(date), '2025-01-05');
    });
  });

  group('WaterIntake', () {
    test('create sets timestamp to now if not provided', () {
      final before = DateTime.now();
      final intake = WaterIntake.create(amountMl: 200);
      final after = DateTime.now();
      expect(intake.timestamp.isAfter(before.subtract(const Duration(seconds: 1))), true);
      expect(intake.timestamp.isBefore(after.add(const Duration(seconds: 1))), true);
      expect(intake.amountMl, 200);
    });

    test('fromMap and toMap roundtrip', () {
      final original = WaterIntake(
        id: 1,
        timestamp: DateTime(2025, 6, 1, 14, 30),
        amountMl: 330,
        glassType: 'bottle',
      );
      final map = original.toMap();
      final restored = WaterIntake.fromMap(map);
      expect(restored.amountMl, 330);
      expect(restored.glassType, 'bottle');
      expect(restored.isDeleted, false);
    });

    test('displayText formats correctly', () {
      expect(WaterIntake.create(amountMl: 500).displayText, '500 ml');
      expect(WaterIntake.create(amountMl: 1500).displayText, '1.5 L');
    });
  });

  group('UserSettings', () {
    test('calculateTarget returns clamped value', () {
      final target = UserSettings.calculateTarget(
        weightKg: 70,
        activityLevel: 'medium',
        gender: 'male',
      );
      expect(target, greaterThanOrEqualTo(1000));
      expect(target, lessThanOrEqualTo(6000));
    });

    test('defaults creates valid settings', () {
      final settings = UserSettings.defaults();
      expect(settings.dailyTargetMl, 2500);
      expect(settings.onboardingCompleted, false);
      expect(settings.unit, 'ml');
    });
  });
}
