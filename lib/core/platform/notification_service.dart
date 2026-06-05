import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/user_settings.dart';
import 'notification_messages.dart';

/// Bildirim Servisi
///
/// flutter_local_notifications kullanarak:
/// - Düzenli su hatırlatmaları (cron-based)
/// - Eşik tebrik bildirimleri
/// - Persistent durum bildirimi
class NotificationService {
  static NotificationService? _instance;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  NotificationService._();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  // Bildirim ID'leri
  static const int idPersistent = 1;
  static const int idReminder = 2;
  static const int idMilestone = 3;
  static const int idGoalComplete = 4;
  static const int idStreak = 5;

  // Kanal ID'leri
  static const String channelReminder = 'aquacountdown_reminder';
  static const String channelMilestone = 'aquacountdown_milestone';
  static const String channelPersistent = 'aquacountdown_persistent';

  /// Servisi başlat
  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@drawable/ic_water_drop');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannels();
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  Future<void> _createChannels() async {
    // Platforma özgü implementasyonu al (null olabilir — iOS veya sandbox ortamı)
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl == null) return;

    await androidImpl.createNotificationChannel(
      const AndroidNotificationChannel(
        channelReminder,
        'Hatırlatmalar',
        description: 'Su içme hatırlatmaları',
        importance: Importance.defaultImportance,
        // Ses dosyası (res/raw/water_drop.mp3) opsiyonel — yoksa sistem sesi
      ),
    );

    await androidImpl.createNotificationChannel(
      const AndroidNotificationChannel(
        channelMilestone,
        'Başarılar',
        description: 'Hedef ve seri bildirimleri',
        importance: Importance.high,
      ),
    );

    await androidImpl.createNotificationChannel(
      const AndroidNotificationChannel(
        channelPersistent,
        'Sürekli Bildirim',
        description: 'Su takibi aktif bilgisi',
        importance: Importance.low,
      ),
    );
  }

  static Function(int amountMl)? _onQuickAdd;

  static void setQuickAddHandler(Function(int) handler) {
    _onQuickAdd = handler;
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.actionId == 'quick_add_200') {
      _onQuickAdd?.call(200);
      return;
    }
  }

  // ─────────────────────────────────────────────────────
  // HATIRLATMA BİLDİRİMLERİ
  // ─────────────────────────────────────────────────────

  /// Ayarlara göre tüm hatırlatma bildirimlerini planla
  Future<void> scheduleReminders(UserSettings settings, {int streak = 0}) async {
    if (!settings.notificationsEnabled) {
      await cancelAllReminders();
      return;
    }

    await cancelAllReminders();

    final now = tz.TZDateTime.now(tz.local);
    final wakeHour = settings.wakeHour;
    final sleepHour = settings.sleepHour;
    final intervalMinutes = settings.reminderIntervalMinutes;

    // Gün içindeki her aralık için bildirim planla
    var currentHour = wakeHour;
    var currentMinute = 0;
    var notifId = 100; // Hatırlatmalar için ID aralığı: 100-200

    while (_timeToMinutes(currentHour, currentMinute) <
        _timeToMinutes(sleepHour, 0)) {
      // Sessiz saatler içindeyse bu aralığı atla
      if (_isQuietTime(currentHour, currentMinute, settings)) {
        final totalMinutes =
            _timeToMinutes(currentHour, currentMinute) + intervalMinutes;
        currentHour = totalMinutes ~/ 60;
        currentMinute = totalMinutes % 60;
        continue;
      }

      final scheduledDate = _nextOccurrence(
        now,
        hour: currentHour,
        minute: currentMinute,
      );

      final msg = NotificationMessages.getForTime(currentHour, streak: streak);

      await _plugin.zonedSchedule(
        notifId++,
        msg.title,
        msg.body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelReminder,
            'Hatırlatmalar',
            channelDescription: 'Düzenli su hatırlatmaları',
            icon: '@drawable/ic_water_drop',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            actions: const <AndroidNotificationAction>[
              AndroidNotificationAction(
                'quick_add_200',
                '💧 200ml İçtim',
                showsUserInterface: false,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Bir sonraki aralığa geç
      final totalMinutes =
          _timeToMinutes(currentHour, currentMinute) + intervalMinutes;
      currentHour = totalMinutes ~/ 60;
      currentMinute = totalMinutes % 60;

      if (notifId > 200) break; // Güvenlik sınırı
    }
  }

  Future<void> cancelAllReminders() async {
    for (int id = 100; id <= 200; id++) {
      await _plugin.cancel(id);
    }
  }

  // ─────────────────────────────────────────────────────
  // EŞİK BİLDİRİMLERİ
  // ─────────────────────────────────────────────────────

  /// Kalan miktara göre eşik bildirimi göster
  Future<void> showMilestoneIfNeeded({
    required int remainingMl,
    required int targetMl,
  }) async {
    final percent = (remainingMl / targetMl * 100).round();

    String? title;
    String? body;

    if (remainingMl == 0) {
      title = '🎉 Hedef Tamamlandı!';
      body = 'Bugünkü su hedefini tamamladın. Harika iş!';
    } else if (remainingMl <= 250 && percent <= 10) {
      title = '💛 Bir bardak daha!';
      body = 'Sadece $remainingMl ml kaldı. Neredeyse bitti!';
    } else if (remainingMl <= 500 && percent <= 20) {
      title = '🏁 Sona yakın!';
      body = '$remainingMl ml daha içersen hedefe ulaşırsın.';
    } else if (percent <= 50 && percent > 48) {
      title = '⚡ Yarısına geldin!';
      body = 'Günün yarısı geçti, gayet iyisin!';
    }

    if (title == null) return;

    await _plugin.show(
      idMilestone,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelMilestone,
          'Başarılar',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_water_drop',
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // STREAK BİLDİRİMİ
  // ─────────────────────────────────────────────────────

  Future<void> showStreakNotification(int streakDays) async {
    if (streakDays < 3) return;

    await _plugin.show(
      idStreak,
      '🔥 $streakDays Günlük Seri!',
      '$streakDays gündür hedefini tutturuyorsun. Bırakma!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          channelMilestone,
          'Başarılar',
          importance: Importance.defaultImportance,
          icon: '@drawable/ic_water_drop',
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // YARDIMCI
  // ─────────────────────────────────────────────────────

  int _timeToMinutes(int hour, int minute) => hour * 60 + minute;

  bool _isQuietTime(int hour, int minute, UserSettings settings) {
    final qs = settings.quietStartHour;
    final qsm = settings.quietStartMinute ?? 0;
    final qe = settings.quietEndHour;
    final qem = settings.quietEndMinute ?? 0;
    if (qs == null || qe == null) return false;

    final current = _timeToMinutes(hour, minute);
    final start = _timeToMinutes(qs, qsm);
    final end = _timeToMinutes(qe, qem);

    // Gece yarısını geçen aralık (örn. 23:00 - 07:00)
    if (start > end) return current >= start || current < end;
    return current >= start && current < end;
  }

  tz.TZDateTime _nextOccurrence(
    tz.TZDateTime now, {
    required int hour,
    required int minute,
  }) {
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
