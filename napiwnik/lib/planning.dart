import 'dates.dart';
import 'models.dart';

/// Przedział godzin zmiany w minutach od północy. end <= start oznacza zmianę do następnego dnia.
class TimeRange {
  final int start;
  final int end;
  const TimeRange(this.start, this.end);

  bool get valid => start >= 0 && start < 1440 && end >= 0 && end < 1440 && start != end;

  int get minutes => end > start ? end - start : 1440 - start + end;

  @override
  bool operator ==(Object other) => other is TimeRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Co zrobić z dniem, który ma już zmianę: pominąć, dodać drugą obok albo zastąpić.
enum Conflict { skip, add, replace }

class BulkPlan {
  final List<Shift> add;
  final List<Shift> replace; // istniejące zmiany bez wpisanych napiwków, które zostaną usunięte
  final int skippedDays;
  const BulkPlan({required this.add, required this.replace, required this.skippedDays});
}

/// 7 dni od poniedziałku [start].
List<DateTime> weekDays(DateTime start) => [for (var i = 0; i < 7; i++) addDays(start, i)];

/// Wszystkie dni miesiąca o danym dniu tygodnia (1 = poniedziałek ... 7 = niedziela).
List<DateTime> daysOfWeekdayInMonth(DateTime month, int weekday) {
  final first = monthStart(month);
  final n = daysInMonth(first);
  return [
    for (var d = 1; d <= n; d++)
      if (DateTime(first.year, first.month, d).weekday == weekday)
        DateTime(first.year, first.month, d),
  ];
}

/// Zamienia zaznaczone dni na listę zmian do dodania. Dzień bez własnych godzin dostaje
/// [defaultRange], dzień z wpisem w [overrides] dostaje swoje godziny.
/// Zmiany z wpisanymi napiwkami nigdy nie są zastępowane.
BulkPlan buildBulkPlan({
  required Set<DateTime> days,
  required TimeRange defaultRange,
  required Map<DateTime, TimeRange> overrides,
  required int? workplaceId,
  required List<Shift> existing,
  required Conflict conflict,
}) {
  final add = <Shift>[];
  final replace = <Shift>[];
  var skipped = 0;
  final sorted = days.map(dateOnly).toSet().toList()..sort();
  for (final day in sorted) {
    final onDay = existing.where((s) => sameDay(s.date, day)).toList();
    if (onDay.isNotEmpty) {
      if (conflict == Conflict.skip) {
        skipped++;
        continue;
      }
      if (conflict == Conflict.replace) {
        replace.addAll(onDay.where((s) => s.tipId == null));
      }
    }
    final r = overrides[day] ?? defaultRange;
    add.add(Shift(workplaceId: workplaceId, date: day, startMin: r.start, endMin: r.end));
  }
  return BulkPlan(add: add, replace: replace, skippedDays: skipped);
}
