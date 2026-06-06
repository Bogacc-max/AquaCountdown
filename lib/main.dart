import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'core/platform/native_bridge.dart';
import 'core/platform/notification_service.dart';
import 'core/services/ad_manager.dart';
import 'core/themes/app_theme.dart';
import 'data/repositories/water_repository.dart';
import 'presentation/providers/water_provider.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Zaman dilimi veritabanını başlat (bildirimler için)
  tz.initializeTimeZones();

  // intl Türkçe locale verilerini yükle (DateFormat için zorunlu)
  await initializeDateFormatting('tr_TR', null);
  await initializeDateFormatting('en_US', null);
  await initializeDateFormatting('de_DE', null);
  await initializeDateFormatting('es_ES', null);

  // Durum çubuğunu şeffaf yap (tema'ya göre initState'te güncellenir)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Yalnızca dikey yön
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Native event kanalını başlat
  NativeBridge.initEventChannel();

  // Veritabanını ön yükle
  await WaterRepository.getInstance();

  // Bildirim servisini başlat
  await NotificationService.instance.initialize();

  // Reklam servisini başlat
  await AdManager.instance.initialize();

  // Bildirim action butonundan su ekleme
  NotificationService.setQuickAddHandler((amountMl) async {
    if (amountMl <= 0 || amountMl > 2000) return;
    final repo = await WaterRepository.getInstance();
    await repo.addIntake(amountMl: amountMl, glassType: 'notification');
  });

  runApp(
    const ProviderScope(
      child: AquaCountdownApp(),
    ),
  );
}

class AquaCountdownApp extends ConsumerWidget {
  const AquaCountdownApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const _SplashScreen(),
      error: (_, __) => const _SplashScreen(),
      data: (settings) {
        FlutterNativeSplash.remove();
        final themeMode = switch (settings.themeMode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };

        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
        ));

        return MaterialApp(
          title: 'AquaCountdown',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: Locale(settings.language, ''),
          supportedLocales: const [
            Locale('tr', 'TR'),
            Locale('en', 'US'),
            Locale('de', 'DE'),
            Locale('es', 'ES'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: settings.onboardingCompleted
              ? const HomeScreen()
              : const OnboardingScreen(),
        );
      },
    );
  }
}

/// Uygulama yüklenirken gösterilen başlangıç ekranı
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A1929) : const Color(0xFFF5FBFC);
    final textColor = isDark ? Colors.white : const Color(0xDE000000);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.water_drop,
                color: Color(0xFF00BCD4),
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                'AquaCountdown',
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: Color(0xFF00BCD4),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
