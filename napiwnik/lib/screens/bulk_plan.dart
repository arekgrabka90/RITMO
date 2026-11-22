import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dates.dart';
import '../planning.dart';
import '../store.dart';
import '../theme.dart';
import '../util.dart';
import '../widgets.dart';

enum BulkMode { week, month }

/// Planowanie wielu zmian naraz: zaznaczasz dni (tydzień albo miesiąc), ustawiasz godziny
/// wspólne dla wszystkich i ewentualnie poprawiasz pojedyncze dni (godziny niestandardowe).
class BulkPlanScreen extends StatefulWidget {
  final BulkMode mode;
  final DateTime anchor; // poniedziałek tygodnia albo pierwszy dzień miesiąca
  const BulkPlanScreen({super.key, required this.mode, required this.anchor});

  @override
  State<BulkPlanScreen> createState() => _BulkPlanScreenState();
}

class _BulkPlanScreenState extends State<BulkPlanScreen> {
  final Set<DateTime> _days = {};
  final Map<DateTime, TimeRange> _own = {};
  late TimeRange _default = store.lastRange;
  int? _wid;
  Conflict _conflict = Conflict.skip;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _wid = store.filterId ??
        (store.workplaces.length == 1 ? store.workplaces.first.id : null);
  }

  BulkPlan _plan() => buildBulkPlan(
        days: _days,
        defaultRange: _default,
        overrides: _own,
        workplaceId: _wid,
        existing: store.shifts,
        conflict: _conflict,
      );

  void _toast(String m) => ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(content: Text(m)));

  void _setDays(Iterable<DateTime> ds) => setState(() {
        _days
          ..clear()
          ..addAll(ds);
        _own.removeWhere((k, _) => !_days.contains(k));
      });

  void _toggle(DateTime d) => setState(() {
        if (_days.contains(d)) {
          _days.remove(d);
          _own.remove(d);
        } else {
          _days.add(d);
        }
      });

  void _toggleWeekday(int weekday) {
    final ds = daysOfWeekdayInMonth(widget.anchor, weekday);
    final all = ds.every(_days.contains);
    setState(() {
      if (all) {
        for (final d in ds) {
          _days.remove(d);
          _own.remove(d);
        }
      } else {
        _days.addAll(ds);
      }
    });
  }

  Future<void> _editDay(DateTime d) async {
    final cur = _own[d] ?? _default;
    final s = await pickTimeMin(context, cur.start, help: 'Początek zmiany: ${DateFormat('d.MM', 'pl').format(d)}');
    if (s == null || !mounted) return;
    final e = await pickTimeMin(context, cur.end, help: 'Koniec zmiany: ${DateFormat('d.MM', 'pl').format(d)}');
    if (e == null || !mounted) return;
    if (s == e) {
      _toast('Początek i koniec zmiany nie mogą być takie same.');
      return;
    }
    final r = TimeRange(s, e);
    setState(() {
      if (r == _default) {
        _own.remove(d);
      } else {
        _own[d] = r;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final plan = _plan();
    if (plan.add.isEmpty) {
      _toast('Wszystkie zaznaczone dni mają już zmianę. Wybierz „Dodaj obok” albo „Zastąp”.');
      return;
    }
    setState(() => _saving = true);
    try {
      final result = await store.applyBulk(add: plan.add, replace: plan.replace);
      await store.setLastRange(_default);
      if (mounted) Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Nie udało się zapisać zmian. Spróbuj ponownie.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final isWeek = widget.mode == BulkMode.week;
    final today = dateOnly(DateTime.now());
    final plan = _plan();
    final sorted = _days.toList()..sort();
    final totalMin = sorted.fold<int>(0, (sum, d) => sum + (_own[d] ?? _default).minutes);
    final clash = sorted.where((d) => store.shifts.any((x) => sameDay(x.date, d))).length;

    return Scaffold(
      appBar: AppBar(title: Text(isWeek ? 'Zaplanuj tydzień' : 'Zaplanuj miesiąc')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: (_saving || _days.isEmpty || !_default.valid) ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: Text(plan.add.isEmpty ? 'Zapisz' : 'Zapisz ${fmtShiftCount(plan.add.length)}'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            isWeek ? weekTitle(widget.anchor) : monthTitle(widget.anchor),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            isWeek
                ? 'Zaznacz dni, w które pracujesz.'
                : 'Dotknij dni w kalendarzu albo wybierz dzień tygodnia, żeby zaznaczyć go w całym miesiącu.',
            style: TextStyle(color: s.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (isWeek) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final d in weekDays(widget.anchor))
                  FilterChip(
                    label: Text('${weekdayShort[d.weekday - 1]} ${d.day}'),
                    selected: _days.contains(d),
                    onSelected: (_) => _toggle(d),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Pn–Pt'),
                  onPressed: () => _setDays(weekDays(widget.anchor).take(5)),
                ),
                ActionChip(
                  label: const Text('Cały tydzień'),
                  onPressed: () => _setDays(weekDays(widget.anchor)),
                ),
                ActionChip(label: const Text('Wyczyść'), onPressed: () => _setDays(const [])),
              ],
            ),
          ] else ...[
            MonthGrid(
              month: widget.anchor,
              today: today,
              selected: _days,
              shiftsOn: (d) => store.shifts.where((x) => sameDay(x.date, d)).toList(),
              onTap: _toggle,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var wd = 1; wd <= 7; wd++)
                  FilterChip(
                    label: Text(weekdayShort[wd - 1]),
                    selected: () {
                      final ds = daysOfWeekdayInMonth(widget.anchor, wd);
                      return ds.isNotEmpty && ds.every(_days.contains);
                    }(),
                    onSelected: (_) => _toggleWeekday(wd),
                  ),
                ActionChip(label: const Text('Wyczyść'), onPressed: () => _setDays(const [])),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (store.workplaces.isNotEmpty) ...[
            DropdownButtonFormField<int?>(
              value: _wid,
              decoration: const InputDecoration(labelText: 'Miejsce pracy'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('Bez miejsca')),
                for (final w in store.workplaces)
                  DropdownMenuItem<int?>(value: w.id, child: Text(w.name)),
              ],
              onChanged: (v) => setState(() => _wid = v),
            ),
            const SizedBox(height: 16),
          ],
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Godziny dla wszystkich zaznaczonych dni',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TimeRangeField(
                  range: _default,
                  onChanged: (r) => setState(() => _default = r),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (sorted.isEmpty)
            Text('Nie zaznaczono żadnego dnia.', style: TextStyle(color: s.onSurfaceVariant))
          else ...[
            Text(
              'Wybrane dni: ${sorted.length}${_default.valid ? ' · razem ${fmtDuration(totalMin)}' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Dotknij dnia, żeby ustawić dla niego inne godziny.',
                style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 8),
            for (final d in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _editDay(d),
                  child: Panel(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 76,
                          child: Text(
                            '${weekdayShort[d.weekday - 1]} ${DateFormat('d.MM', 'pl').format(d)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(() {
                                final r = _own[d] ?? _default;
                                return '${fmtTimeRange(r.start, r.end)} · ${fmtDuration(r.minutes)}';
                              }()),
                              if (_own.containsKey(d))
                                const Text('własne godziny',
                                    style: TextStyle(fontSize: 12, color: kBrass)),
                            ],
                          ),
                        ),
                        if (_own.containsKey(d))
                          IconButton(
                            tooltip: 'Użyj godzin domyślnych',
                            icon: const Icon(Icons.undo),
                            onPressed: () => setState(() => _own.remove(d)),
                          ),
                        IconButton(
                          tooltip: 'Usuń dzień',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _days.remove(d);
                            _own.remove(d);
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
          if (clash > 0) ...[
            const SizedBox(height: 8),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clash == 1
                        ? '1 wybrany dzień ma już zmianę. Co z nim zrobić?'
                        : '$clash wybranych dni ma już zmianę. Co z nimi zrobić?',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<Conflict>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: Conflict.skip, label: Text('Pomiń')),
                      ButtonSegment(value: Conflict.add, label: Text('Dodaj obok')),
                      ButtonSegment(value: Conflict.replace, label: Text('Zastąp')),
                    ],
                    selected: {_conflict},
                    onSelectionChanged: (v) => setState(() => _conflict = v.first),
                  ),
                  if (_conflict == Conflict.replace) ...[
                    const SizedBox(height: 8),
                    Text('Zmiany z wpisanymi napiwkami zostają.',
                        style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
                  ],
                  if (plan.skippedDays > 0) ...[
                    const SizedBox(height: 8),
                    Text('Pominięto dni: ${plan.skippedDays}.',
                        style: TextStyle(color: s.onSurfaceVariant, fontSize: 13)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
