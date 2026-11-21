import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import 'home.dart';

enum Period { week, month, year, all }

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Period _period = Period.month;

  DateTime? _cutoff(DateTime today) {
    switch (_period) {
      case Period.week:
        return today.subtract(const Duration(days: 6));
      case Period.month:
        return today.subtract(const Duration(days: 29));
      case Period.year:
        return DateTime(today.year, today.month - 11, 1);
      case Period.all:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final n = DateTime.now();
        final today = DateTime(n.year, n.month, n.day);
        final cutoff = _cutoff(today);
        final tips = store.visible
            .where((t) => cutoff == null || !t.date.isBefore(cutoff))
            .toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Statystyki')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const WorkplaceChips(),
              const SizedBox(height: 12),
              SegmentedButton<Period>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: Period.week, label: Text('7 dni')),
                  ButtonSegment(value: Period.month, label: Text('30 dni')),
                  ButtonSegment(value: Period.year, label: Text('Rok')),
                  ButtonSegment(value: Period.all, label: Text('Całość')),
                ],
                selected: {_period},
                onSelectionChanged: (s) => setState(() => _period = s.first),
              ),
              const SizedBox(height: 16),
              if (tips.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text('Brak wpisów w tym okresie.', textAlign: TextAlign.center),
                )
              else ...[
                _Summary(tips: tips),
                const SizedBox(height: 12),
                _TimeChart(tips: tips, period: _period, today: today),
                const SizedBox(height: 12),
                _WeekdayChart(tips: tips),
                const SizedBox(height: 12),
                _Split(tips: tips),
                if (store.filterId == null && store.workplaces.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ByWorkplace(tips: tips),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Summary extends StatelessWidget {
  final List<Tip> tips;
  const _Summary({required this.tips});

  @override
  Widget build(BuildContext context) {
    final total = tips.fold<int>(0, (s, t) => s + t.net);
    final avg = (total / tips.length).round();
    final withHours = tips.where((t) => t.hours != null && t.hours! > 0).toList();
    final hrs = withHours.fold<double>(0, (s, t) => s + t.hours!);
    final netH = withHours.fold<int>(0, (s, t) => s + t.net);
    final best = tips.reduce((a, b) => a.net >= b.net ? a : b);
    final out = tips.fold<int>(0, (s, t) => s + t.tipOut);

    Widget cell(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFeatures: tabular)),
            ],
          ),
        );

    return Panel(
      child: Column(
        children: [
          Row(children: [
            cell('Suma netto', fmtMoney(total)),
            cell('Liczba zmian', '${tips.length}'),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            cell('Średnio na zmianę', fmtMoney(avg)),
            cell('Średnio na godzinę', hrs > 0 ? fmtMoney((netH / hrs).round()) : 'brak godzin'),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            cell('Najlepsza zmiana', '${fmtMoney(best.net)} (${DateFormat('d.MM', 'pl').format(best.date)})'),
            cell('Suma odliczeń', fmtMoney(out)),
          ]),
        ],
      ),
    );
  }
}

class _Bucket {
  final String label;
  final double value;
  const _Bucket(this.label, this.value);
}

BarChartData _barData(BuildContext context, List<_Bucket> b,
    {double width = 12, int skip = 1, Color? color}) {
  final s = Theme.of(context).colorScheme;
  return BarChartData(
    gridData: const FlGridData(show: false),
    borderData: FlBorderData(show: false),
    titlesData: FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 26,
          getTitlesWidget: (v, meta) {
            final i = v.toInt();
            if (i < 0 || i >= b.length || i % skip != 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(b[i].label, style: const TextStyle(fontSize: 10)),
            );
          },
        ),
      ),
    ),
    barTouchData: BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
          fmtMoney((rod.toY * 100).round()),
          TextStyle(color: s.onInverseSurface, fontWeight: FontWeight.w600),
        ),
      ),
    ),
    barGroups: [
      for (var i = 0; i < b.length; i++)
        BarChartGroupData(x: i, barRods: [
          BarChartRodData(
            toY: b[i].value,
            width: width,
            color: color ?? kTeal,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ]),
    ],
  );
}

