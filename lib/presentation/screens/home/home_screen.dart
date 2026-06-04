import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/water_intake.dart';
import '../../../data/models/user_settings.dart';
import '../../providers/water_provider.dart';
import '../../widgets/bottle_widget.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';

/// AquaCountdown Ana Ekranı
///
/// Ekran düzeni (spesifikasyona göre):
/// - Üst: Selamlama + tarih
/// - Orta: Büyük bardak görseli (ekranın ~%45'i)
/// - Alt: Hızlı ekleme butonları + su geçmişi
/// - Streak göstergesi
/// - Alt navigasyon çubuğu
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // Konfeti kontrolcüsü
  late ConfettiController _confettiController;
  // Ses oynatıcı
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Sekme indeksi
  int _currentTab = 0;
  bool _goalCelebrated = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildMainTab(),
          const ReportsScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMainTab() {
    final recordAsync = ref.watch(todayRecordProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final streakAsync = ref.watch(streakProvider);

    return recordAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
      ),
      error: (e, _) => Center(child: Text('Hata: $e')),
      data: (record) {
        final settings = settingsAsync.valueOrNull ?? UserSettings.defaults();
        final streak = streakAsync.valueOrNull ?? 0;

        // Hedef tamamlandı mı? Konfeti göster
        if (record.goalReached && !_goalCelebrated) {
          _goalCelebrated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _confettiController.play();
          });
        } else if (!record.goalReached) {
          _goalCelebrated = false;
        }

        return Stack(
          children: [
            // Arkaplan gradyanı
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A1929),
                    const Color(0xFF0D2137),
                    const Color(0xFF006064).withOpacity(0.3),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // ── Üst başlık ──
                  _buildHeader(streak),
                  const SizedBox(height: 8),

                  // ── Bardak widget (ekranın ortası) ──
                  Expanded(
                    flex: 5,
                    child: Center(
                      child: BottleWidget(
                        fillRatio: 1.0 - record.progressRatio,
                        remainingMl: record.remainingMl,
                        targetMl: record.targetMl,
                        unit: settings.unit,
                        size: MediaQuery.of(context).size.width * 0.55,
                        showCelebration: record.goalReached,
                      ),
                    ),
                  ),

                  // ── Hızlı ekleme butonları ──
                  _buildQuickAddButtons(settings),

                  const SizedBox(height: 12),

                  // ── Bugünün kayıt zaman çizelgesi ──
                  Expanded(
                    flex: 3,
                    child: _buildIntakeTimeline(settings),
                  ),
                ],
              ),
            ),

            // Konfeti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.06,
                numberOfParticles: 15,
                gravity: 0.2,
                colors: const [
                  Color(0xFF00BCD4),
                  Color(0xFFFFD54F),
                  Color(0xFF4CAF50),
                  Color(0xFFE91E63),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Üst başlık: tarih + selamlama + streak
  Widget _buildHeader(int streak) {
    final now = DateTime.now();
    final greeting = _getGreeting(now.hour);
    final dateStr = DateFormat('d MMMM, EEEE', 'tr_TR').format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (streak > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    '$streak gün',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Hızlı su ekleme butonları
  Widget _buildQuickAddButtons(UserSettings settings) {
    final amounts = [100, 200, 330, 500];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Ne kadar içtin?',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            children: [
              ...amounts.map((ml) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _QuickAddButton(
                        amountMl: ml,
                        unit: settings.unit,
                        onTap: () => _addWater(ml, settings),
                      ),
                    ),
                  )),
              const SizedBox(width: 4),
              _CustomAmountButton(
                onTap: () => _showCustomAmountSheet(settings),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bugünün içme zaman çizelgesi
  Widget _buildIntakeTimeline(UserSettings settings) {
    // todayRecordProvider'dan intakes çek — addWater sonrası otomatik güncellenir
    final recordAsync = ref.watch(todayRecordProvider);

    return recordAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (record) {
        final intakes = record.intakes
            .where((i) => !i.isDeleted)
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (intakes.isEmpty) {
          return Center(
            child: Text(
              'Henüz su içmedin. Başlamaya hazır mısın? 💧',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: intakes.length,
          itemBuilder: (ctx, i) => _IntakeTile(
            intake: intakes[i],
            unit: settings.unit,
            onUndo: () {
              ref
                  .read(todayRecordProvider.notifier)
                  .removeIntake(intakes[i].id!);
            },
          ),
        );
      },
    );
  }

  /// Su ekle — ses + titreşim + state güncelle
  void _addWater(int amountMl, UserSettings settings) {
    // Titreşim
    if (settings.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    // Su damlası sesi
    if (settings.soundEnabled) {
      _audioPlayer.play(AssetSource('sounds/water_drop.wav'));
    }
    ref.read(todayRecordProvider.notifier).addWater(amountMl: amountMl);
  }

  /// Özel miktar bottom sheet
  void _showCustomAmountSheet(UserSettings settings) {
    int customMl = settings.defaultGlassSizeMl;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D2137),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Özel Miktar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                settings.unit == 'ml' ? '$customMl ml' : '${(customMl / 29.5735).toStringAsFixed(1)} oz',
                style: const TextStyle(
                  color: Color(0xFF00BCD4),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Slider(
                value: customMl.toDouble(),
                min: 50,
                max: 1500,
                divisions: 29,
                activeColor: const Color(0xFF00BCD4),
                inactiveColor: Colors.white12,
                onChanged: (v) => setModal(() => customMl = v.round()),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BCD4),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _addWater(customMl, settings);
                },
                child: const Text('Ekle', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return NavigationBar(
      backgroundColor: const Color(0xFF0A1929),
      selectedIndex: _currentTab,
      onDestinationSelected: (i) => setState(() => _currentTab = i),
      indicatorColor: const Color(0xFF00BCD4).withOpacity(0.2),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.water_drop_outlined),
          selectedIcon: Icon(Icons.water_drop, color: Color(0xFF00BCD4)),
          label: 'Ana',
        ),
        NavigationDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF00BCD4)),
          label: 'Raporlar',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings, color: Color(0xFF00BCD4)),
          label: 'Ayarlar',
        ),
      ],
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Günaydın! ☀️';
    if (hour < 18) return 'İyi öğleden sonralar! 🌤️';
    return 'İyi akşamlar! 🌙';
  }
}

// ─────────────────────────────────────────────────────
// ALT WİDGETLER
// ─────────────────────────────────────────────────────

class _QuickAddButton extends StatelessWidget {
  final int amountMl;
  final String unit;
  final VoidCallback onTap;

  const _QuickAddButton({
    required this.amountMl,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = unit == 'oz'
        ? '${(amountMl / 29.5735).toStringAsFixed(0)} oz'
        : '$amountMl ml';

    return Material(
      color: const Color(0xFF00BCD4).withOpacity(0.18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.water_drop,
                color: Color(0xFF00BCD4),
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomAmountButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CustomAmountButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF00BCD4), size: 22),
              SizedBox(height: 6),
              Text(
                'Özel',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntakeTile extends StatelessWidget {
  final WaterIntake intake;
  final String unit;
  final VoidCallback onUndo;

  const _IntakeTile({
    required this.intake,
    required this.unit,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = TimeOfDay.fromDateTime(intake.timestamp).format(context);
    final amountStr = unit == 'oz'
        ? '${(intake.amountMl / 29.5735).toStringAsFixed(0)} oz'
        : '${intake.amountMl} ml';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF00BCD4),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            timeStr,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '— $amountStr',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onUndo,
            child: Icon(
              Icons.undo,
              color: Colors.white.withOpacity(0.35),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
