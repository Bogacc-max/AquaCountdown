import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Uygulama lokalizasyon sınıfı
/// Türkçe (varsayılan) ve İngilizce destekler.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = locale;

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('tr', 'TR'),
    Locale('en', 'US'),
    Locale('de', 'DE'),
    Locale('es', 'ES'),
  ];

  // Soyut getter'lar — her dil için impl gerekli
  String get appTitle;
  String get remaining;
  String get goalCompleted;
  String get addWater;
  String streakDays(int days);
  String get settingsDailyGoal;
  String get settingsNotifications;
  String get settingsTheme;
  String get unitMl;
  String get unitOz;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['tr', 'en', 'de', 'es'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return switch (locale.languageCode) {
      'tr' => _AppLocalizationsTr(),
      'de' => _AppLocalizationsDe(),
      'es' => _AppLocalizationsEs(),
      _ => _AppLocalizationsEn(),
    };
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ─── Türkçe ──────────────────────────────────────────
class _AppLocalizationsTr extends AppLocalizations {
  _AppLocalizationsTr() : super('tr');

  @override String get appTitle => 'AquaCountdown';
  @override String get remaining => 'kaldı';
  @override String get goalCompleted => '🎉 Hedef tamamlandı!';
  @override String get addWater => 'Su Ekle';
  @override String streakDays(int days) => '$days gündür hedef tutturuyorsun! 🔥';
  @override String get settingsDailyGoal => 'Günlük Su Hedefi';
  @override String get settingsNotifications => 'Bildirimler';
  @override String get settingsTheme => 'Tema';
  @override String get unitMl => 'ml';
  @override String get unitOz => 'oz';
}

// ─── İngilizce ───────────────────────────────────────
class _AppLocalizationsEn extends AppLocalizations {
  _AppLocalizationsEn() : super('en');

  @override String get appTitle => 'AquaCountdown';
  @override String get remaining => 'remaining';
  @override String get goalCompleted => '🎉 Goal completed!';
  @override String get addWater => 'Add Water';
  @override String streakDays(int days) => '$days day streak! 🔥';
  @override String get settingsDailyGoal => 'Daily Water Goal';
  @override String get settingsNotifications => 'Notifications';
  @override String get settingsTheme => 'Theme';
  @override String get unitMl => 'ml';
  @override String get unitOz => 'oz';
}

// ─── Almanca ────────────────────────────────────────
class _AppLocalizationsDe extends AppLocalizations {
  _AppLocalizationsDe() : super('de');

  @override String get appTitle => 'AquaCountdown';
  @override String get remaining => 'verbleibend';
  @override String get goalCompleted => '🎉 Ziel erreicht!';
  @override String get addWater => 'Wasser hinzufügen';
  @override String streakDays(int days) => '$days Tage Serie! 🔥';
  @override String get settingsDailyGoal => 'Tägliches Wasserziel';
  @override String get settingsNotifications => 'Benachrichtigungen';
  @override String get settingsTheme => 'Design';
  @override String get unitMl => 'ml';
  @override String get unitOz => 'oz';
}

// ─── İspanyolca ─────────────────────────────────────
class _AppLocalizationsEs extends AppLocalizations {
  _AppLocalizationsEs() : super('es');

  @override String get appTitle => 'AquaCountdown';
  @override String get remaining => 'restante';
  @override String get goalCompleted => '🎉 ¡Meta completada!';
  @override String get addWater => 'Agregar agua';
  @override String streakDays(int days) => '¡$days días de racha! 🔥';
  @override String get settingsDailyGoal => 'Meta diaria de agua';
  @override String get settingsNotifications => 'Notificaciones';
  @override String get settingsTheme => 'Tema';
  @override String get unitMl => 'ml';
  @override String get unitOz => 'oz';
}
