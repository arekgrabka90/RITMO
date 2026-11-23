import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dates.dart';
import '../models.dart';
import '../overview.dart';
import '../percent.dart';
import '../period.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import 'home.dart';
import 'period_details.dart';
import 'shift_actions.dart';
import 'shift_form.dart';
import 'tiles.dart';

const _onTeal = Colors.white;
const _onTealMuted = Colors.white70;
const _gold = Color(0xFFFFD58A); // jasne złoto czytelne na turkusie

/// „Dziś”, „Jutro” albo „Pt 27.11”.
String _dayLabel(DateTime date, DateTime today) {
  final d = daysBetween(today, date);
  if (d == 0) return 'Dziś';
  if (d == 1) return 'Jutro';
  return '${weekdayShort[date.weekday - 1]} ${shortDate(date)}';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Odliczanie („zostało 2 h”) odświeża się co minutę.
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PeriodDetailsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final now = DateTime.now();
        final today = dateOnly(now);
        final period = store.currentPeriod;
        // Filtr miejsca pracy (chipsy u góry) działa tak samo jak w pozostałych zakładkach.
        final shifts = store.visibleShifts;
        final tipList = store.visible;
        final stats = computePeriodStats(
          period: period,
          shifts: shifts,
          tips: tipList,
          rates: store.rates,
          now: now,
        );
        final focus = pickFocusShift(shifts, now);
        final upcoming = upcomingShifts(shifts, now, exclude: focus, limit: 4);
        final unfilled = unfilledShifts(shifts, now);
        final toPay = daysToPayday(today, store.payDay);
        final payDate = nextPayday(today, store.payDay);
        final left = period.daysLeft(today);
        final goal = store.goal;
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;
        final perHour = stats.tipsPerHour;
        final sales = salesLine(stats);

        return Scaffold(
          appBar: AppBar(title: const Text('Dashboard')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              const WorkplaceChips(),
              const SizedBox(height: 8),
              _TodayCard(shift: focus, now: now, next: upcoming.isEmpty ? null : upcoming.first),
              // Licznik pojawia się na tydzień przed wypłatą.
              if (toPay != null && payDate != null && toPay <= 7) ...[
                const SizedBox(height: 12),
                _PaydayTile(days: toPay, date: payDate),
              ],
              if (unfilled.isNotEmpty) ...[
                const SizedBox(height: 12),
                StatTile(
                  label: 'Do uzupełnienia',
                  value: fmtShiftCount(unfilled.length),
                  valueColor: kBrass,
                  caption: 'Dotknij, aby wpisać napiwki z najstarszej zmiany',
                  onTap: () => openForm(context, shift: unfilled.first),
                ),
              ],
              const SizedBox(height: 20),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _openDetails,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Okres ${periodRangeLabel(period)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        left <= 1 ? 'ostatni dzień' : 'zostało ${fmtDays(left)}',
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'Napiwki netto',
                        value: fmtMoney(stats.tipsNet),
                        caption: [
                          perHour == null ? 'brak wpisów' : '${fmtMoney(perHour)} na godzinę',
                          if (sales != null) sales,
                        ].join('\n'),
                        onTap: _openDetails,
                        extra: goal > 0
                            ? Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (stats.tipsNet / goal).clamp(0.0, 1.0),
                                        minHeight: 6,
                                        color: kBrass,
                                        backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Cel ${fmtMoney(goal)}',
                                        style: TextStyle(fontSize: 12, color: muted)),
                                  ],
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        label: 'Godziny',
                        value: fmtDuration(stats.workedMin),
                        caption: stats.remainingMin > 0
                            ? 'jeszcze ${fmtDuration(stats.remainingMin)} w planie'
                            : 'nic więcej w planie',
                        onTap: _openDetails,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (stats.hasRates)
                StatTile(
                  label: 'Zarobki w okresie',
                  value: fmtMoney(stats.total),
                  caption: 'wypłata ${fmtMoney(stats.wages)} + napiwki ${fmtMoney(stats.tipsNet)}',
                  onTap: _openDetails,
                )
              else
                Panel(
                  child: Text(
                    'Ustaw stawkę godzinową przy miejscu pracy w Ustawieniach, aby zobaczyć zarobki.',
                    style: TextStyle(color: muted),
                  ),
                ),
              const SizedBox(height: 12),
              _UpcomingTile(shifts: upcoming, today: today),
            ],
          ),
        );
      },
    );
  }
}

/// Duża karta „Dziś”: bieżąca zmiana z najważniejszą liczbą (przepracowane godziny).
class _TodayCard extends StatelessWidget {
  final Shift? shift;
  final DateTime now;
  final Shift? next;
  const _TodayCard({required this.shift, required this.now, required this.next});

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(now);
    final dateText = toBeginningOfSentenceCase(DateFormat('EEEE, d MMMM', 'pl').format(now))!;
    final s = shift;

