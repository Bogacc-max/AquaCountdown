import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/services/ad_manager.dart';
import '../../../core/themes/app_theme.dart';
import '../../../data/models/daily_record.dart';
import '../../providers/water_provider.dart';

/// Raporlar Ekranı — Günlük / Haftalık / Aylık sekmeli
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  BannerAd? _bannerAd;
  bool _bannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _bannerAd = AdManager.instance.createBannerAd(
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _bannerLoaded = true),
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aqua = context.aqua;
    return Scaffold(
      backgroundColor: aqua.scaffoldGradientStart,
      appBar: AppBar(
        backgroundColor: aqua.scaffoldGradientStart,
        elevation: 0,
        title: Text(
          'Raporlar',
          style: TextStyle(color: aqua.textPrimary, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00BCD4),
          labelColor: const Color(0xFF00BCD4),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'Günlük'),
            Tab(text: 'Haftalık'),
            Tab(text: 'Aylık'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _DailyTab(),
                _WeeklyTab(),
                _MonthlyTab(
                  selectedMonth: _selectedMonth,
                  onMonthChanged: (m) => setState(() => _selectedMonth = m),
                ),
              ],
            ),
          ),
          if (_bannerLoaded && _bannerAd != null)
            SafeArea(
              top: false,
              child: SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// GÜNLÜK SEKME
// ─────────────────────────────────────────────────────

class _DailyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordAsync = ref.watch(todayRecordProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return recordAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4))),
      error: (e, _) => Center(child: Text('$e')),
      data: (record) {
        final unit = settingsAsync.valueOrNull?.unit ?? 'ml';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Özet kartları
              Row(
                children: [
                  _StatCard(
                    label: 'İçilen',
                    value: _fmt(record.consumedMl, unit),
                    color: const Color(0xFF00BCD4),
                    icon: Icons.water_drop,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Hedef',
                    value: _fmt(record.targetMl, unit),
                    color: Colors.white54,
                    icon: Icons.flag_outlined,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Kalan',
                    value: _fmt(record.remainingMl, unit),
                    color: const Color(0xFFFFD54F),
                    icon: Icons.hourglass_bottom,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Saatlik dağılım grafiği
              _SectionTitle('Saatlik Dağılım'),
              const SizedBox(height: 12),
              _HourlyChart(record: record),

              const SizedBox(height: 20),

              // İlerleme halka
              _SectionTitle('Günlük İlerleme'),
              const SizedBox(height: 12),
              _ProgressRing(ratio: record.progressRatio),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
// HAFTALIK SEKME
// ─────────────────────────────────────────────────────

class _WeeklyTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekAsync = ref.watch(weeklyRecordsProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final streakAsync = ref.watch(streakProvider);

    return weekAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4))),
      error: (e, _) => Center(child: Text('$e')),
      data: (records) {
        final unit = settingsAsync.valueOrNull?.unit ?? 'ml';
        final streak = streakAsync.valueOrNull ?? 0;

        // Son 7 gün için map oluştur
        final now = DateTime.now();
        final Map<DateTime, DailyRecord> recordMap = {
          for (final r in records) DailyRecord.normalizeDate(r.date): r
        };

        final days = List.generate(7, (i) {
          final d = DailyRecord.normalizeDate(
              now.subtract(Duration(days: 6 - i)));
          return (date: d, record: recordMap[d]);
        });

        // Haftalık ortalama
        final total = records.fold(0, (s, r) => s + r.consumedMl);
        final avg = records.isNotEmpty ? total ~/ records.length : 0;
        final goalDays = records.where((r) => r.goalReached).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Özet
              Row(
                children: [
                  _StatCard(
                    label: 'Ortalama',
                    value: _fmt(avg, unit),
                    color: const Color(0xFF00BCD4),
                    icon: Icons.show_chart,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Hedef Gün',
                    value: '$goalDays/7',
                    color: const Color(0xFF4CAF50),
                    icon: Icons.check_circle_outline,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Seri',
                    value: '$streak 🔥',
                    color: Colors.orange,
                    icon: Icons.local_fire_department,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle('7 Günlük Grafik'),
              const SizedBox(height: 12),
              _WeeklyBarChart(days: days),

              const SizedBox(height: 20),
              _SectionTitle('Gün Detayları'),
              const SizedBox(height: 10),
              ...days.map((d) => _DayDetailTile(
                    date: d.date,
                    record: d.record,
                    unit: unit,
                  )),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
// AYLIK SEKME
// ─────────────────────────────────────────────────────

class _MonthlyTab extends ConsumerWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const _MonthlyTab({
    required this.selectedMonth,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthAsync = ref.watch(monthlyRecordsProvider(
      (year: selectedMonth.year, month: selectedMonth.month),
    ));
    final settingsAsync = ref.watch(settingsProvider);

    return monthAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BCD4))),
      error: (e, _) => Center(child: Text('$e')),
      data: (records) {
        final unit = settingsAsync.valueOrNull?.unit ?? 'ml';
        final total = records.fold(0, (s, r) => s + r.consumedMl);
        final avg = records.isNotEmpty ? total ~/ records.length : 0;
        final goalDays = records.where((r) => r.goalReached).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Ay navigasyonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: context.aqua.textPrimary),
                    onPressed: () => onMonthChanged(DateTime(
                        selectedMonth.year, selectedMonth.month - 1)),
                  ),
                  Text(
                    DateFormat('MMMM yyyy', 'tr_TR').format(selectedMonth),
                    style: TextStyle(
                      color: context.aqua.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: context.aqua.textPrimary),
                    onPressed: selectedMonth.month == DateTime.now().month &&
                            selectedMonth.year == DateTime.now().year
                        ? null
                        : () => onMonthChanged(DateTime(
                            selectedMonth.year, selectedMonth.month + 1)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Özet
              Row(
                children: [
                  _StatCard(
                    label: 'Toplam',
                    value: _fmt(total, unit),
                    color: const Color(0xFF00BCD4),
                    icon: Icons.water_drop,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Günlük Ort.',
                    value: _fmt(avg, unit),
                    color: Colors.white70,
                    icon: Icons.show_chart,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Hedef Gün',
                    value: '$goalDays',
                    color: const Color(0xFF4CAF50),
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _SectionTitle('Takvim (Isı Haritası)'),
              const SizedBox(height: 12),
              _MonthlyHeatmap(
                records: records,
                selectedMonth: selectedMonth,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────
// GRAFİK WİDGETLERİ
// ─────────────────────────────────────────────────────

class _HourlyChart extends StatelessWidget {
  final DailyRecord record;

  const _HourlyChart({required this.record});

  @override
  Widget build(BuildContext context) {
    // Saatlik gruplandırma
    final Map<int, int> hourly = {};
    for (final intake in record.intakes) {
      if (intake.isDeleted) continue;
      final h = intake.timestamp.hour;
      hourly[h] = (hourly[h] ?? 0) + intake.amountMl;
    }

    final spots = List.generate(18, (i) {
      final hour = i + 6; // 06:00 - 23:00
      return BarChartGroupData(
        x: hour,
        barRods: [
          BarChartRodData(
            toY: (hourly[hour] ?? 0).toDouble(),
            color: const Color(0xFF00BCD4),
            width: 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          barGroups: spots,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final h = v.toInt();
                  if (h % 3 != 0) return const SizedBox.shrink();
                  return Text(
                    '$h',
                    style:
                        TextStyle(color: context.aqua.textHint, fontSize: 10),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<({DateTime date, DailyRecord? record})> days;

  const _WeeklyBarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    final groups = List.generate(days.length, (i) {
      final r = days[i].record;
      final consumed = r?.consumedMl.toDouble() ?? 0;
      final target = r?.targetMl.toDouble() ?? 2500;
      final goalReached = r?.goalReached ?? false;

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: consumed,
            color: goalReached
                ? const Color(0xFF4CAF50)
                : const Color(0xFF00BCD4).withOpacity(0.7),
            width: 28,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(6)),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: target,
              color: context.aqua.cardBg,
            ),
          ),
        ],
      );
    });

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          barGroups: groups,
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final dayDate = days[v.toInt()].date;
                  final name = dayNames[dayDate.weekday - 1];
                  return Text(
                    name,
                    style:
                        TextStyle(color: context.aqua.textHint, fontSize: 11),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final double ratio;

  const _ProgressRing({required this.ratio});

  @override
  Widget build(BuildContext context) {
    final percentage = (ratio * 100).round();
    return SizedBox(
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: ratio * 100,
                  color: const Color(0xFF00BCD4),
                  radius: 24,
                  title: '',
                ),
                PieChartSectionData(
                  value: (1 - ratio) * 100,
                  color: context.aqua.cardBg,
                  radius: 24,
                  title: '',
                ),
              ],
              centerSpaceRadius: 52,
              sectionsSpace: 0,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '%$percentage',
                style: TextStyle(
                  color: context.aqua.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'tamamlandı',
                style: TextStyle(
                  color: context.aqua.textHint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyHeatmap extends StatelessWidget {
  final List<DailyRecord> records;
  final DateTime selectedMonth;

  const _MonthlyHeatmap(
      {required this.records, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, DailyRecord> recordMap = {
      for (final r in records) DailyRecord.normalizeDate(r.date): r
    };

    final firstDay = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final daysInMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    // Haftanın başlangıcı için offset (Pazartesi=1)
    final startOffset = (firstDay.weekday - 1) % 7;

    final dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

    final aqua = context.aqua;
    return Column(
      children: [
        Row(
          children: dayNames
              .map((d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: aqua.textHint, fontSize: 11),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (ctx, i) {
            if (i < startOffset) return const SizedBox.shrink();
            final day = i - startOffset + 1;
            final date = DateTime(selectedMonth.year, selectedMonth.month, day);
            final record = recordMap[date];

            Color cellColor;
            if (record == null) {
              cellColor = aqua.cardBg;
            } else if (record.goalReached) {
              cellColor = const Color(0xFF4CAF50);
            } else {
              final pct = record.progressRatio;
              cellColor = Color.lerp(
                aqua.cardBg,
                const Color(0xFF00BCD4),
                pct,
              )!;
            }

            return Container(
              decoration: BoxDecoration(
                color: cellColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: aqua.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────
// YARDIMCI WİDGETLER
// ─────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final aqua = context.aqua;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: aqua.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: aqua.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: aqua.textHint, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: context.aqua.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _DayDetailTile extends StatelessWidget {
  final DateTime date;
  final DailyRecord? record;
  final String unit;

  const _DayDetailTile({
    required this.date,
    required this.record,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final aqua = context.aqua;
    final dayName =
        DateFormat('EEEE, d MMM', 'tr_TR').format(date);
    final consumed = record?.consumedMl ?? 0;
    final target = record?.targetMl ?? 2500;
    final reached = record?.goalReached ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: reached ? const Color(0xFF4CAF50) : aqua.cardBorder,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dayName,
              style: TextStyle(color: aqua.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            '${_fmt(consumed, unit)} / ${_fmt(target, unit)}',
            style: TextStyle(
              color: reached ? const Color(0xFF4CAF50) : aqua.textHint,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

String _fmt(int ml, String unit) {
  if (unit == 'oz') return '${(ml / 29.5735).toStringAsFixed(0)} oz';
  return ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1)} L' : '$ml ml';
}
