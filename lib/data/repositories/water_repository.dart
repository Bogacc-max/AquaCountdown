import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_record.dart';
import '../models/user_settings.dart';
import '../models/water_intake.dart';

/// Su verisi için tek kaynak: sqflite + SharedPreferences
class WaterRepository {
  static WaterRepository? _instance;
  late Database _db;
  late SharedPreferences _prefs;

  // Reaktif akışlar için StreamController'lar
  final _settingsController =
      StreamController<UserSettings?>.broadcast();
  final _todayController =
      StreamController<DailyRecord?>.broadcast();

  WaterRepository._();

  static Future<WaterRepository> getInstance() async {
    if (_instance == null) {
      final repo = WaterRepository._();
      await repo._init();
      _instance = repo;
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();

    final dbPath = p.join(await getDatabasesPath(), 'aquacountdown.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE water_intakes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        amount_ml INTEGER NOT NULL,
        glass_type TEXT NOT NULL DEFAULT 'default',
        deleted_at INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_records (
        date_key TEXT PRIMARY KEY,
        consumed_ml INTEGER NOT NULL DEFAULT 0,
        target_ml INTEGER NOT NULL DEFAULT 2500
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_intakes_timestamp ON water_intakes(timestamp)');
  }

  // ─────────────────────────────────────────────────────
  // KULLANICI AYARLARI (SharedPreferences)
  // ─────────────────────────────────────────────────────

  Future<UserSettings> getSettings() async {
    final s = UserSettings.defaults();
    s.dailyTargetMl = _prefs.getInt('dailyTargetMl') ?? s.dailyTargetMl;
    s.defaultGlassSizeMl =
        _prefs.getInt('defaultGlassSizeMl') ?? s.defaultGlassSizeMl;
    s.gender = _prefs.getString('gender') ?? s.gender;
    s.weightKg = _prefs.getInt('weightKg') ?? s.weightKg;
    s.ageYears = _prefs.getInt('ageYears') ?? s.ageYears;
    s.activityLevel = _prefs.getString('activityLevel') ?? s.activityLevel;
    s.notificationsEnabled =
        _prefs.getBool('notificationsEnabled') ?? s.notificationsEnabled;
    s.reminderIntervalMinutes =
        _prefs.getInt('reminderIntervalMinutes') ?? s.reminderIntervalMinutes;
    s.wakeHour = _prefs.getInt('wakeHour') ?? s.wakeHour;
    s.wakeMinute = _prefs.getInt('wakeMinute') ?? s.wakeMinute;
    s.sleepHour = _prefs.getInt('sleepHour') ?? s.sleepHour;
    s.sleepMinute = _prefs.getInt('sleepMinute') ?? s.sleepMinute;
    s.quietStartHour = _prefs.getInt('quietStartHour');
    s.quietStartMinute = _prefs.getInt('quietStartMinute');
    s.quietEndHour = _prefs.getInt('quietEndHour');
    s.quietEndMinute = _prefs.getInt('quietEndMinute');
    s.themeMode = _prefs.getString('themeMode') ?? s.themeMode;
    s.bottleTheme = _prefs.getString('bottleTheme') ?? s.bottleTheme;
    s.unit = _prefs.getString('unit') ?? s.unit;
    s.wallpaperEnabled =
        _prefs.getBool('wallpaperEnabled') ?? s.wallpaperEnabled;
    s.floatingBubbleEnabled =
        _prefs.getBool('floatingBubbleEnabled') ?? s.floatingBubbleEnabled;
    s.bubbleOpacity = _prefs.getDouble('bubbleOpacity') ?? s.bubbleOpacity;
    s.bubbleSize = _prefs.getString('bubbleSize') ?? s.bubbleSize;
    s.onboardingCompleted =
        _prefs.getBool('onboardingCompleted') ?? s.onboardingCompleted;
    s.soundEnabled = _prefs.getBool('soundEnabled') ?? s.soundEnabled;
    s.hapticEnabled = _prefs.getBool('hapticEnabled') ?? s.hapticEnabled;
    return s;
  }

  Future<void> saveSettings(UserSettings s) async {
    await _prefs.setInt('dailyTargetMl', s.dailyTargetMl);
    await _prefs.setInt('defaultGlassSizeMl', s.defaultGlassSizeMl);
    await _prefs.setString('gender', s.gender);
    await _prefs.setInt('weightKg', s.weightKg);
    await _prefs.setInt('ageYears', s.ageYears);
    await _prefs.setString('activityLevel', s.activityLevel);
    await _prefs.setBool('notificationsEnabled', s.notificationsEnabled);
    await _prefs.setInt(
        'reminderIntervalMinutes', s.reminderIntervalMinutes);
    await _prefs.setInt('wakeHour', s.wakeHour);
    await _prefs.setInt('wakeMinute', s.wakeMinute);
    await _prefs.setInt('sleepHour', s.sleepHour);
    await _prefs.setInt('sleepMinute', s.sleepMinute);
    if (s.quietStartHour != null)
      await _prefs.setInt('quietStartHour', s.quietStartHour!);
    if (s.quietStartMinute != null)
      await _prefs.setInt('quietStartMinute', s.quietStartMinute!);
    if (s.quietEndHour != null)
      await _prefs.setInt('quietEndHour', s.quietEndHour!);
    if (s.quietEndMinute != null)
      await _prefs.setInt('quietEndMinute', s.quietEndMinute!);
    await _prefs.setString('themeMode', s.themeMode);
    await _prefs.setString('bottleTheme', s.bottleTheme);
    await _prefs.setString('unit', s.unit);
    await _prefs.setBool('wallpaperEnabled', s.wallpaperEnabled);
    await _prefs.setBool('floatingBubbleEnabled', s.floatingBubbleEnabled);
    await _prefs.setDouble('bubbleOpacity', s.bubbleOpacity);
    await _prefs.setString('bubbleSize', s.bubbleSize);
    await _prefs.setBool('onboardingCompleted', s.onboardingCompleted);
    await _prefs.setBool('soundEnabled', s.soundEnabled);
    await _prefs.setBool('hapticEnabled', s.hapticEnabled);
    _settingsController.add(s);
  }

  Stream<UserSettings?> watchSettings() {
    return _settingsController.stream;
  }

  // ─────────────────────────────────────────────────────
  // GÜNLÜK KAYIT
  // ─────────────────────────────────────────────────────

  Future<DailyRecord> getTodayRecord() async {
    final today = DailyRecord.formatDate(DateTime.now());
    final rows = await _db.query(
      'daily_records',
      where: 'date_key = ?',
      whereArgs: [today],
    );

    DailyRecord record;
    if (rows.isNotEmpty) {
      record = DailyRecord.fromMap(rows.first);
    } else {
      final settings = await getSettings();
      record = DailyRecord.forToday(targetMl: settings.dailyTargetMl);
      await _db.insert('daily_records', record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    record.intakes = await _getTodayIntakes(today);
    return record;
  }

  Future<DailyRecord?> getRecordForDate(DateTime date) async {
    final key = DailyRecord.formatDate(date);
    final rows = await _db.query(
      'daily_records',
      where: 'date_key = ?',
      whereArgs: [key],
    );
    if (rows.isEmpty) return null;
    final record = DailyRecord.fromMap(rows.first);
    record.intakes = await _getIntakesForDate(key);
    return record;
  }

  Stream<DailyRecord?> watchTodayRecord() {
    // İlk değeri hemen yayınla
    getTodayRecord().then((r) => _todayController.add(r));
    return _todayController.stream;
  }

  Future<List<WaterIntake>> _getTodayIntakes(String dateKey) =>
      _getIntakesForDate(dateKey);

  Future<List<WaterIntake>> _getIntakesForDate(String dateKey) async {
    final date = _parseDateKey(dateKey);
    final start = date.millisecondsSinceEpoch;
    final end = date
        .add(const Duration(days: 1))
        .millisecondsSinceEpoch;

    final rows = await _db.query(
      'water_intakes',
      where: 'timestamp >= ? AND timestamp < ? AND deleted_at IS NULL',
      whereArgs: [start, end],
      orderBy: 'timestamp ASC',
    );
    return rows.map(WaterIntake.fromMap).toList();
  }

  DateTime _parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  // ─────────────────────────────────────────────────────
  // SU KAYDI EKLEME / SİLME
  // ─────────────────────────────────────────────────────

  Future<WaterIntake> addIntake({
    required int amountMl,
    String glassType = 'default',
    DateTime? timestamp,
  }) async {
    final intake = WaterIntake.create(
      amountMl: amountMl,
      glassType: glassType,
      timestamp: timestamp,
    );

    final id = await _db.insert('water_intakes', intake.toMap());
    final saved = WaterIntake(
      id: id,
      timestamp: intake.timestamp,
      amountMl: intake.amountMl,
      glassType: intake.glassType,
    );

    // Günlük tüketimi güncelle (tek seferlik — çift sayım olmasın)
    final today = DailyRecord.formatDate(DateTime.now());
    final existing = await _db.query('daily_records',
        where: 'date_key = ?', whereArgs: [today]);
    if (existing.isEmpty) {
      final settings = await getSettings();
      await _db.insert('daily_records', {
        'date_key': today,
        'consumed_ml': amountMl,
        'target_ml': settings.dailyTargetMl,
      });
    } else {
      await _db.execute(
          'UPDATE daily_records SET consumed_ml = consumed_ml + ? WHERE date_key = ?',
          [amountMl, today]);
    }

    final updated = await getTodayRecord();
    _todayController.add(updated);
    return saved;
  }

  Future<void> _ensureTodayRecord(String today, int addedMl) async {
    final rows = await _db.query('daily_records',
        where: 'date_key = ?', whereArgs: [today]);
    if (rows.isEmpty) {
      final settings = await getSettings();
      await _db.insert('daily_records', {
        'date_key': today,
        'consumed_ml': addedMl,
        'target_ml': settings.dailyTargetMl,
      });
    } else {
      await _db.execute(
          'UPDATE daily_records SET consumed_ml = consumed_ml + ? WHERE date_key = ?',
          [addedMl, today]);
    }
  }

  Future<void> deleteIntake(int intakeId) async {
    final rows = await _db.query('water_intakes',
        where: 'id = ?', whereArgs: [intakeId]);
    if (rows.isEmpty) return;

    final intake = WaterIntake.fromMap(rows.first);
    if (intake.isDeleted) return;

    await _db.update(
      'water_intakes',
      {'deleted_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [intakeId],
    );

    // Bugünkü kayıtsa miktarı düş
    final today = DailyRecord.formatDate(DateTime.now());
    final intakeDate = DailyRecord.formatDate(intake.timestamp);
    if (intakeDate == today) {
      await _db.execute(
          'UPDATE daily_records SET consumed_ml = MAX(0, consumed_ml - ?) WHERE date_key = ?',
          [intake.amountMl, today]);
    }

    final updated = await getTodayRecord();
    _todayController.add(updated);
  }

  // ─────────────────────────────────────────────────────
  // GEÇMİŞ & RAPORLAR
  // ─────────────────────────────────────────────────────

  Future<List<DailyRecord>> getLastNDays(int n) async {
    final now = DateTime.now();
    final records = <DailyRecord>[];
    for (int i = n - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final r = await getRecordForDate(date);
      if (r != null) records.add(r);
    }
    return records;
  }

  Future<List<DailyRecord>> getMonthRecords(int year, int month) async {
    final start = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-01';
    final endMonth = month == 12 ? 1 : month + 1;
    final endYear = month == 12 ? year + 1 : year;
    final end = '${endYear.toString().padLeft(4, '0')}-${endMonth.toString().padLeft(2, '0')}-01';

    final rows = await _db.query(
      'daily_records',
      where: 'date_key >= ? AND date_key < ?',
      whereArgs: [start, end],
      orderBy: 'date_key ASC',
    );

    final result = <DailyRecord>[];
    for (final row in rows) {
      final r = DailyRecord.fromMap(row);
      r.intakes = await _getIntakesForDate(r.dateKey);
      result.add(r);
    }
    return result;
  }

  Future<int> calculateStreak() async {
    int streak = 0;
    DateTime checkDate = DateTime.now();
    while (true) {
      final record = await getRecordForDate(checkDate);
      if (record == null || !record.goalReached) break;
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> resetAllData() async {
    await _db.delete('water_intakes');
    await _db.delete('daily_records');
    final fresh = await getTodayRecord();
    _todayController.add(fresh);
  }
}
