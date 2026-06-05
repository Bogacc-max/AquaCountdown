import 'package:flutter_test/flutter_test.dart';
import 'package:aquacountdown/data/models/daily_record.dart';
import 'package:aquacountdown/data/models/water_intake.dart';
import 'package:aquacountdown/data/models/user_settings.dart';
import 'package:aquacountdown/data/models/achievement.dart';
import 'package:aquacountdown/presentation/widgets/bottle_theme.dart';
import 'package:aquacountdown/core/platform/notification_messages.dart';

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

    test('progressRatio is 0 when nothing consumed', () {
      final record = DailyRecord(
        dateKey: '2025-06-01',
        consumedMl: 0,
        targetMl: 2500,
      );
      expect(record.progressRatio, 0.0);
      expect(record.goalReached, false);
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

    test('formatDate pads single digit month and day', () {
      expect(DailyRecord.formatDate(DateTime(2025, 3, 9)), '2025-03-09');
      expect(DailyRecord.formatDate(DateTime(2025, 12, 25)), '2025-12-25');
    });

    test('progressText formats correctly', () {
      final record = DailyRecord(
        dateKey: '2025-06-01',
        consumedMl: 1500,
        targetMl: 2500,
      );
      expect(record.progressText, '1.5 L / 2.5 L');
    });

    test('progressText uses ml for small amounts', () {
      final record = DailyRecord(
        dateKey: '2025-06-01',
        consumedMl: 500,
        targetMl: 900,
      );
      expect(record.progressText, '500 ml / 900 ml');
    });

    test('date getter parses dateKey correctly', () {
      final record = DailyRecord(
        dateKey: '2025-06-15',
        consumedMl: 0,
        targetMl: 2500,
      );
      expect(record.date.year, 2025);
      expect(record.date.month, 6);
      expect(record.date.day, 15);
    });
  });

  group('WaterIntake', () {
    test('create sets timestamp to now if not provided', () {
      final before = DateTime.now();
      final intake = WaterIntake.create(amountMl: 200);
      final after = DateTime.now();
      expect(
          intake.timestamp
              .isAfter(before.subtract(const Duration(seconds: 1))),
          true);
      expect(
          intake.timestamp.isBefore(after.add(const Duration(seconds: 1))),
          true);
      expect(intake.amountMl, 200);
    });

    test('create uses provided timestamp', () {
      final ts = DateTime(2025, 3, 15, 10, 30);
      final intake = WaterIntake.create(amountMl: 500, timestamp: ts);
      expect(intake.timestamp, ts);
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

    test('isDeleted returns true when deletedAt is set', () {
      final intake = WaterIntake(
        timestamp: DateTime.now(),
        amountMl: 200,
        deletedAt: DateTime.now(),
      );
      expect(intake.isDeleted, true);
    });

    test('copyWith sets deletedAt', () {
      final intake = WaterIntake.create(amountMl: 200);
      final deleted = intake.copyWith(deletedAt: DateTime.now());
      expect(deleted.isDeleted, true);
      expect(deleted.amountMl, 200);
    });

    test('displayText formats correctly', () {
      expect(WaterIntake.create(amountMl: 500).displayText, '500 ml');
      expect(WaterIntake.create(amountMl: 1500).displayText, '1.5 L');
      expect(WaterIntake.create(amountMl: 1000).displayText, '1.0 L');
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

    test('calculateTarget differs by gender', () {
      final male = UserSettings.calculateTarget(
        weightKg: 80,
        activityLevel: 'medium',
        gender: 'male',
      );
      final female = UserSettings.calculateTarget(
        weightKg: 80,
        activityLevel: 'medium',
        gender: 'female',
      );
      expect(male, greaterThan(female));
    });

    test('calculateTarget increases with activity level', () {
      final low = UserSettings.calculateTarget(
        weightKg: 70,
        activityLevel: 'low',
        gender: 'male',
      );
      final athlete = UserSettings.calculateTarget(
        weightKg: 70,
        activityLevel: 'athlete',
        gender: 'male',
      );
      expect(athlete, greaterThan(low));
    });

    test('calculateTarget clamps extreme values', () {
      final tiny = UserSettings.calculateTarget(
        weightKg: 40,
        activityLevel: 'low',
        gender: 'female',
      );
      final huge = UserSettings.calculateTarget(
        weightKg: 150,
        activityLevel: 'athlete',
        gender: 'male',
      );
      expect(tiny, greaterThanOrEqualTo(1000));
      expect(huge, lessThanOrEqualTo(6000));
    });

    test('defaults creates valid settings', () {
      final settings = UserSettings.defaults();
      expect(settings.dailyTargetMl, 2500);
      expect(settings.onboardingCompleted, false);
      expect(settings.unit, 'ml');
      expect(settings.language, 'tr');
      expect(settings.healthSyncEnabled, false);
      expect(settings.bottleTheme, 'classic');
    });

    test('copy creates independent instance', () {
      final original = UserSettings.defaults();
      final copied = original.copy();
      copied.dailyTargetMl = 3000;
      expect(original.dailyTargetMl, 2500);
      expect(copied.dailyTargetMl, 3000);
    });
  });

  group('Achievement', () {
    test('all() returns 10 achievements', () {
      final achievements = Achievement.all();
      expect(achievements.length, 10);
    });

    test('all achievements have unique ids', () {
      final ids = Achievement.all().map((a) => a.id).toSet();
      expect(ids.length, 10);
    });

    test('isUnlocked is false by default', () {
      final a = Achievement.all().first;
      expect(a.isUnlocked, false);
    });

    test('isUnlocked is true when unlockedAt is set', () {
      final a = Achievement.all().first;
      a.unlockedAt = DateTime.now();
      expect(a.isUnlocked, true);
    });

    test('progressRatio clamps correctly', () {
      final a = Achievement.all().first;
      a.progress = 0;
      expect(a.progressRatio, 0.0);
      a.progress = 1;
      expect(a.progressRatio, 1.0);
    });

    test('all achievements have non-empty title and description', () {
      for (final a in Achievement.all()) {
        expect(a.title.isNotEmpty, true);
        expect(a.description.isNotEmpty, true);
        expect(a.icon.isNotEmpty, true);
        expect(a.target, greaterThan(0));
      }
    });
  });

  group('BottleThemeData', () {
    test('fromId returns correct theme for each id', () {
      expect(BottleThemeData.fromId('classic').id, 'classic');
      expect(BottleThemeData.fromId('modern').id, 'modern');
      expect(BottleThemeData.fromId('nature').id, 'nature');
      expect(BottleThemeData.fromId('minimal').id, 'minimal');
    });

    test('fromId treats premium as minimal alias', () {
      expect(BottleThemeData.fromId('premium').id, 'minimal');
    });

    test('fromId defaults to classic for unknown id', () {
      expect(BottleThemeData.fromId('unknown').id, 'classic');
    });

    test('all themes have 4 entries', () {
      expect(BottleThemeData.all.length, 4);
    });

    test('each theme has unique id', () {
      final ids = BottleThemeData.all.map((t) => t.id).toSet();
      expect(ids.length, 4);
    });

    test('colorForLevel returns different colors for different levels', () {
      final theme = BottleThemeData.fromId('classic');
      final c0 = theme.colorForLevel(0);
      final c500 = theme.colorForLevel(500);
      final c2000 = theme.colorForLevel(2000);
      expect(c0, isNot(equals(c2000)));
      expect(c500, isNot(equals(c2000)));
    });

    test('nature theme uses green palette', () {
      final nature = BottleThemeData.fromId('nature');
      final color = nature.colorForLevel(1500);
      // Green channel should be dominant
      expect(color.green, greaterThan(color.red));
      expect(color.green, greaterThan(color.blue));
    });
  });

  group('NotificationMessages', () {
    test('getForTime returns morning message before noon', () {
      final msg = NotificationMessages.getForTime(8);
      expect(msg.title.isNotEmpty, true);
      expect(msg.body.isNotEmpty, true);
    });

    test('getForTime returns afternoon message 12-18', () {
      final msg = NotificationMessages.getForTime(14);
      expect(msg.title.isNotEmpty, true);
      expect(msg.body.isNotEmpty, true);
    });

    test('getForTime returns evening message after 18', () {
      final msg = NotificationMessages.getForTime(21);
      expect(msg.title.isNotEmpty, true);
      expect(msg.body.isNotEmpty, true);
    });

    test('getForTime returns streak message when streak >= 3', () {
      final msg = NotificationMessages.getForTime(10, streak: 5);
      expect(msg.body.contains('5'), true);
    });

    test('getForTime does not return streak message when streak < 3', () {
      final msg1 = NotificationMessages.getForTime(10, streak: 0);
      final msg2 = NotificationMessages.getForTime(10, streak: 2);
      // Should return regular morning message, not streak
      expect(msg1.body.contains('gündür'), false);
      expect(msg2.body.contains('gündür'), false);
    });
  });
}
