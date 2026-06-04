import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/daily_record.dart';
import '../../data/models/user_settings.dart';
import '../../data/models/water_intake.dart';
import '../../data/repositories/water_repository.dart';
import '../../core/platform/native_bridge.dart';

// ─────────────────────────────────────────────────────
// REPOSITORY PROVIDER
// ─────────────────────────────────────────────────────

final repositoryProvider = FutureProvider<WaterRepository>((ref) async {
  return WaterRepository.getInstance();
});

// ─────────────────────────────────────────────────────
// SETTINGS PROVIDER
// ─────────────────────────────────────────────────────

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AsyncValue<UserSettings>>((ref) {
  return SettingsNotifier(ref);
});

class SettingsNotifier extends StateNotifier<AsyncValue<UserSettings>> {
  SettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;
  StreamSubscription? _sub;

  Future<void> _load() async {
    try {
      final repo = await _ref.read(repositoryProvider.future);
      final settings = await repo.getSettings();
      state = AsyncValue.data(settings);

      // Gerçek zamanlı değişiklikleri dinle
      _sub = repo.watchSettings().listen((s) {
        if (s != null) state = AsyncValue.data(s);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> save(UserSettings settings) async {
    final repo = await _ref.read(repositoryProvider.future);
    await repo.saveSettings(settings);
    state = AsyncValue.data(settings);

    // Native katmanı güncelle
    await NativeBridge.syncWaterData(
      remainingMl: _ref.read(todayRecordProvider).valueOrNull?.remainingMl ?? 0,
      targetMl: settings.dailyTargetMl,
      unit: settings.unit,
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────
// BUGÜNKÜ KAYIT PROVIDER
// ─────────────────────────────────────────────────────

final todayRecordProvider =
    StateNotifierProvider<TodayRecordNotifier, AsyncValue<DailyRecord>>((ref) {
  return TodayRecordNotifier(ref);
});

class TodayRecordNotifier extends StateNotifier<AsyncValue<DailyRecord>> {
  TodayRecordNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
    _listenNativeEvents();
  }

  final Ref _ref;
  StreamSubscription? _dbSub;
  StreamSubscription? _nativeSub;

  Future<void> _load() async {
    try {
      final repo = await _ref.read(repositoryProvider.future);

      // Uygulama kapalıyken bubble'dan eklenen bekleyen kayıtları işle
      await _flushPendingBubbleIntakes(repo);

      final record = await repo.getTodayRecord();
      state = AsyncValue.data(record);

      // Gece yarısı otomatik yenileme
      _scheduleMidnightRefresh();

      // DB değişikliklerini izle
      _dbSub = repo.watchTodayRecord().listen((r) {
        if (r != null) state = AsyncValue.data(r);
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _flushPendingBubbleIntakes(WaterRepository repo) async {
    try {
      final pending = await NativeBridge.getPendingIntakes();
      if (pending == null) return;
      final amountMl = pending['amount_ml'] as int? ?? 0;
      if (amountMl <= 0) return;

      final timestamp = pending['timestamp'] as int?;
      await repo.addIntake(
        amountMl: amountMl,
        glassType: 'bubble',
        timestamp: timestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(timestamp)
            : null,
      );
    } catch (_) {
      // Bekleyen kayıt alınamazsa sessizce geç
    }
  }

  /// Native baloncuktan gelen su ekleme eventlerini dinle
  void _listenNativeEvents() {
    _nativeSub = NativeBridge.nativeEvents.listen((event) {
      if (event['type'] == 'water_added') {
        final amountMl = event['amount_ml'] as int? ?? 0;
        if (amountMl > 0) addWater(amountMl: amountMl, fromNative: true);
      }
    });
  }

  Future<void> addWater({
    required int amountMl,
    String glassType = 'default',
    bool fromNative = false,
  }) async {
    try {
      final repo = await _ref.read(repositoryProvider.future);
      final intake = await repo.addIntake(
        amountMl: amountMl,
        glassType: glassType,
      );

      final current = state.valueOrNull;
      if (current != null) {
        final updated = DailyRecord(
          dateKey: current.dateKey,
          targetMl: current.targetMl,
          consumedMl: current.consumedMl + amountMl,
          intakes: [...current.intakes, intake],
        );
        state = AsyncValue.data(updated);

        // Native katmanı güncelle (double sync önle)
        if (!fromNative) {
          final settings = _ref.read(settingsProvider).valueOrNull;
          await NativeBridge.syncWaterData(
            remainingMl: updated.remainingMl,
            targetMl: updated.targetMl,
            unit: settings?.unit ?? 'ml',
          );
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> removeIntake(int intakeId) async {
    final repo = await _ref.read(repositoryProvider.future);
    await repo.deleteIntake(intakeId);
    final record = await repo.getTodayRecord();
    state = AsyncValue.data(record);

    final settings = _ref.read(settingsProvider).valueOrNull;
    await NativeBridge.syncWaterData(
      remainingMl: record.remainingMl,
      targetMl: record.targetMl,
      unit: settings?.unit ?? 'ml',
    );
  }

  void _scheduleMidnightRefresh() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    Future.delayed(diff, () {
      _load();
    });
  }

  @override
  void dispose() {
    _dbSub?.cancel();
    _nativeSub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────
// STREAK PROVIDER
// ─────────────────────────────────────────────────────

final streakProvider = FutureProvider<int>((ref) async {
  final repo = await ref.watch(repositoryProvider.future);
  return repo.calculateStreak();
});

// ─────────────────────────────────────────────────────
// RAPOR PROVIDER
// ─────────────────────────────────────────────────────

final weeklyRecordsProvider = FutureProvider<List<DailyRecord>>((ref) async {
  final repo = await ref.watch(repositoryProvider.future);
  return repo.getLastNDays(7);
});

final monthlyRecordsProvider =
    FutureProvider.family<List<DailyRecord>, ({int year, int month})>(
        (ref, args) async {
  final repo = await ref.watch(repositoryProvider.future);
  return repo.getMonthRecords(args.year, args.month);
});

// ─────────────────────────────────────────────────────
// TODAY'S INTAKES (gerçek zamanlı liste)
// ─────────────────────────────────────────────────────

final todayIntakesProvider = FutureProvider<List<WaterIntake>>((ref) async {
  final repo = await ref.watch(repositoryProvider.future);
  final record = await repo.getTodayRecord();
  return record.intakes
      .where((i) => !i.isDeleted)
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
});
