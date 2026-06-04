import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/native_bridge.dart';
import '../../../data/models/user_settings.dart';
import '../../providers/water_provider.dart';
import '../home/home_screen.dart';

/// AquaCountdown Onboarding Akışı
///
/// 6 adım:
/// 1. Hoşgeldin + konsept tanıtımı
/// 2. Kişisel bilgiler (cinsiyet, kilo, yaş, aktivite)
/// 3. Hedef hesabı + düzenleme
/// 4. Bardak boyutu + saatler
/// 5. İzin istekleri (sıralı)
/// 6. Hazır!
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

  // Kullanıcı verileri
  String _gender = 'other';
  int _weightKg = 70;
  int _ageYears = 28;
  String _activityLevel = 'medium';
  int _calculatedTarget = 2500;
  int _finalTarget = 2500;
  int _defaultGlassSize = 200;
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 23, minute: 0);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  void _recalculateTarget() {
    _calculatedTarget = UserSettings.calculateTarget(
      weightKg: _weightKg,
      activityLevel: _activityLevel,
      gender: _gender,
    );
    _finalTarget = _calculatedTarget;
  }

  Future<void> _completeOnboarding() async {
    final settings = UserSettings.defaults()
      ..gender = _gender
      ..weightKg = _weightKg
      ..ageYears = _ageYears
      ..activityLevel = _activityLevel
      ..dailyTargetMl = _finalTarget
      ..defaultGlassSizeMl = _defaultGlassSize
      ..wakeHour = _wakeTime.hour
      ..wakeMinute = _wakeTime.minute
      ..sleepHour = _sleepTime.hour
      ..sleepMinute = _sleepTime.minute
      ..onboardingCompleted = true;

    await ref.read(settingsProvider.notifier).save(settings);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1929),
      body: SafeArea(
        child: Column(
          children: [
            // İlerleme göstergesi
            _buildProgressIndicator(),

            // Sayfa içeriği
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _ProfilePage(
                    gender: _gender,
                    weight: _weightKg,
                    age: _ageYears,
                    activity: _activityLevel,
                    onChanged: (g, w, a, act) {
                      setState(() {
                        _gender = g;
                        _weightKg = w;
                        _ageYears = a;
                        _activityLevel = act;
                        _recalculateTarget();
                      });
                    },
                    onNext: _nextPage,
                  ),
                  _GoalPage(
                    calculatedTarget: _calculatedTarget,
                    finalTarget: _finalTarget,
                    onTargetChanged: (v) => setState(() => _finalTarget = v),
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),
                  _PreferencesPage(
                    defaultGlassSize: _defaultGlassSize,
                    wakeTime: _wakeTime,
                    sleepTime: _sleepTime,
                    onChanged: (gs, wt, st) {
                      setState(() {
                        _defaultGlassSize = gs;
                        _wakeTime = wt;
                        _sleepTime = st;
                      });
                    },
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),
                  _PermissionsPage(
                    onNext: _nextPage,
                    onBack: _previousPage,
                  ),
                  _ReadyPage(onFinish: _completeOnboarding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: List.generate(_totalPages, (i) {
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i <= _currentPage
                    ? const Color(0xFF00BCD4)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// SAYFA 1: HOŞGELDİN
// ─────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Spacer(),
          // Animasyonlu ikon
          const Icon(Icons.water_drop, size: 96, color: Color(0xFF00BCD4)),
          const SizedBox(height: 24),
          const Text(
            'AquaCountdown\'a\nHoşgeldin!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          // Konsept açıklaması
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00BCD4).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                _conceptRow('❌', 'Klasik', 'Boş bardakla başla, içtikçe doldur',
                    isGood: false),
                const Divider(color: Colors.white12, height: 20),
                _conceptRow('✅', 'AquaCountdown',
                    'Dolu bardakla başla, içtikçe boşalt — Geri sayım!',
                    isGood: true),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '"Kalan miktar" gösterimi, tamamlanan miktardan\ndaha güçlü motivasyon yaratır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const Spacer(),
          _OnboardingButton(label: 'Başlayalım', onTap: onNext),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _conceptRow(String emoji, String title, String desc,
      {required bool isGood}) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isGood ? const Color(0xFF00BCD4) : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// SAYFA 2: PROFİL
// ─────────────────────────────────────────────────────

class _ProfilePage extends StatelessWidget {
  final String gender;
  final int weight;
  final int age;
  final String activity;
  final Function(String, int, int, String) onChanged;
  final VoidCallback onNext;

  const _ProfilePage({
    required this.gender,
    required this.weight,
    required this.age,
    required this.activity,
    required this.onChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const _PageTitle(
            title: 'Seni Tanıyalım',
            subtitle:
                'Bu bilgiler senin için kişisel su hedefi hesaplamak için kullanılır.',
          ),
          const SizedBox(height: 28),

          // Cinsiyet
          _SectionLabel('Cinsiyet'),
          const SizedBox(height: 10),
          Row(
            children: [
              _GenderChip(
                label: '👨 Erkek',
                selected: gender == 'male',
                onTap: () => onChanged('male', weight, age, activity),
              ),
              const SizedBox(width: 10),
              _GenderChip(
                label: '👩 Kadın',
                selected: gender == 'female',
                onTap: () => onChanged('female', weight, age, activity),
              ),
              const SizedBox(width: 10),
              _GenderChip(
                label: '⚧ Diğer',
                selected: gender == 'other',
                onTap: () => onChanged('other', weight, age, activity),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Kilo
          _SectionLabel('Kilo: $weight kg'),
          Slider(
            value: weight.toDouble(),
            min: 40,
            max: 150,
            divisions: 110,
            activeColor: const Color(0xFF00BCD4),
            inactiveColor: Colors.white12,
            onChanged: (v) => onChanged(gender, v.round(), age, activity),
          ),
          const SizedBox(height: 16),

          // Yaş
          _SectionLabel('Yaş: $age'),
          Slider(
            value: age.toDouble(),
            min: 10,
            max: 90,
            divisions: 80,
            activeColor: const Color(0xFF00BCD4),
            inactiveColor: Colors.white12,
            onChanged: (v) => onChanged(gender, weight, v.round(), activity),
          ),
          const SizedBox(height: 24),

          // Aktivite
          _SectionLabel('Aktivite Seviyesi'),
          const SizedBox(height: 10),
          ...['low', 'medium', 'high', 'athlete'].map((a) {
            final labels = {
              'low': '🛋️ Sedanter — Az hareket',
              'medium': '🚶 Orta — Günlük yürüyüş',
              'high': '🏃 Aktif — Düzenli spor',
              'athlete': '🏋️ Sporcu — Yoğun antrenman',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActivityTile(
                label: labels[a]!,
                selected: activity == a,
                onTap: () => onChanged(gender, weight, age, a),
              ),
            );
          }),

          const SizedBox(height: 24),
          _OnboardingButton(label: 'Devam Et', onTap: onNext),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// SAYFA 3: HEDEF
// ─────────────────────────────────────────────────────

class _GoalPage extends StatelessWidget {
  final int calculatedTarget;
  final int finalTarget;
  final ValueChanged<int> onTargetChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _GoalPage({
    required this.calculatedTarget,
    required this.finalTarget,
    required this.onTargetChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const _PageTitle(
            title: 'Günlük Hedefin',
            subtitle: 'Profiline göre kişisel hedefinizi hesapladık.',
          ),
          const Spacer(),

          // Hesaplanan hedef
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00BCD4).withOpacity(0.15),
                  const Color(0xFF0288D1).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF00BCD4).withOpacity(0.4),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${(calculatedTarget / 1000).toStringAsFixed(1)} L',
                  style: const TextStyle(
                    color: Color(0xFF00BCD4),
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -2,
                  ),
                ),
                Text(
                  'önerilen günlük su miktarı',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Manuel düzenleme
          Text(
            'Özelleştir: ${(finalTarget / 1000).toStringAsFixed(1)} L',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: finalTarget.toDouble(),
            min: 1000,
            max: 6000,
            divisions: 50,
            activeColor: const Color(0xFF00BCD4),
            inactiveColor: Colors.white12,
            onChanged: (v) => onTargetChanged(v.round()),
          ),
          Text(
            '1 L ← ${(finalTarget / 1000).toStringAsFixed(1)} L → 6 L',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),

          const Spacer(),
          _OnboardingButton(label: 'Bu hedefi kullan', onTap: onNext),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onBack,
            child: const Text('Geri', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// SAYFA 4: TERCİHLER
// ─────────────────────────────────────────────────────

class _PreferencesPage extends ConsumerWidget {
  final int defaultGlassSize;
  final TimeOfDay wakeTime;
  final TimeOfDay sleepTime;
  final Function(int, TimeOfDay, TimeOfDay) onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _PreferencesPage({
    required this.defaultGlassSize,
    required this.wakeTime,
    required this.sleepTime,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassSizes = [100, 200, 250, 330, 500];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const _PageTitle(
            title: 'Tercihler',
            subtitle: 'Bardak boyutunu ve uyku saatlerini ayarla.',
          ),
          const SizedBox(height: 28),

          _SectionLabel('Varsayılan Bardak Boyutu'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: glassSizes.map((ml) {
              return ChoiceChip(
                label: Text('$ml ml'),
                selected: defaultGlassSize == ml,
                onSelected: (_) => onChanged(ml, wakeTime, sleepTime),
                selectedColor: const Color(0xFF00BCD4),
                backgroundColor: Colors.white.withOpacity(0.08),
                labelStyle: TextStyle(
                  color: defaultGlassSize == ml ? Colors.white : Colors.white70,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          _SectionLabel('Uyanış Saati'),
          _TimeTile(
            time: wakeTime,
            icon: Icons.wb_sunny_outlined,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: wakeTime,
              );
              if (picked != null) onChanged(defaultGlassSize, picked, sleepTime);
            },
          ),
          const SizedBox(height: 12),

          _SectionLabel('Uyku Saati'),
          _TimeTile(
            time: sleepTime,
            icon: Icons.bedtime_outlined,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: sleepTime,
              );
              if (picked != null) onChanged(defaultGlassSize, wakeTime, picked);
            },
          ),
          const SizedBox(height: 32),

          _OnboardingButton(label: 'Devam Et', onTap: onNext),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onBack,
            child: const Text('Geri', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// SAYFA 5: İZİNLER
// ─────────────────────────────────────────────────────

class _PermissionsPage extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _PermissionsPage({required this.onNext, required this.onBack});

  @override
  State<_PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<_PermissionsPage> {
  bool _notifGranted = false;
  bool _overlayGranted = false;
  bool _wallpaperSet = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final overlay = await NativeBridge.hasOverlayPermission();
      final wallpaper = await NativeBridge.isWallpaperSet();
      setState(() {
        _overlayGranted = overlay;
        _wallpaperSet = wallpaper;
      });
    } catch (_) {
      // Native kanal henüz hazır değilse sessizce geç
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const _PageTitle(
            title: 'İzinler',
            subtitle: 'Tümü isteğe bağlıdır — istediğini seç, gerisini atla.',
          ),
          const SizedBox(height: 20),

          // Bildirim izni
          _PermissionTile(
            icon: Icons.notifications_outlined,
            title: 'Bildirimler',
            description: 'Su içme hatırlatmaları için.',
            granted: _notifGranted,
            optional: true,
            onRequest: () async {
              setState(() => _notifGranted = true);
            },
          ),
          const SizedBox(height: 10),

          // Overlay izni
          _PermissionTile(
            icon: Icons.layers_outlined,
            title: 'Yüzen Buton',
            description: 'Diğer uygulamalar üzerinde su ekleme butonu.',
            granted: _overlayGranted,
            optional: true,
            onRequest: () async {
              try {
                await NativeBridge.requestOverlayPermission();
                await Future.delayed(const Duration(seconds: 1));
                final granted = await NativeBridge.hasOverlayPermission();
                setState(() => _overlayGranted = granted);
              } catch (_) {}
            },
          ),
          const SizedBox(height: 10),

          // Live Wallpaper
          _PermissionTile(
            icon: Icons.wallpaper,
            title: 'Canlı Duvar Kağıdı',
            description: 'Telefon ekranında bardak görseli.',
            granted: _wallpaperSet,
            optional: true,
            onRequest: () async {
              try {
                await NativeBridge.openWallpaperPicker();
                final isSet = await NativeBridge.isWallpaperSet();
                setState(() => _wallpaperSet = isSet);
              } catch (_) {}
            },
          ),

          const Spacer(),

          // Devam Et — büyük, belirgin
          _OnboardingButton(label: 'Devam Et →', onTap: widget.onNext),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'İzin vermeden de devam edebilirsin',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: widget.onBack,
            child: const Text('Geri', style: TextStyle(color: Colors.white38)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// SAYFA 6: HAZIR!
// ─────────────────────────────────────────────────────

class _ReadyPage extends StatelessWidget {
  final VoidCallback onFinish;
  const _ReadyPage({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const Text('🎉', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 24),
          const Text(
            'Hazırsın!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bardağın dolu. Boşaltma zamanı! 💧\n\nSu içtiğinde butona basarak'
            ' bardağını boşalt ve günlük hedefini tamamla.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
              height: 1.6,
            ),
          ),
          const Spacer(),
          _OnboardingButton(label: 'Başla!', onTap: onFinish),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// YARDIMCI WİDGETLER
// ─────────────────────────────────────────────────────

class _OnboardingButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OnboardingButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00BCD4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _PageTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PageTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 14),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withOpacity(0.7),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _GenderChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenderChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00BCD4).withOpacity(0.2)
              : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF00BCD4)
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF00BCD4) : Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityTile(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF00BCD4).withOpacity(0.12)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFF00BCD4)
                : Colors.white.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFF00BCD4) : Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Color(0xFF00BCD4), size: 18),
          ],
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final TimeOfDay time;
  final IconData icon;
  final VoidCallback onTap;

  const _TimeTile(
      {required this.time, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF00BCD4), size: 20),
            const SizedBox(width: 12),
            Text(
              time.format(context),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.4)),
          ],
        ),
      ),
    );
  }
}

class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final bool optional;
  final VoidCallback onRequest;

  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.onRequest,
    this.optional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: granted
              ? const Color(0xFF4CAF50).withOpacity(0.5)
              : Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00BCD4), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (optional) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'opsiyonel',
                          style: TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (granted)
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 22)
          else
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00BCD4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: const Color(0xFF00BCD4).withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onRequest,
              child: const Text('İzin Ver', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
