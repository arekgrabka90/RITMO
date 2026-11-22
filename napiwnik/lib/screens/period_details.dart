import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dates.dart';
import '../models.dart';
import '../overview.dart';
import '../period.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'home.dart';
import 'tiles.dart';

/// Szczegóły okresu rozliczeniowego: sumy, podział na miejsca i lista wpisów napiwków.
/// Strzałki przechodzą między okresami.
class PeriodDetailsScreen extends StatefulWidget {
  const PeriodDetailsScreen({super.key});

  @override
  State<PeriodDetailsScreen> createState() => _PeriodDetailsScreenState();
}

class _PeriodDetailsScreenState extends State<PeriodDetailsScreen> {
  late BillingPeriod _period = store.currentPeriod;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = DateTime.now();
        final today = dateOnly(now);
        final type = store.periodType;
        final anchor = store.periodAnchor;
        final next = nextPeriod(_period, type, anchor);
        final current = _period.contains(today);
        final stats = computePeriodStats(
          period: _period,
          shifts: store.shifts,
          tips: store.tips,
          rates: store.rates,
          now: now,
        );
        final tips = store.tips.where((t) => _period.contains(t.date)).toList();
        final byPlace = tipsByWorkplace(_period, store.tips).entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        final perHour = stats.tipsPerHour;

        return Scaffold(
          appBar: AppBar(title: const Text('Okres rozliczeniowy')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              PeriodSwitcher(
                label: periodRangeLabel(_period),
                onPrev: () => setState(() => _period = previousPeriod(_period, type, anchor)),
                onNext: next.start.isAfter(today) ? null : () => setState(() => _period = next),
                onTap: current ? null : () => setState(() => _period = store.currentPeriod),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  current ? 'Bieżący okres, zostało ${fmtDays(_period.daysLeft(today))}' : periodTypeName(type),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 13),
                ),
              ),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Napiwki netto',
                        value: fmtMoney(stats.tipsNet),
                        caption: perHour == null ? 'brak wpisów' : '${fmtMoney(perHour)} na godzinę',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        label: 'Godziny',
                        value: fmtDuration(stats.workedMin),
                        caption: stats.remainingMin > 0
                            ? 'jeszcze ${fmtDuration(stats.remainingMin)} w planie'
                            : '${fmtShiftCount(stats.shiftCount)} w okresie',
                      ),
                    ),
                  ],
                ),
              ),
              if (stats.hasRates) ...[
                const SizedBox(height: 12),
                StatTile(
                  label: 'Zarobki',
                  value: fmtMoney(stats.total),
                  caption: 'wypłata ${fmtMoney(stats.wages)} + napiwki ${fmtMoney(stats.tipsNet)}',
                ),
              ],
              if (byPlace.length > 1) ...[
                const SizedBox(height: 12),
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Napiwki według miejsca', style: TextStyle(fontSize: 13, color: muted)),
                      const SizedBox(height: 8),
                      for (final e in byPlace)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(store.workplaceName(e.key)),
                              Text(fmtMoney(e.value),
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontFeatures: tabular)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              if (tips.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text('Brak wpisów napiwków w tym okresie.',
                      textAlign: TextAlign.center, style: TextStyle(color: muted)),
                )
              else
                ..._groups(context, tips),
              const SizedBox(height: 8),
              Text(
                'Dotknij wpisu, aby go edytować. Przytrzymaj, aby zobaczyć opcje. Przesuń w lewo, aby usunąć.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _groups(BuildContext context, List<Tip> tips) {
    final out = <Widget>[];
    DateTime? last;
    for (final t in tips) {
      if (last == null || last != t.date) {
        out.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
          child: Text(
            toBeginningOfSentenceCase(DateFormat('EEEE, d MMMM', 'pl').format(t.date))!,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ));
        last = t.date;
      }
      out.add(TipTile(tip: t));
    }
    return out;
  }
}
