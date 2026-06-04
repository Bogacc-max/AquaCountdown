import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/platform/native_bridge.dart';
import '../../../data/models/user_settings.dart';
import '../../../data/repositories/water_repository.dart';
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
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A1929),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00BCD4))),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: const Color(0xFF0A1929),
        body: Center(child: Text('$e', style: const TextStyle(color: Colors.red))),
      ),
      data: (settings) => _buildBody(settings),
    );
  }

  Widget _buildBody(UserSettings settings) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1929),
        elevation: 0,
        title: const Text(
          'Ayarlar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
            title: 'Tema',
            subtitle: _themeLabel(settings.themeMode),
            onTap: () => _showThemePicker(settings),
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

          // ─── VERİ ────────────────────────────────────
          _SectionHeader('📁 Veri'),
          _SettingsTile(
            title: 'Tüm Verileri Sıfırla',
            onTap: () => _confirmReset(context),
            trailing: const Icon(
                Icons.delete_outline, color: Colors.redAccent, size: 20),
            titleColor: Colors.redAccent,
          ),

          // ─── HAKKINDA ────────────────────────────────
          _SectionHeader('ℹ️ Hakkında'),
          _SettingsTile(
            title: 'Versiyon',
            subtitle: _appVersion,
          ),
          _SettingsTile(
            title: 'Gizlilik Politikası',
            onTap: () => _showPrivacyPolicy(context),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D2137),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          ...List.generate(options.length, (i) => ListTile(
                title: Text(options[i],
                    style: const TextStyle(color: Colors.white)),
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

  void _showPrivacyPolicy(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0D2137),
        title: const Text(
          'Gizlilik Politikası',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            'AquaCountdown Gizlilik Politikası\n\n'
            'Son güncelleme: Mayıs 2025\n\n'
            '1. Toplanan Veriler\n'
            'Uygulama, su içme kayıtlarınızı ve ayarlarınızı yalnızca cihazınızda yerel olarak saklar. '
            'Hiçbir kişisel veri dış sunuculara gönderilmez.\n\n'
            '2. Veri Kullanımı\n'
            'Saklanan veriler; günlük ilerlemenizi göstermek, hatırlatma bildirimleri planlamak '
            've kişisel su hedefinizi hesaplamak için kullanılır.\n\n'
            '3. Üçüncü Taraf Paylaşımı\n'
            'Verileriniz üçüncü taraflarla paylaşılmaz, satılmaz veya kiralanmaz.\n\n'
            '4. İzinler\n'
            'Bildirim izni: Hatırlatmalar için.\n'
            'Overlay izni: Yüzen buton için.\n'
            'Bu izinler isteğe bağlıdır ve uygulama ayarlarından kaldırılabilir.\n\n'
            '5. İletişim\n'
            'Sorularınız için: celikbogac@gmail.com',
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam', style: TextStyle(color: Color(0xFF00BCD4))),
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
          color: Colors.white.withOpacity(0.5),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: TextStyle(
            color: titleColor ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 12,
                ),
              )
            : null,
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right,
                    color: Colors.white.withOpacity(0.3), size: 18)
                : null),
      ),
    );
  }
}
