import '../models/achievement.dart';
import '../models/daily_record.dart';
import '../repositories/water_repository.dart';

class AchievementService {
  final WaterRepository _repo;

  AchievementService(this._repo);

  Future<List<Achievement>> checkAfterWaterAdd({
    required int amountMl,
    required DailyRecord record,
    required int streak,
    required DateTime timestamp,
  }) async {
    final achievements = await _repo.getAchievements();
    final unlocked = <Achievement>[];

    for (final a in achievements) {
      if (a.isUnlocked) continue;

      bool shouldUnlock = false;

      switch (a.type) {
        case AchievementType.ilkYudum:
          shouldUnlock = true;

        case AchievementType.ucGun:
          await _repo.updateAchievementProgress(a.id, streak);
          shouldUnlock = streak >= 3;

        case AchievementType.yediGun:
          await _repo.updateAchievementProgress(a.id, streak);
          shouldUnlock = streak >= 7;

        case AchievementType.otuzGun:
          await _repo.updateAchievementProgress(a.id, streak);
          shouldUnlock = streak >= 30;

        case AchievementType.erkenKus:
          shouldUnlock = timestamp.hour < 7;

        case AchievementType.geceSavascisi:
          shouldUnlock = timestamp.hour >= 22;

        case AchievementType.litrelik:
          shouldUnlock = amountMl >= 1000;

        case AchievementType.onBinKulubu:
          final total = await _repo.getTotalConsumedAllTime();
          await _repo.updateAchievementProgress(a.id, total);
          shouldUnlock = total >= 10000;

        case AchievementType.tamIsabet:
          shouldUnlock = record.consumedMl == record.targetMl;

        case AchievementType.haftaSonuSavascisi:
          if (record.goalReached) {
            final today = timestamp.weekday;
            if (today == DateTime.saturday || today == DateTime.sunday) {
              final otherDay = today == DateTime.saturday
                  ? timestamp.add(const Duration(days: 1))
                  : timestamp.subtract(const Duration(days: 1));
              final otherRecord = await _repo.getRecordForDate(otherDay);
              shouldUnlock = otherRecord?.goalReached ?? false;
            }
          }
      }

      if (shouldUnlock) {
        await _repo.unlockAchievement(a.id);
        a.unlockedAt = DateTime.now();
        unlocked.add(a);
      }
    }

    return unlocked;
  }
}