class _TimeChart extends StatelessWidget {
  final List<Tip> tips;
  final Period period;
  final DateTime today;
  const _TimeChart({required this.tips, required this.period, required this.today});

  List<_Bucket> _buckets() {
    if (period == Period.week || period == Period.month) {
      final days = period == Period.week ? 7 : 30;
      final start = today.subtract(Duration(days: days - 1));
      return [
        for (var i = 0; i < days; i++)
          () {
            final d = DateTime(start.year, start.month, start.day + i);
            final sum = tips.where((t) => t.date == d).fold<int>(0, (s, t) => s + t.net);
            final label = period == Period.week ? weekdayShort[d.weekday - 1] : '${d.day}';
            return _Bucket(label, sum / 100);
          }(),
      ];
    }
    var months = 12;
    if (period == Period.all) {
      final first = tips.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
      months = ((today.year - first.year) * 12 + today.month - first.month + 1).clamp(1, 24);
    }
    return [
      for (var i = months - 1; i >= 0; i--)
        () {
          final m = DateTime(today.year, today.month - i, 1);
          final sum = tips
              .where((t) => t.date.year == m.year && t.date.month == m.month)
              .fold<int>(0, (s, t) => s + t.net);
          return _Bucket(DateFormat('LLL', 'pl').format(m), sum / 100);
        }(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final b = _buckets();
    final width = period == Period.week ? 20.0 : (period == Period.month ? 5.0 : (b.length > 12 ? 8.0 : 14.0));
    final skip = period == Period.month ? 5 : (b.length > 12 ? 2 : 1);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(period == Period.week || period == Period.month ? 'Netto dzień po dniu' : 'Netto miesiąc po miesiącu',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(height: 180, child: BarChart(_barData(context, b, width: width, skip: skip))),
        ],
      ),
    );
  }
}

class _WeekdayChart extends StatelessWidget {
  final List<Tip> tips;
  const _WeekdayChart({required this.tips});

  @override
  Widget build(BuildContext context) {
    final b = <_Bucket>[];
    for (var wd = 1; wd <= 7; wd++) {
      final list = tips.where((t) => t.date.weekday == wd).toList();
      final avg = list.isEmpty ? 0.0 : list.fold<int>(0, (s, t) => s + t.net) / list.length / 100;
      b.add(_Bucket(weekdayShort[wd - 1], avg));
    }
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Średnio na zmianę wg dnia tygodnia', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(height: 150, child: BarChart(_barData(context, b, width: 20, color: kBrass))),
        ],
      ),
    );
  }
}

class _Split extends StatelessWidget {
  final List<Tip> tips;
  const _Split({required this.tips});

  @override
  Widget build(BuildContext context) {
    final cash = tips.fold<int>(0, (s, t) => s + t.cash);
    final card = tips.fold<int>(0, (s, t) => s + t.card);
    final all = cash + card;
    final cashShare = all == 0 ? 0.0 : cash / all;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gotówka i karta', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: cashShare,
              minHeight: 10,
              color: kBrass,
              backgroundColor: kTeal,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Gotówka ${fmtMoney(cash)} (${(cashShare * 100).round()}%)'),
              Text('Karta ${fmtMoney(card)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ByWorkplace extends StatelessWidget {
  final List<Tip> tips;
  const _ByWorkplace({required this.tips});

  @override
  Widget build(BuildContext context) {
    final sums = <int?, int>{};
    for (final t in tips) {
      sums[t.workplaceId] = (sums[t.workplaceId] ?? 0) + t.net;
    }
    final entries = sums.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Wg miejsca pracy', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(store.workplaceName(e.key)),
                  Text(fmtMoney(e.value), style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: tabular)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
