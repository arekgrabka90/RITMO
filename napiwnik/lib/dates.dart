import 'package:intl/intl.dart';

/// Wspólne reguły dat dla całej aplikacji. Wszystkie daty to lokalna północ (bez godzin),
/// a działania na dniach i miesiącach idą przez konstruktor DateTime (odporne na zmianę czasu).

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime monthStart(DateTime d) => DateTime(d.year, d.month, 1);

DateTime addMonths(DateTime m, int n) => DateTime(m.year, m.month + n, 1);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

/// Pierwszy dzień tygodnia, do którego należy [d]. [startDay] to dzień tygodnia, od którego
/// zaczyna się tydzień (1 = poniedziałek ... 7 = niedziela), domyślnie poniedziałek.
DateTime weekStart(DateTime d, [int startDay = DateTime.monday]) =>
    DateTime(d.year, d.month, d.day - ((d.weekday - startDay + 7) % 7));

int daysInMonth(DateTime m) => DateTime(m.year, m.month + 1, 0).day;

/// Liczba dni od [a] do [b] (ujemna, gdy [b] jest wcześniej). Odporna na zmianę czasu.
int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day)
    .difference(DateTime.utc(a.year, a.month, a.day))
    .inDays;

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool sameMonth(DateTime a, DateTime b) => a.year == b.year && a.month == b.month;

/// "2026-11-05": do zapisu w ustawieniach.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// "5.11"
String shortDate(DateTime d) => DateFormat('d.MM', 'pl').format(d);

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