    String label = dateText;
    String big;
    double bigSize = 46;
    String bigCaption = '';
    String? range;
    String status;
    Color statusColor = _onTealMuted;
    double? progress;
    VoidCallback onTap;
    VoidCallback? onLongPress;

    if (s == null) {
      big = 'Dziś wolne';
      bigSize = 38;
      final n = next;
      status = n == null
          ? 'Brak zaplanowanych zmian. Dotknij, aby dodać zmianę.'
          : 'Najbliższa zmiana: ${_dayLabel(n.date, today)}, ${fmtTimeRange(n.startMin, n.endMin)} (${fmtDuration(n.durationMin)})';
      onTap = () => openShiftForm(context, date: today);
    } else {
      final place = store.workplaceName(s.workplaceId);
      final when = sameDay(s.date, today) ? 'DZIŚ' : 'WCZORAJ';
      label = '$when · $place';
      range = fmtTimeRange(s.startMin, s.endMin);
      final phase = phaseOf(s, now);
      final elapsed = elapsedMin(s, now);
      final tip = s.tipId == null ? null : store.tipById(s.tipId!);
      if (phase == ShiftPhase.upcoming) {
        big = fmtDuration(s.durationMin);
        bigCaption = 'zaplanowana zmiana';
        final toStart = (s.start.difference(now).inSeconds / 60).ceil();
        status = 'Zaczyna się za ${fmtDuration(toStart < 1 ? 1 : toStart)}';
      } else if (phase == ShiftPhase.ongoing) {
        big = fmtDuration(elapsed);
        bigCaption = 'przepracowane dzisiaj';
        progress = s.durationMin > 0 ? elapsed / s.durationMin : null;
        status = 'Zostało ${fmtDuration(s.durationMin - elapsed)}, do ${fmtTime(s.endMin)}';
      } else {
        big = fmtDuration(s.durationMin);
        bigCaption = 'przepracowane dzisiaj';
        if (s.isDone) {
          final ph = tip?.perHour;
          final pct = tip?.tipPercent;
          status = tip == null
              ? 'Napiwki wpisane'
              : 'Napiwki netto ${fmtMoney(tip.net)}${ph != null ? ' · ${fmtMoney(ph.round())}/h' : ''}${pct != null ? ' · ${fmtPercent(pct)} utargu' : ''}';
        } else {
          status = 'Dotknij, aby wpisać napiwki';
          statusColor = _gold;
        }
      }
      onTap = () => openShiftDefault(context, s);
      onLongPress = () => showShiftOptions(context, s);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(18)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _onTealMuted, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (range != null)
                      Text(
                        range,
                        style: const TextStyle(
                          color: _onTeal,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFeatures: tabular,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    big,
                    style: TextStyle(
                      color: _onTeal,
                      fontSize: bigSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      fontFeatures: tabular,
                    ),
                  ),
                ),
                if (bigCaption.isNotEmpty)
                  Text(bigCaption, style: const TextStyle(color: _onTealMuted, fontSize: 14)),
                if (progress != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      color: kBrass,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Licznik do wypłaty: pojawia się tydzień przed wypłatą.
class _PaydayTile extends StatelessWidget {
  final int days;
  final DateTime date;
  const _PaydayTile({required this.days, required this.date});

  @override
  Widget build(BuildContext context) {
    final big = days == 0
        ? 'Dziś wypłata!'
        : (days == 1 ? 'Jutro wypłata!' : 'Za ${fmtDays(days)}');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: kBrass, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Icon(Icons.payments_outlined, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Do wypłaty', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text(
                  big,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  toBeginningOfSentenceCase(DateFormat('EEEE, d MMMM', 'pl').format(date))!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Najbliższe zmiany: dotknięcie otwiera, przytrzymanie daje opcje, przesunięcie usuwa.
class _UpcomingTile extends StatelessWidget {
  final List<Shift> shifts;
  final DateTime today;
  const _UpcomingTile({required this.shifts, required this.today});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Panel(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('Najbliższe zmiany', style: TextStyle(fontSize: 13, color: muted)),
          ),
          if (shifts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Brak zaplanowanych zmian. Dodasz je w zakładce Grafik.',
                  style: TextStyle(color: muted)),
            )
          else
            for (final s in shifts)
              ShiftDismissible(
                shift: s,
                child: InkWell(
                  onTap: () => openShiftDefault(context, s),
                  onLongPress: () => showShiftOptions(context, s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 78,
                          child: Text(
                            _dayLabel(s.date, today),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fmtTimeRange(s.startMin, s.endMin),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: tabular,
                                ),
                              ),
                              Text(store.workplaceName(s.workplaceId),
                                  style: TextStyle(fontSize: 13, color: muted)),
                            ],
                          ),
                        ),
                        Text(
                          fmtDuration(s.durationMin),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
