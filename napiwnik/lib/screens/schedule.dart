import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dates.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';
import 'bulk_plan.dart';
import 'home.dart';
import 'shift_actions.dart';
import 'shift_form.dart';

enum ScheduleView { week, month }

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  ScheduleView _view = ScheduleView.week;

  /// Jedyny punkt odniesienia: tydzień i miesiąc są z niego wyliczane (więc zmiana pierwszego
  /// dnia tygodnia w Ustawieniach od razu działa).
  late DateTime _focus = dateOnly(DateTime.now());

  DateTime _defaultFocus(DateTime m) {
    final t = dateOnly(DateTime.now());
    return sameMonth(t, m) ? t : m;
  }

  void _move(int dir) => setState(() {
        if (_view == ScheduleView.week) {
          _focus = addDays(_focus, 7 * dir);
        } else {
          _focus = _defaultFocus(addMonths(monthStart(_focus), dir));
        }
      });

  void _goToday() => setState(() => _focus = dateOnly(DateTime.now()));

  /// Przesunięcie palcem w bok zmienia tydzień albo miesiąc.
  void _swipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v < -300) {
      _move(1);
    } else if (v > 300) {
      _move(-1);
    }
  }

  Future<void> _plan(BulkMode mode, DateTime day) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<BulkResult>(
      MaterialPageRoute(
        builder: (_) => BulkPlanScreen(
          mode: mode,
          anchor: mode == BulkMode.week ? weekStart(day, store.weekStartDay) : monthStart(day),
        ),
      ),
    );
    if (result == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text('Dodano ${fmtShiftCount(result.addedIds.length)}'),
      action: SnackBarAction(
        label: 'Cofnij',
        onPressed: () async {
          try {
            await store.revertBulk(result);
          } catch (_) {
            messenger.showSnackBar(const SnackBar(content: Text('Nie udało się cofnąć zmian.')));
          }
        },
      ),
    ));
  }

  /// Przytrzymanie dnia: dodanie zmiany albo planowanie tygodnia lub miesiąca.
  void _dayOptions(DateTime day) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  toBeginningOfSentenceCase(DateFormat('EEEE, d MMMM', 'pl').format(day))!,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Dodaj zmianę'),
              onTap: () {
                Navigator.pop(ctx);
                openShiftForm(context, date: day);
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_week_outlined),
              title: const Text('Zaplanuj tydzień'),
              onTap: () {
                Navigator.pop(ctx);
                _plan(BulkMode.week, day);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Zaplanuj miesiąc'),
              onTap: () {
                Navigator.pop(ctx);
                _plan(BulkMode.month, day);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final today = dateOnly(DateTime.now());
        final week = _view == ScheduleView.week;
        final startDay = store.weekStartDay;
        final wk = weekStart(_focus, startDay);
        final wkEnd = addDays(wk, 6);
        final month = monthStart(_focus);
        final inRange = store.visibleShifts.where((s) => week
            ? (!s.date.isBefore(wk) && !s.date.isAfter(wkEnd))
            : sameMonth(s.date, month));
        final count = inRange.length;
        final totalMin = inRange.fold<int>(0, (a, s) => a + s.durationMin);
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;

        return Scaffold(
          appBar: AppBar(title: const Text('Grafik')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              const WorkplaceChips(),
              const SizedBox(height: 12),
              SegmentedButton<ScheduleView>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ScheduleView.week, label: Text('Tydzień')),
                  ButtonSegment(value: ScheduleView.month, label: Text('Miesiąc')),
                ],
                selected: {_view},
                onSelectionChanged: (s) => setState(() => _view = s.first),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragEnd: _swipe,
                child: PeriodSwitcher(
                  label: week ? weekTitle(wk) : monthTitle(month),
                  onPrev: () => _move(-1),
                  onNext: () => _move(1),
                  onTap: _goToday,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  count == 0
                      ? 'Brak zaplanowanych zmian'
                      : '${fmtShiftCount(count)} · razem ${fmtDuration(totalMin)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, color: muted),
                ),
              ),
              if (week)
                for (final d in weekDays(wk))
                  _DayCard(day: d, today: today, onOptions: _dayOptions)
              else ...[
                GestureDetector(
                  onHorizontalDragEnd: _swipe,
                  child: MonthGrid(
                    month: month,
                    today: today,
                    focused: _focus,
                    weekStartDay: startDay,
                    shiftsOn: store.shiftsOn,
                    onTap: (d) => setState(() => _focus = d),
                    onLongPress: _dayOptions,
                  ),
                ),
                const SizedBox(height: 12),
                _DayCard(day: _focus, today: today, onOptions: _dayOptions),
              ],
              const SizedBox(height: 8),
              Text(
                'Dotknij „Wolne”, aby dodać zmianę. Przytrzymaj dzień, aby zaplanować tydzień lub miesiąc. Przytrzymaj zmianę, aby zobaczyć opcje, a przesuń ją w lewo, aby usunąć.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final DateTime today;
  final ValueChanged<DateTime> onOptions;
  const _DayCard({required this.day, required this.today, required this.onOptions});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final isToday = sameDay(day, today);
    final shifts = store.shiftsOn(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onLongPress: () => onOptions(day),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Text(
              toBeginningOfSentenceCase(DateFormat('EEEE, d MMMM', 'pl').format(day))!,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isToday ? kBrass : null,
              ),
            ),
          ),
        ),
        if (shifts.isEmpty)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => openShiftForm(context, date: day),
            onLongPress: () => onOptions(day),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text('Wolne', style: TextStyle(color: s.onSurfaceVariant)),
            ),
          )
        else
          for (final sh in shifts) _ShiftTile(shift: sh),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _ShiftTile extends StatelessWidget {
  final Shift shift;
  const _ShiftTile({required this.shift});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final muted = TextStyle(color: s.onSurfaceVariant, fontSize: 13);
    final tip = shift.tipId == null ? null : store.tipById(shift.tipId!);
    final ended = shift.hasEnded(DateTime.now());
    final place = store.workplaceName(shift.workplaceId);

    Widget status;
    if (shift.isDone) {
      status = Row(children: [
        Icon(Icons.check_circle, size: 18, color: s.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            tip == null ? 'Napiwki wpisane' : 'Napiwki wpisane: netto ${fmtMoney(tip.net)}',
            style: TextStyle(color: s.primary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ]);
    } else if (ended) {
      status = const Text(
        'Dotknij, aby wpisać napiwki',
        style: TextStyle(color: kBrass, fontWeight: FontWeight.w700, fontSize: 13),
      );
    } else {
      status = Text('Zaplanowana, jeszcze się nie odbyła', style: muted);
    }

    return ShiftDismissible(
      shift: shift,
      backgroundMargin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => openShiftDefault(context, shift),
          onLongPress: () => showShiftOptions(context, shift),
          child: Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        fmtTimeRange(shift.startMin, shift.endMin),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFeatures: tabular),
                      ),
                    ),
                    Text(
                      fmtDuration(shift.durationMin),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(shift.note.isEmpty ? place : '$place · ${shift.note}', style: muted),
                const SizedBox(height: 8),
                status,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
