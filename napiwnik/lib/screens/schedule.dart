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
import 'shift_form.dart';

enum ScheduleView { week, month }

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  ScheduleView _view = ScheduleView.week;
  late DateTime _week = weekStart(dateOnly(DateTime.now()));
  late DateTime _month = monthStart(DateTime.now());
  late DateTime _focus = dateOnly(DateTime.now());

  DateTime _defaultFocus(DateTime m) {
    final t = dateOnly(DateTime.now());
    return sameMonth(t, m) ? t : m;
  }

  void _move(int dir) => setState(() {
        if (_view == ScheduleView.week) {
          _week = addDays(_week, 7 * dir);
          _focus = addDays(_focus, 7 * dir);
        } else {
          _month = addMonths(_month, dir);
          _focus = _defaultFocus(_month);
        }
      });

  void _goToday() => setState(() {
        final t = dateOnly(DateTime.now());
        _week = weekStart(t);
        _month = monthStart(t);
        _focus = t;
      });

  Future<void> _plan() async {
    final messenger = ScaffoldMessenger.of(context);
    final week = _view == ScheduleView.week;
    final result = await Navigator.of(context).push<BulkResult>(
      MaterialPageRoute(
        builder: (_) => BulkPlanScreen(
          mode: week ? BulkMode.week : BulkMode.month,
          anchor: week ? _week : _month,
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final today = dateOnly(DateTime.now());
        final week = _view == ScheduleView.week;
        final weekEnd = addDays(_week, 6);
        final inRange = store.visibleShifts.where((s) => week
            ? (!s.date.isBefore(_week) && !s.date.isAfter(weekEnd))
            : sameMonth(s.date, _month));
        final count = inRange.length;
        final totalMin = inRange.fold<int>(0, (a, s) => a + s.durationMin);
        final muted = Theme.of(context).colorScheme.onSurfaceVariant;

        return Scaffold(
          appBar: AppBar(title: const Text('Grafik')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _plan,
            icon: const Icon(Icons.event_available),
            label: Text(week ? 'Zaplanuj tydzień' : 'Zaplanuj miesiąc'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
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
                onSelectionChanged: (s) => setState(() {
                  final v = s.first;
                  if (v == ScheduleView.week) {
                    _week = weekStart(_focus);
                  } else {
                    _month = monthStart(_focus);
                  }
                  _view = v;
                }),
              ),
              const SizedBox(height: 4),
              PeriodSwitcher(
                label: week ? weekTitle(_week) : monthTitle(_month),
                onPrev: () => _move(-1),
                onNext: () => _move(1),
                onTap: _goToday,
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
                for (final d in weekDays(_week)) _DayCard(day: d, today: today)
              else ...[
                MonthGrid(
                  month: _month,
                  today: today,
                  focused: _focus,
                  shiftsOn: store.shiftsOn,
                  onTap: (d) => setState(() => _focus = d),
                ),
                const SizedBox(height: 12),
                _DayCard(day: _focus, today: today),
              ],
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
  const _DayCard({required this.day, required this.today});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final isToday = sameDay(day, today);
    final shifts = store.shiftsOn(day);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  toBeginningOfSentenceCase(DateFormat('EEEE, d MMMM', 'pl').format(day))!,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isToday ? kBrass : null,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Dodaj zmianę',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => openShiftForm(context, date: day),
            ),
          ],
        ),
        if (shifts.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text('Wolne', style: TextStyle(color: s.onSurfaceVariant)),
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
      status = Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonalIcon(
          onPressed: () => openForm(context, shift: shift),
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Uzupełnij napiwki'),
        ),
      );
    } else {
      status = Text('Zaplanowana, jeszcze się nie odbyła', style: muted);
    }

    return Dismissible(
      key: ValueKey('shift-${shift.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: s.errorContainer, borderRadius: BorderRadius.circular(14)),
        child: Icon(Icons.delete_outline, color: s.onErrorContainer),
      ),
      onDismissed: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final ok = await store.deleteShift(shift);
        messenger.clearSnackBars();
        if (!ok) {
          messenger.showSnackBar(const SnackBar(content: Text('Nie udało się usunąć zmiany.')));
          return;
        }
        messenger.showSnackBar(SnackBar(
          content: const Text('Usunięto zmianę'),
          action: SnackBarAction(
            label: 'Cofnij',
            onPressed: () async {
              try {
                await store.addShift(shift.asNew());
              } catch (_) {
                messenger.showSnackBar(
                    const SnackBar(content: Text('Nie udało się cofnąć usunięcia.')));
              }
            },
          ),
        ));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => openShiftForm(context, shift: shift),
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
