import 'package:flutter/material.dart';

import 'dates.dart';
import 'models.dart';
import 'planning.dart';
import 'theme.dart';
import 'util.dart';

/// Pasek „‹  Listopad 2026  ›” wspólny dla Dziennika, Statystyk i Grafiku.
/// Przycisk z wartością null jest wyłączony.
class PeriodSwitcher extends StatelessWidget {
  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onTap; // dotknięcie etykiety, np. skok do „dziś”

  const PeriodSwitcher({
    super.key,
    required this.label,
    this.onPrev,
    this.onNext,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Wstecz',
        ),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Dalej',
        ),
      ],
    );
  }
}

/// Wybór godziny w formacie 24 h. Zwraca minuty od północy albo null po anulowaniu.
Future<int?> pickTimeMin(BuildContext context, int initial, {String? help}) async {
  final t = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initial ~/ 60, minute: initial % 60),
    helpText: help,
    builder: (ctx, child) => MediaQuery(
      data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
      child: child!,
    ),
  );
  return t == null ? null : t.hour * 60 + t.minute;
}

/// Dwa przyciski „Od / Do” i wyraźna informacja o liczbie godzin.
class TimeRangeField extends StatelessWidget {
  final TimeRange range;
  final ValueChanged<TimeRange> onChanged;
  const TimeRangeField({super.key, required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final m = await pickTimeMin(context, range.start, help: 'Początek zmiany');
                if (m != null && context.mounted) onChanged(TimeRange(m, range.end));
              },
              icon: const Icon(Icons.login),
              label: Text('Od ${fmtTime(range.start)}'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final m = await pickTimeMin(context, range.end, help: 'Koniec zmiany');
                if (m != null && context.mounted) onChanged(TimeRange(range.start, m));
              },
              icon: const Icon(Icons.logout),
              label: Text('Do ${fmtTime(range.end)}'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          range.valid
              ? 'Czas pracy: ${fmtDuration(range.minutes)}${range.end < range.start ? ' (do następnego dnia)' : ''}'
              : 'Początek i koniec zmiany nie mogą być takie same.',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: range.valid ? null : s.error,
          ),
        ),
      ],
    );
  }
}

/// Kalendarz miesiąca (tydzień od poniedziałku). W komórce: numer dnia, suma godzin zmian
/// i kropki zmian (turkusowa = zaplanowana, złota = napiwki wpisane).
/// [selected] to dni zaznaczone w trybie wyboru, [focused] to podświetlony dzień w trybie przeglądania.
class MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime today;
  final Set<DateTime> selected;
  final DateTime? focused;
  final List<Shift> Function(DateTime day) shiftsOn;
  final ValueChanged<DateTime> onTap;

  const MonthGrid({
    super.key,
    required this.month,
    required this.today,
    required this.shiftsOn,
    required this.onTap,
    this.selected = const {},
    this.focused,
  });

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final first = monthStart(month);
    final offset = first.weekday - 1;
    final days = daysInMonth(first);
    final rows = ((offset + days) / 7).ceil();

    Widget cell(int dayNum) {
      if (dayNum < 1 || dayNum > days) return const SizedBox(height: 60);
      final date = DateTime(first.year, first.month, dayNum);
      final shifts = shiftsOn(date);
      final isToday = sameDay(date, today);
      final isSel = selected.contains(date);
      final isFocus = focused != null && sameDay(focused!, date);
      final fg = isSel ? Colors.white : s.onSurface;
      final totalMin = shifts.fold<int>(0, (a, x) => a + x.durationMin);
      return InkWell(
        onTap: () => onTap(date),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 56,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSel ? kTeal : null,
            borderRadius: BorderRadius.circular(10),
            border: (isFocus || isToday)
                ? Border.all(color: isFocus ? kTeal : kBrass, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNum',
                style: TextStyle(
                  fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                  color: fg,
                ),
              ),
              if (shifts.isNotEmpty) ...[
                Text(
                  fmtHoursShort(totalMin),
                  style: TextStyle(fontSize: 10, color: fg.withOpacity(0.85)),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final x in shifts.take(3))
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSel ? Colors.white : (x.isDone ? kBrass : kTeal),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [
          for (final n in weekdayShort)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(n, style: TextStyle(fontSize: 12, color: s.onSurfaceVariant)),
                ),
              ),
            ),
        ]),
        for (var r = 0; r < rows; r++)
          Row(children: [
            for (var c = 0; c < 7; c++) Expanded(child: cell(r * 7 + c - offset + 1)),
          ]),
      ],
    );
  }
}
