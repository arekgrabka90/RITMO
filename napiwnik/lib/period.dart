import 'dart:math';

import 'package:intl/intl.dart';

import 'dates.dart';

/// Jak często jest okres rozliczeniowy.
enum PeriodType { weekly, biweekly, monthly }

String periodTypeName(PeriodType t) {
  switch (t) {
    case PeriodType.weekly:
      return 'Co tydzień';
    case PeriodType.biweekly:
      return 'Co dwa tygodnie';
    case PeriodType.monthly:
      return 'Co miesiąc (kalendarzowy)';
  }
}

/// Okres rozliczeniowy: [start] to pierwszy, a [end] ostatni dzień (włącznie).
class BillingPeriod {
  final DateTime start;
  final DateTime end;
  const BillingPeriod(this.start, this.end);

  int get days => daysBetween(start, end) + 1;

  bool contains(DateTime d) {
    final x = dateOnly(d);
    return !x.isBefore(start) && !x.isAfter(end);
  }

  /// Ile dni zostało do końca okresu, liczcąc dzisiejszy (ostatni dzień = 1, po okresie = 0).
  int daysLeft(DateTime today) {
    final n = daysBetween(dateOnly(today), end) + 1;
    return n < 0 ? 0 : n;
  }
}

/// Okres, do którego należy [day]. Miesięczny = miesiąc kalendarzowy. Tygodniowy i dwutygodniowy
/// liczone są co 7 albo 14 dni od [anchor] (pierwszego dnia dowolnego okresu).
BillingPeriod periodFor(DateTime day, PeriodType type, DateTime anchor) {
  final d = dateOnly(day);
  if (type == PeriodType.monthly) {
    final s = monthStart(d);
    return BillingPeriod(s, DateTime(s.year, s.month, daysInMonth(s)));
  }
  final len = type == PeriodType.weekly ? 7 : 14;
  final a = dateOnly(anchor);
  final diff = daysBetween(a, d);
  final k = (diff - (diff % len)) ~/ len; // dzielenie z zaokrągleniem w dół (też dla dat sprzed [anchor])
  final start = addDays(a, k * len);
  return BillingPeriod(start, addDays(start, len - 1));
}

BillingPeriod previousPeriod(BillingPeriod p, PeriodType type, DateTime anchor) =>
    periodFor(addDays(p.start, -1), type, anchor);

BillingPeriod nextPeriod(BillingPeriod p, PeriodType type, DateTime anchor) =>
    periodFor(addDays(p.end, 1), type, anchor);

/// "10.11–23.11" (z latami, gdy okres przechodzi przez Nowy Rok).
String periodRangeLabel(BillingPeriod p) {
  final f = DateFormat('d.MM', 'pl');
  final fy = DateFormat('d.MM.y', 'pl');
  if (p.start.year != p.end.year) return '${fy.format(p.start)}–${fy.format(p.end)}';
  return '${f.format(p.start)}–${f.format(p.end)}';
}

/// Najbliższa wypłata (dzisiejsza też się liczy), gdy wypłata jest co miesiąc w dniu [dayOfMonth].
/// W krótszych miesiącach przypada na ostatni dzień miesiąca (np. 31 w listopadzie = 30.11).
/// Zwraca null, gdy [dayOfMonth] to nie 1–31 (brak ustawionej wypłaty).
DateTime? nextPayday(DateTime today, int dayOfMonth) {
  if (dayOfMonth < 1 || dayOfMonth > 31) return null;
  DateTime inMonth(DateTime m) =>
      DateTime(m.year, m.month, min(dayOfMonth, daysInMonth(m)));
  final t = dateOnly(today);
  final thisMonth = inMonth(monthStart(t));
  return thisMonth.isBefore(t) ? inMonth(addMonths(monthStart(t), 1)) : thisMonth;
}

/// Ile dni do najbliższej wypłaty (0 = dzisiaj), null gdy wypłata nie jest ustawiona.
int? daysToPayday(DateTime today, int dayOfMonth) {
  final next = nextPayday(today, dayOfMonth);
  return next == null ? null : daysBetween(dateOnly(today), next);
}

/// Najbliższa wypłata, gdy przychodzi [offsetDays] dni po końcu okresu rozliczeniowego (0 = w ostatnim
/// dniu okresu). Dzisiejsza też się liczy. Wypłata za któryś z poprzednich okresów może przypadać
/// dopiero dzisiaj lub później (przy długim opóźnieniu), więc sprawdzamy kilka okresów wstecz.
/// Zwraca null, gdy [offsetDays] nie jest z zakresu 0–14.
DateTime? nextPaydayAfterPeriod(
  DateTime today,
  PeriodType type,
  DateTime anchor,
  int offsetDays,
) {
  if (offsetDays < 0 || offsetDays > 14) return null;
  final t = dateOnly(today);
  var p = periodFor(t, type, anchor);
  for (var i = 0; i < 4; i++) {
    p = previousPeriod(p, type, anchor);
  }
  for (var i = 0; i < 12; i++) {
    final pay = addDays(p.end, offsetDays);
    if (!pay.isBefore(t)) return pay;
    p = nextPeriod(p, type, anchor);
  }
  return null;
}
