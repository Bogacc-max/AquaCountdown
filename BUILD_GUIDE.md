# AquaCountdown — Build & Yayın Rehberi

## Ön Gereksinimler

| Araç | Versiyon | İndirme |
|------|----------|---------|
| Flutter SDK | 3.22+ | https://flutter.dev/docs/get-started/install |
| Android Studio | Electric Eel+ | https://developer.android.com/studio |
| Java (JDK) | 17 | Android Studio ile birlikte gelir |
| Git | herhangi | https://git-scm.com |

Flutter kurulumunu doğrula:
```bash
flutter doctor
# Tüm satırlar [✓] olmalı
```

---

## ADIM 1 — Bağımlılıkları Yükle

```bash
cd aquacountdown
flutter pub get
```

---

## ADIM 2 — Isar Kod Üretimi (build_runner)

Isar veritabanı modelleri `.g.dart` dosyalarına ihtiyaç duyar.
Bu dosyalar otomatik üretilir ve **her model değişikliğinde** tekrar çalıştırılmalıdır.

```bash
dart run build_runner build --delete-conflicting-outputs
```

Başarılı çıktı şöyle görünür:
```
[INFO] Generating build script...
[INFO] Building new asset graph...
[INFO] Running build...
[INFO] Succeeded after Xs with Y outputs
```

Üretilen dosyalar:
- `lib/data/models/water_intake.g.dart`
- `lib/data/models/daily_record.g.dart`
- `lib/data/models/user_settings.g.dart`

> Bu dosyaları `.gitignore`'a ekleme — projeye dahil et.

---

## ADIM 3 — Emülatörde Test

```bash
# Bağlı cihaz / emülatörleri listele
flutter devices

# Debug modda çalıştır
flutter run

# Belirli cihazda
flutter run -d emulator-5554
```

---

## ADIM 4 — Keystore Oluşturma (Tek Seferlik)

**ÖNEMLİ:** Keystore dosyasını ve şifrelerini kaybedersen Play Store'a
bir daha güncelleme gönderemezsin. Güvenli bir yerde yedekle (USB, Google Drive vb.).

```bash
keytool -genkey -v \
  -keystore ~/aquacountdown-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias aquacountdown
```

Sorulan bilgileri doldur (ad, şehir, ülke vb.).

### key.properties Dosyasını Oluştur

`android/key.properties` dosyasını oluştur (bu dosyayı Git'e **ekleme**):

```properties
storePassword=<keystore_sifresi>
keyPassword=<key_sifresi>
keyAlias=aquacountdown
storeFile=/Users/<kullanici_adin>/aquacountdown-release.jks
```

`.gitignore` dosyana şunları ekle:
```
android/key.properties
*.jks
```

---

## ADIM 5 — Uygulama İkonu Launcher'a Ekleme

`pubspec.yaml` dosyasına `dev_dependencies` altına ekle:
```yaml
  flutter_launcher_icons: ^0.14.1
```

`pubspec.yaml` en altına ekle:
```yaml
flutter_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  min_sdk_android: 21
  adaptive_icon_background: "#0A1929"
  adaptive_icon_foreground: "assets/icons/app_icon.png"
```

Çalıştır:
```bash
flutter pub get
dart run flutter_launcher_icons
```

---

## ADIM 6 — Release APK / AAB Oluştur

### APK (test ve doğrudan kurulum için)
```bash
flutter build apk --release
# Çıktı: build/app/outputs/flutter-apk/app-release.apk
```

### AAB (Google Play Store için — zorunlu)
```bash
flutter build appbundle --release
# Çıktı: build/app/outputs/bundle/release/app-release.aab
```

---

## ADIM 7 — Google Play Console

1. https://play.google.com/console adresine git
2. **Uygulama oluştur** → AquaCountdown → Türkçe → Uygulama
3. **Üretim → Sürümler** → `.aab` dosyasını yükle
4. Store listing'i doldur:
   - Kısa açıklama (80 karakter)
   - Tam açıklama
   - Ekran görüntüleri (en az 2 adet)
   - Uygulama ikonu: `assets/icons/app_icon.png` (1024×1024)
5. **İçerik derecelendirmesi** → anketi doldur
6. **İncelemeye gönder**

---

## Sık Karşılaşılan Sorunlar

| Sorun | Çözüm |
|-------|-------|
| `MissingPluginException` | `flutter clean && flutter pub get` |
| Isar `.g.dart` bulunamadı | `dart run build_runner build --delete-conflicting-outputs` |
| Keystore bulunamadı | `android/key.properties` yolunu kontrol et |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | `flutter clean` + cihazdan eski APK'yı sil |
| Overlay izni çalışmıyor | Ayarlar → Uygulamalar → AquaCountdown → Diğer uygulamaların üzerinde görün |
| Bildirimler gelmiyor | Ayarlar → Bildirimler → AquaCountdown → İzin Ver |

---

## Dosya Yapısı

```
aquacountdown/
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── platform/native_bridge.dart
│   │   ├── platform/notification_service.dart
│   │   └── themes/app_theme.dart
│   ├── data/
│   │   ├── models/          (+ *.g.dart — build_runner üretir)
│   │   └── repositories/water_repository.dart
│   ├── presentation/
│   │   ├── providers/water_provider.dart
│   │   ├── screens/home / onboarding / reports / settings
│   │   └── widgets/bottle_widget.dart
│   └── l10n/app_localizations.dart
├── android/
│   ├── app/src/main/kotlin/com/aquacountdown/
│   │   ├── MainActivity.kt
│   │   ├── WaterWallpaperService.kt
│   │   ├── FloatingBubbleService.kt
│   │   ├── BootReceiver.kt
│   │   └── WaterWidgetProvider.kt
│   └── app/src/main/res/
├── ios/Runner/Info.plist
└── assets/
    ├── icons/app_icon.png
    └── sounds/water_drop.wav
```
