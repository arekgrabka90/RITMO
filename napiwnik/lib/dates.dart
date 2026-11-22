import 'package:intl/intl.dart';

/// Wspólne reguły dat dla całej aplikacji. Wszystkie daty to lokalna północ (bez godzin),
/// a działania na dniach i miesiącach idą przez konstruktor DateTime (odporne na zmianę czasu).

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

DateTime addMonths(DateTime m, int n) => DateTime(m.year, m.month + n, 1);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Poniedziałek tygodnia, do którego należy [d].
DateTime weekStart(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

List<DateTime> weekDays(DateTime start) {
  final monday = weekStart(start);
  return List.generate(7, (index) => addDays(monday, index));
}

int daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// „Listopad 2026”
String monthTitle(DateTime m) =>
    toBeginningOfSentenceCase(DateFormat('LLLL y', 'pl').format(m))!;

/// „16–22 lis 2026”, „30 lis – 6 gru 2026” albo z latami, gdy tydzień przechodzi przez Nowy Rok.
String weekTitle(DateTime start) {
  final end = addDays(start, 6);
  final d = DateFormat('d', 'pl');
  final dm = DateFormat('d MMM', 'pl');
  final dmy = DateFormat('d MMM y', 'pl');
  if (start.year != end.year) return '${dmy.format(start)} – ${dmy.format(end)}';
  if (start.month != end.month) return '${dm.format(start)} – ${dmy.format(end)}';
  return '${d.format(start)}–${dmy.format(end)}';
}
