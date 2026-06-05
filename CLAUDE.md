# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Run on a specific device
flutter devices          # list available
flutter run -d <device>

# Analyze (lint) — 0 errors expected
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Build release APK / AAB
flutter build apk --release
flutter build appbundle --release
```

**Requirements:** Flutter 3.22+, JDK 17, Android minSdk 26 (Oreo).

## Architecture

**Flutter (Dart)** — UI, state, persistence. **Kotlin** — Android-only native services.

### State Management: Riverpod

`water_provider.dart` is the central state hub. Key providers:

- `settingsProvider` (StateNotifier) — user settings from SharedPreferences
- `todayRecordProvider` (StateNotifier) — today's water data, reactive via StreamController
- `repositoryProvider` — async singleton for `WaterRepository`
- `streakProvider`, `weeklyRecordsProvider`, `monthlyRecordsProvider` — derived read-only data

All water mutations flow through `TodayRecordNotifier.addWater()` / `removeIntake()`, which also trigger: native sync, milestone notifications, streak notifications, and home widget updates.

### Data Layer

- **sqflite** (`aquacountdown.db`) — `water_intakes` and `daily_records` tables
- **SharedPreferences** — user settings (target, theme, notifications, bubble config)
- **WaterRepository** — singleton, exposes `StreamController`-based watch methods for reactive UI updates
- `.g.dart` files exist but are manually maintained stubs (no active build_runner codegen despite BUILD_GUIDE.md referencing it)

### Flutter ↔ Native Bridge

`NativeBridge` (static class) communicates via 3 MethodChannels + 1 EventChannel:

| Channel | Direction | Purpose |
|---------|-----------|---------|
| `aquacountdown/wallpaper` | Flutter → Native | Live wallpaper control |
| `aquacountdown/bubble` | Flutter → Native | Floating bubble service |
| `aquacountdown/water` | Bidirectional | Sync water data to native, read pending bubble intakes |
| `aquacountdown/events` | Native → Flutter | Real-time events (water_added from bubble/widget) |

Channel names must match between `NativeBridge` (Dart) and `MainActivity.kt` (Kotlin).

### Native Android Services (Kotlin)

All in `android/app/src/main/kotlin/com/aquacountdown/`:

- **FloatingBubbleService** — Foreground service, overlay window. Single tap = add default amount, long press = radial menu (100/200/330/500ml), double tap = open app. Stores pending intakes in SharedPreferences (`last_intake_amount` accumulates).
- **WaterWallpaperService** — Live wallpaper reading water data from SharedPreferences.
- **WaterWidgetProvider** — AppWidget, reads/writes SharedPreferences, sends `WATER_ADDED` broadcast.
- **BootReceiver** — Restarts bubble service on device boot if enabled.

**Shared state contract:** Native services and Flutter share data via SharedPreferences (`aquacountdown_prefs`). Keys like `remaining_ml`, `target_ml`, `last_intake_amount` are the integration surface. When the app is closed, native components write to SharedPreferences; on app open, `_flushPendingBubbleIntakes()` syncs them into sqflite.

### Theme System

`AquaColors` ThemeExtension provides theme-aware colors. Access via `context.aqua.textPrimary`, `context.aqua.scaffoldGradientStart`, etc. Both light and dark variants are defined. Screens should use `context.aqua.*` instead of hardcoded colors.

### Bottle Theme System

`BottleThemeData` in `lib/presentation/widgets/bottle_theme.dart` defines 4 bottle visual styles (Classic, Modern, Nature, Minimal). Each theme provides: `buildCupPath()` for shape, `colorForLevel()` for water colors, wave amplitude params. Selected via `UserSettings.bottleTheme` field. Accessed via `BottleThemeData.fromId(id)`.

### Achievement System

DB v2 adds `achievements` table. `AchievementService` in `lib/data/services/achievement_service.dart` checks 10 achievement conditions after every water add. Unlocked achievements broadcast via `TodayRecordNotifier.achievementUnlocks` stream. Home screen shows badge row and confetti on unlock.

### Ads (Google Mobile Ads)

`AdManager` singleton in `lib/core/services/ad_manager.dart`. Uses TEST ad IDs. Banner on Reports screen, interstitial every 5th water add (max 2/day). Replace test IDs with real AdMob IDs before production.

### Health Integration

`HealthService` singleton writes water intake to Google Fit / Apple Health via `health` package. Toggle in Settings. Requires runtime permission.

### Localization

Türkçe is the default locale. ARB files in `lib/l10n/`. Manual `AppLocalizations` delegate (not codegen). Supports tr_TR and en_US.

## Key Patterns

- **Countdown model:** The core UX shows "remaining" water (full glass draining down), not "consumed" (empty glass filling up). `BottleWidget.fillRatio` represents the remaining fraction, and labels say "kaldi" (remaining).
- **Notification scheduling:** `NotificationService.scheduleReminders()` must be called after any settings change and after onboarding. It creates time-based notifications between wake/sleep hours respecting quiet hours.
- **Home widget sync:** Call `HomeWidget.updateWidget(androidName: 'WaterWidgetProvider')` after any water data mutation.
- **Native event flow:** Bubble/widget → SharedPreferences + broadcast → MainActivity receiver → EventChannel → `TodayRecordNotifier._listenNativeEvents()`.
