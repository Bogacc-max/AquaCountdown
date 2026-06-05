import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  // Zaman dilimi veritabanını başlat (bildirimler için)
  tz.initializeTimeZones();

  // intl Türkçe locale verilerini yükle (DateFormat için zorunlu)
  await initializeDateFormatting('tr_TR', null);
  await initializeDateFormatting('en_US', null);

  // Durum çubuğunu şeffaf yap
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
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
        final themeMode = switch (settings.themeMode) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };

        return MaterialApp(
          title: 'AquaCountdown',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          locale: const Locale('tr', 'TR'),
          supportedLocales: const [
            Locale('tr', 'TR'),
            Locale('en', 'US'),
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A1929),
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
                  color: Colors.white,
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
