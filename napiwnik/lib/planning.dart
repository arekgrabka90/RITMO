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

/// Szablon zmiany (np. „Lunch 10:00–16:00”): dotknięcie ustawia godziny w formularzu zmiany
/// i w planowaniu tygodnia lub miesiąca.
class ShiftTemplate {
  final String name;
  final int start;
  final int end;
  const ShiftTemplate(this.name, this.start, this.end);

  TimeRange get range => TimeRange(start, end);

  bool get valid => name.trim().isNotEmpty && range.valid;

  Map<String, Object?> toMap() => {'name': name, 'start': start, 'end': end};

  /// Łagodny odczyt: zły albo niepełny wpis daje null.
  static ShiftTemplate? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final n = raw['name'];
    final s = raw['start'];
    final e = raw['end'];
    if (n is! String || s is! int || e is! int) return null;
    final t = ShiftTemplate(n.trim(), s, e);
    return t.valid ? t : null;
  }
}

/// Czy dwie zmiany zachodzą na siebie w czasie (zmiana kończąca się dokładnie wtedy, gdy druga
/// się zaczyna, nie nakłada się).
bool shiftsOverlap(Shift a, Shift b) => a.start.isBefore(b.end) && b.start.isBefore(a.end);

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

/// Kopiuje zmiany z tygodnia zaczynającego się w [weekStartDate] na tydzień później (bez wpisów
/// napiwków). Dni, które w następnym tygodniu mają już jakąś zmianę ([existing]), są pomijane.
BulkPlan copyWeekPlan({
  required DateTime weekStartDate,
  required List<Shift> source,
  required List<Shift> existing,
}) {
  final end = addDays(weekStartDate, 6);
  final list = source
      .where((s) => !s.date.isBefore(weekStartDate) && !s.date.isAfter(end))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  final add = <Shift>[];
  final skipped = <DateTime>{};
  for (final s in list) {
    final target = addDays(s.date, 7);
    if (existing.any((x) => sameDay(x.date, target))) {
      skipped.add(target);
      continue;
    }
    add.add(Shift(
      workplaceId: s.workplaceId,
      date: target,
      startMin: s.startMin,
      endMin: s.endMin,
      note: s.note,
    ));
  }
  return BulkPlan(add: add, replace: const [], skippedDays: skipped.length);
}
