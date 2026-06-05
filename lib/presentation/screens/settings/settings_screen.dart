import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/platform/native_bridge.dart';
import '../../../core/services/health_service.dart';
import '../../../core/themes/app_theme.dart';
import '../../../data/models/achievement.dart';
import '../../../data/models/user_settings.dart';
import '../../../data/repositories/water_repository.dart';
import '../../widgets/bottle_theme.dart';
import '../../widgets/bottle_widget.dart';
import '../../providers/water_provider.dart';

/// Ayarlar Ekranı
/// Hedef, bildirim, görünüm, native özellikler, veri yönetimi
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _appVersion = '${info.version}+${info.buildNumber}');
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => Scaffold(
        backgroundColor: context.aqua.scaffoldGradientStart,
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4))),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: context.aqua.scaffoldGradientStart,
        body: Center(child: Text('$e', style: const TextStyle(color: Colors.red))),
      ),
      data: (settings) => _buildBody(settings),
    );
  }

  Widget _buildBody(UserSettings settings) {
    final aqua = context.aqua;
    return Scaffold(
      backgroundColor: aqua.scaffoldGradientStart,
      appBar: AppBar(
        backgroundColor: aqua.scaffoldGradientStart,
        elevation: 0,
        title: Text(
          'Ayarlar',
          style: TextStyle(color: aqua.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── PROFİL ───────────────────────────────
          _SectionHeader('👤 Profil'),
          _SettingsTile(
            title: 'Cinsiyet',
            subtitle: _genderLabel(settings.gender),
            onTap: () => _showGenderPicker(settings),
          ),
          _SettingsTile(
            title: 'Kilo',
            subtitle: '${settings.weightKg} kg',
            onTap: () => _showWeightPicker(settings),
          ),
          _SettingsTile(
            title: 'Yaş',
            subtitle: '${settings.ageYears}',
            onTap: () => _showAgePicker(settings),
          ),
          _SettingsTile(
            title: 'Aktivite Seviyesi',
            subtitle: _activityLabel(settings.activityLevel),
            onTap: () => _showActivityPicker(settings),
          ),
          _SettingsTile(
            title: 'Hedefi Yeniden Hesapla',
            subtitle: 'Profil bilgilerine göre önerilen hedefi uygula',
            onTap: () {
              final newTarget = UserSettings.calculateTarget(
                weightKg: settings.weightKg,
                activityLevel: settings.activityLevel,
                gender: settings.gender,
              );
              _saveSettings(settings.copy()..dailyTargetMl = newTarget);
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(SnackBar(
                  content: Text('Hedef ${(newTarget / 1000).toStringAsFixed(1)} L olarak güncellendi'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF00BCD4),
                ));
            },
            trailing: const Icon(Icons.refresh, color: Color(0xFF00BCD4), size: 20),
          ),

          // ─── HEDEFLER ───────────────────────────────
          _SectionHeader('🎯 Hedefler'),
          _SettingsTile(
            title: 'Günlük Su Hedefi',
            subtitle: settings.dailyTargetMl >= 1000
                ? '${(settings.dailyTargetMl / 1000).toStringAsFixed(1)} L'
                : '${settings.dailyTargetMl} ml',
            trailing: SizedBox(
              width: 180,
              child: Slider(
                value: settings.dailyTargetMl.toDouble(),
                min: 1000,
                max: 6000,
                divisions: 50,
                activeColor: const Color(0xFF00BCD4),
                inactiveColor: Colors.white12,
                onChanged: (v) {
                  _saveSettings(settings.copy()..dailyTargetMl = v.round());
                },
              ),
            ),
          ),
          _SettingsTile(
            title: 'Varsayılan Bardak',
            subtitle: '${settings.defaultGlassSizeMl} ml',
            onTap: () => _showGlassSizePicker(settings),
          ),

          // ─── BİLDİRİMLER ────────────────────────────
          _SectionHeader('🔔 Bildirimler'),
          _SettingsTile(
            title: 'Bildirimler',
            trailing: Switch(
              value: settings.notificationsEnabled,
              onChanged: (v) {
                _saveSettings(settings.copy()..notificationsEnabled = v);
              },
              activeColor: const Color(0xFF00BCD4),
            ),
          ),
          if (settings.notificationsEnabled) ...[
            _SettingsTile(
              title: 'Hatırlatma Aralığı',
              subtitle: _intervalLabel(settings.reminderIntervalMinutes),
              onTap: () => _showIntervalPicker(settings),
            ),
            _SettingsTile(
              title: 'Uyanış Saati',
              subtitle: TimeOfDay(
                      hour: settings.wakeHour, minute: settings.wakeMinute)
                  .format(context),
              onTap: () async {
                final t = await showTimePicker(
                    context: context,
                    initialTime: settings.wakeTime);
                if (t != null) {
                  _saveSettings(settings.copy()
                    ..wakeHour = t.hour
                    ..wakeMinute = t.minute);
                }
              },
            ),
            _SettingsTile(
              title: 'Uyku Saati',
              subtitle: TimeOfDay(
                      hour: settings.sleepHour, minute: settings.sleepMinute)
                  .format(context),
              onTap: () async {
                final t = await showTimePicker(
                    context: context,
                    initialTime: settings.sleepTime);
                if (t != null) {
                  _saveSettings(settings.copy()
                    ..sleepHour = t.hour
                    ..sleepMinute = t.minute);
                }
              },
            ),
          ],

          // ─── GÖRÜNÜM ────────────────────────────────
          _SectionHeader('🎨 Görünüm'),
          _SettingsTile(
            title: 'Bardak Stili',
            subtitle: BottleThemeData.fromId(settings.bottleTheme).displayName,
            onTap: () => _showBottleThemePicker(settings),
          ),
          _SettingsTile(
            title: 'Tema',
            subtitle: _themeLabel(settings.themeMode),
            onTap: () => _showThemePicker(settings),
          ),
          _SettingsTile(
            title: 'Dil / Language',
            subtitle: _languageLabel(settings.language),
            onTap: () => _showLanguagePicker(settings),
          ),
          _SettingsTile(
            title: 'Birim',
            trailing: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ml', label: Text('ml')),
                ButtonSegment(value: 'oz', label: Text('oz')),
              ],
              selected: {settings.unit},
              onSelectionChanged: (s) {
                _saveSettings(settings.copy()..unit = s.first);
              },
              style: const ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.transparent),
              ),
            ),
          ),
          _SettingsTile(
            title: 'Ses Efektleri',
            trailing: Switch(
              value: settings.soundEnabled,
              onChanged: (v) => _saveSettings(settings.copy()..soundEnabled = v),
              activeColor: const Color(0xFF00BCD4),
            ),
          ),
          _SettingsTile(
            title: 'Titreşim',
            trailing: Switch(
              value: settings.hapticEnabled,
              onChanged: (v) => _saveSettings(settings.copy()..hapticEnabled = v),
              activeColor: const Color(0xFF00BCD4),
            ),
          ),

          // ─── YÜZEN BUTON ────────────────────────────
          _SectionHeader('💧 Yüzen Buton'),
          _SettingsTile(
            title: 'Yüzen Buton',
            trailing: Switch(
              value: settings.floatingBubbleEnabled,
              onChanged: (v) async {
                if (v) {
                  final hasPermission = await NativeBridge.hasOverlayPermission();
                  if (!hasPermission) {
                    await NativeBridge.requestOverlayPermission();
                    return;
                  }
                  await NativeBridge.startBubble();
                } else {
                  await NativeBridge.stopBubble();
                }
                _saveSettings(settings.copy()..floatingBubbleEnabled = v);
              },
              activeColor: const Color(0xFF00BCD4),
            ),
          ),
          if (settings.floatingBubbleEnabled) ...[
            _SettingsTile(
              title: 'Buton Boyutu',
              subtitle: settings.bubbleSize,
              onTap: () => _showBubbleSizePicker(settings),
            ),
            _SettingsTile(
              title: 'Opaklık',
              subtitle: '${(settings.bubbleOpacity * 100).round()}%',
              trailing: SizedBox(
                width: 150,
                child: Slider(
                  value: settings.bubbleOpacity,
                  min: 0.5,
                  max: 1.0,
                  activeColor: const Color(0xFF00BCD4),
                  inactiveColor: Colors.white12,
                  onChanged: (v) => _saveSettings(settings.copy()..bubbleOpacity = v),
                ),
              ),
            ),
          ],

          // ─── CANLI DUVAR KAĞIDI ──────────────────────
          _SectionHeader('🖼️ Canlı Duvar Kağıdı'),
          _SettingsTile(
            title: 'Canlı Duvar Kağıdını Ayarla',
            subtitle: 'Ekrana bardak görseli ekler',
            onTap: () => NativeBridge.openWallpaperPicker(),
            trailing: const Icon(
              Icons.open_in_new,
              color: Color(0xFF00BCD4),
              size: 18,
            ),
          ),

          // ─── SAĞLIK ───────────────────────────────────
          _SectionHeader('❤️ Sağlık'),
          _SettingsTile(
            title: 'Google Fit / Apple Health',
            subtitle: 'Su kayıtlarını sağlık uygulamasına yaz',
            trailing: Switch(
              value: settings.healthSyncEnabled,
              onChanged: (v) async {
                if (v) {
                  final granted = await HealthService.instance.requestPermission();
                  if (!granted) return;
                }
                _saveSettings(settings.copy()..healthSyncEnabled = v);
              },
              activeColor: const Color(0xFF00BCD4),
            ),
          ),

          // ─── VERİ ────────────────────────────────────
          _SectionHeader('📁 Veri'),
          _SettingsTile(
            title: 'Verileri Dışa Aktar (CSV)',
            onTap: () => _exportData(),
            trailing: const Icon(
                Icons.download_outlined, color: Color(0xFF00BCD4), size: 20),
          ),
          _SettingsTile(
            title: 'Tüm Verileri Sıfırla',
            onTap: () => _confirmReset(context),
            trailing: const Icon(
                Icons.delete_outline, color: Colors.redAccent, size: 20),
            titleColor: Colors.redAccent,
          ),

          // ─── HAKKINDA ────────────────────────────────
          // ─── BAŞARIMLAR ──────────────────────────────
          _SectionHeader('🏆 Başarımlar'),
          Consumer(
            builder: (ctx, ref, _) {
              final achievementsAsync = ref.watch(achievementsProvider);
              return achievementsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (list) {
                  final unlocked = list.where((a) => a.isUnlocked).length;
                  return _SettingsTile(
                    title: 'Tüm Başarımlar',
                    subtitle: '$unlocked/${list.length} kazanıldı',
                    onTap: () => _showAchievementsSheet(list),
                    trailing: const Icon(Icons.emoji_events,
                        color: Color(0xFFFFD54F), size: 20),
                  );
                },
              );
            },
          ),

          _SectionHeader('ℹ️ Hakkında'),
          _SettingsTile(
            title: 'Versiyon',
            subtitle: _appVersion,
          ),
          _SettingsTile(
            title: 'Gizlilik Politikası & KVKK',
            onTap: () => _launchUrl(
                'https://celikbogac.github.io/AquaCountdown/privacy.html'),
            trailing: const Icon(
                Icons.privacy_tip_outlined, color: Colors.white38, size: 16),
          ),
          _SettingsTile(
            title: 'Geri Bildirim Gönder',
            onTap: () => _launchUrl('mailto:celikbogac@gmail.com'
                '?subject=AquaCountdown%20Geri%20Bildirim'),
            trailing: const Icon(
                Icons.mail_outline, color: Color(0xFF00BCD4), size: 18),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _saveSettings(UserSettings settings) {
    ref.read(settingsProvider.notifier).save(settings);
  }

  void _showGlassSizePicker(UserSettings settings) {
    final sizes = [100, 150, 200, 250, 330, 500, 750];
    _showOptionSheet(
      context: context,
      title: 'Bardak Boyutu',
      options: sizes.map((ml) => '$ml ml').toList(),
      selectedIndex: sizes.indexOf(settings.defaultGlassSizeMl),
      onSelect: (i) =>
          _saveSettings(settings.copy()..defaultGlassSizeMl = sizes[i]),
    );
  }

  void _showIntervalPicker(UserSettings settings) {
    final intervals = [30, 60, 90, 120, 180];
    _showOptionSheet(
      context: context,
      title: 'Hatırlatma Aralığı',
      options: intervals.map(_intervalLabel).toList(),
      selectedIndex: intervals.indexOf(settings.reminderIntervalMinutes),
      onSelect: (i) => _saveSettings(
          settings.copy()..reminderIntervalMinutes = intervals[i]),
    );
  }

  void _showThemePicker(UserSettings settings) {
    _showOptionSheet(
      context: context,
      title: 'Tema',
      options: ['Açık', 'Koyu', 'Sistem'],
      selectedIndex: ['light', 'dark', 'system'].indexOf(settings.themeMode),
      onSelect: (i) => _saveSettings(
          settings.copy()..themeMode = ['light', 'dark', 'system'][i]),
    );
  }

  void _showBubbleSizePicker(UserSettings settings) {
    _showOptionSheet(
      context: context,
      title: 'Buton Boyutu',
      options: ['S (küçük)', 'M (orta)', 'L (büyük)'],
      selectedIndex: ['S', 'M', 'L'].indexOf(settings.bubbleSize),
      onSelect: (i) =>
          _saveSettings(settings.copy()..bubbleSize = ['S', 'M', 'L'][i]),
    );
  }

  void _showOptionSheet({
    required BuildContext context,
    required String title,
    required List<String> options,
    required int selectedIndex,
    required ValueChanged<int> onSelect,
  }) {
    final aqua = context.aqua;
    showModalBottomSheet(
      context: context,
      backgroundColor: aqua.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                color: aqua.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(color: aqua.cardBorder, height: 1),
          ...List.generate(options.length, (i) => ListTile(
                title: Text(options[i],
                    style: TextStyle(color: aqua.textPrimary)),
                trailing: i == selectedIndex
                    ? const Icon(Icons.check, color: Color(0xFF00BCD4))
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onSelect(i);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showAchievementsSheet(List<Achievement> achievements) {
    final aqua = context.aqua;
    showModalBottomSheet(
      context: context,
      backgroundColor: aqua.sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Başarımlar',
                  style: TextStyle(
                      color: aqua.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            Divider(color: aqua.cardBorder, height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: achievements.length,
                itemBuilder: (_, i) {
                  final a = achievements[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: aqua.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: a.isUnlocked
                            ? const Color(0xFFFFD54F).withOpacity(0.4)
                            : aqua.cardBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(a.icon,
                            style: TextStyle(
                                fontSize: 28,
                                color: a.isUnlocked
                                    ? null
                                    : Colors.grey)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: TextStyle(
                                  color: a.isUnlocked
                                      ? aqua.textPrimary
                                      : aqua.textHint,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                a.description,
                                style: TextStyle(
                                  color: aqua.textHint,
                                  fontSize: 12,
                                ),
                              ),
                              if (!a.isUnlocked && a.target > 1) ...[
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: a.progressRatio,
                                    backgroundColor: aqua.cardBorder,
                                    valueColor:
                                        const AlwaysStoppedAnimation(
                                            Color(0xFF00BCD4)),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (a.isUnlocked)
                          const Icon(Icons.check_circle,
                              color: Color(0xFFFFD54F), size: 22),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final repo = await WaterRepository.getInstance();
      final csv = await repo.exportToCsv();
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV verileri panoya kopyalandı'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dışa aktarma başarısız: $e')),
        );
      }
    }
  }

  void _confirmReset(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2137),
        title: const Text('Verileri Sıfırla',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tüm su kayıtları silinecek. Bu işlem geri alınamaz.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = await WaterRepository.getInstance();
              await repo.resetAllData();
              ref.invalidate(todayRecordProvider);
              ref.invalidate(todayIntakesProvider);
              ref.invalidate(weeklyRecordsProvider);
              ref.invalidate(streakProvider);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veriler sıfırlandı')),
                );
              }
            },
            child: const Text('Sıfırla',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String _intervalLabel(int minutes) {
    if (minutes < 60) return '$minutes dakika';
    return '${minutes ~/ 60} saat';
  }

  String _themeLabel(String mode) => switch (mode) {
        'light' => 'Açık',
        'dark' => 'Koyu',
        _ => 'Sistem',
      };

  String _genderLabel(String gender) => switch (gender) {
        'male' => 'Erkek',
        'female' => 'Kadın',
        _ => 'Diğer',
      };

  String _activityLabel(String level) => switch (level) {
        'low' => 'Sedanter',
        'medium' => 'Orta',
        'high' => 'Aktif',
        'athlete' => 'Sporcu',
        _ => 'Orta',
      };

  String _languageLabel(String lang) => switch (lang) {
        'en' => 'English',
        'de' => 'Deutsch',
        'es' => 'Español',
        _ => 'Türkçe',
      };

  void _showLanguagePicker(UserSettings settings) {
    _showOptionSheet(
      context: context,
      title: 'Dil / Language',
      options: ['Türkçe', 'English', 'Deutsch', 'Español'],
      selectedIndex: ['tr', 'en', 'de', 'es'].indexOf(settings.language),
      onSelect: (i) =>
          _saveSettings(settings.copy()..language = ['tr', 'en', 'de', 'es'][i]),
    );
  }

  void _showGenderPicker(UserSettings settings) {
    _showOptionSheet(
      context: context,
      title: 'Cinsiyet',
      options: ['Erkek', 'Kadın', 'Diğer'],
      selectedIndex: ['male', 'female', 'other'].indexOf(settings.gender),
      onSelect: (i) =>
          _saveSettings(settings.copy()..gender = ['male', 'female', 'other'][i]),
    );
  }

  void _showWeightPicker(UserSettings settings) {
    int weight = settings.weightKg;
    final aqua = context.aqua;
    showModalBottomSheet(
      context: context,
      backgroundColor: aqua.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Kilo: $weight kg',
                  style: TextStyle(color: aqua.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              Slider(
                value: weight.toDouble(),
                min: 40,
                max: 150,
                divisions: 110,
                activeColor: const Color(0xFF00BCD4),
                onChanged: (v) => setModal(() => weight = v.round()),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _saveSettings(settings.copy()..weightKg = weight);
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAgePicker(UserSettings settings) {
    int age = settings.ageYears;
    final aqua = context.aqua;
    showModalBottomSheet(
      context: context,
      backgroundColor: aqua.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Yaş: $age',
                  style: TextStyle(color: aqua.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              Slider(
                value: age.toDouble(),
                min: 10,
                max: 90,
                divisions: 80,
                activeColor: const Color(0xFF00BCD4),
                onChanged: (v) => setModal(() => age = v.round()),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _saveSettings(settings.copy()..ageYears = age);
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBottleThemePicker(UserSettings settings) {
    final themes = BottleThemeData.all;
    final aqua = context.aqua;
    showModalBottomSheet(
      context: context,
      backgroundColor: aqua.sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bardak Stili',
                style: TextStyle(
                    color: aqua.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: themes.map((theme) {
                final selected = settings.bottleTheme == theme.id;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _saveSettings(settings.copy()..bottleTheme = theme.id);
                  },
                  child: Container(
                    width: 72,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF00BCD4)
                            : aqua.cardBorder,
                        width: selected ? 2.5 : 1,
                      ),
                      color: aqua.cardBg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 48,
                          height: 64,
                          child: CustomPaint(
                            painter: _ThemePreviewPainter(theme),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          theme.displayName,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF00BCD4)
                                : aqua.textSecondary,
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showActivityPicker(UserSettings settings) {
    _showOptionSheet(
      context: context,
      title: 'Aktivite Seviyesi',
      options: ['Sedanter', 'Orta', 'Aktif', 'Sporcu'],
      selectedIndex: ['low', 'medium', 'high', 'athlete'].indexOf(settings.activityLevel),
      onSelect: (i) => _saveSettings(
          settings.copy()..activityLevel = ['low', 'medium', 'high', 'athlete'][i]),
    );
  }
}

// ─────────────────────────────────────────────────────
// YARDIMCI WİDGETLER
// ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: context.aqua.textHint,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final aqua = context.aqua;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: aqua.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: aqua.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? aqua.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: aqua.textHint,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right,
                    color: aqua.textHint, size: 18)
                : null),
      ),
    );
  }
}

class _ThemePreviewPainter extends CustomPainter {
  final BottleThemeData theme;
  const _ThemePreviewPainter(this.theme);

  @override
  void paint(Canvas canvas, Size size) {
    final path = theme.buildCupPath(0, 0, size.width, size.height);

    canvas.drawPath(
      path,
      Paint()..color = const Color(0x20006064),
    );

    canvas.save();
    canvas.clipPath(path);
    final waterTop = size.height * 0.4;
    canvas.drawRect(
      Rect.fromLTRB(0, waterTop, size.width, size.height),
      Paint()..color = theme.colorForLevel(1500),
    );
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0x60FFFFFF),
    );
  }

  @override
  bool shouldRepaint(_ThemePreviewPainter old) => old.theme.id != theme.id;
}
