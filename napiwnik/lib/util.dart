import 'package:intl/intl.dart';

/// Górny limit pojedynczej kwoty: 1 000 000,00 zł (w groszach).
const maxMoneyGrosze = 100000000;

// Do 9 cyfr złotych, opcjonalnie separator (przecinek lub kropka) i do 2 cyfr groszy.
final _moneyRe = RegExp(r'^(\d{1,9})(?:[.,](\d{0,2}))?$');
final _spaces = RegExp(r'\s');

String fmtMoney(int grosze) {
  final neg = grosze < 0;
  final a = grosze.abs();
  final zl = NumberFormat.decimalPattern('pl').format(a ~/ 100);
  final gr = (a % 100).toString().padLeft(2, '0');
  return '${neg ? '-' : ''}$zl,$gr zł';
}

String fmtInput(int grosze) =>
    grosze == 0 ? '' : (grosze / 100).toStringAsFixed(2).replaceAll('.', ',');

/// Pusty tekst = 0. Zwraca null przy błędnej wartości (litery, minus, więcej niż 2 miejsca po
/// przecinku, kwota powyżej [maxMoneyGrosze]). Parsuje tekst, bez `double`, więc nie ma błędów
/// zaokrągleń ani wartości typu Infinity/NaN.
int? parseMoney(String s) {
  final t = s.replaceAll(_spaces, '');
  if (t.isEmpty) return 0;
  final m = _moneyRe.firstMatch(t);
  if (m == null) return null;
  final zl = int.parse(m.group(1)!);
  final frac = (m.group(2) ?? '').padRight(2, '0');
  final grosze = zl * 100 + int.parse(frac);
  return grosze > maxMoneyGrosze ? null : grosze;
}

double? parseHours(String s) {
  final t = s.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  final d = double.tryParse(t);
  if (d == null || !d.isFinite || d <= 0 || d > 48) return null;
  return d;
}

/// Godziny do wyświetlenia: 8 -> "8", 6.5 -> "6,5", 10.05 -> "10,05".
String fmtHours(double h) {
  if (h == h.roundToDouble()) return h.round().toString();
  return h.toString().replaceAll('.', ',');
}

/// Minuty od północy jako "HH:mm".
String fmtTime(int min) =>
    '${(min ~/ 60).toString().padLeft(2, '0')}:${(min % 60).toString().padLeft(2, '0')}';

/// "16:00–22:00", a dla zmiany kończącej się następnego dnia "22:00–06:00 (+1)".
String fmtTimeRange(int start, int end) =>
    '${fmtTime(start)}–${fmtTime(end)}${end <= start ? ' (+1)' : ''}';

/// Czas pracy czytelnie: "8 h", "7 h 30 min", "45 min".
String fmtDuration(int min) {
  final h = min ~/ 60;
  final m = min % 60;
  if (m == 0) return '$h h';
  if (h == 0) return '$m min';
  return '$h h $m min';
}

/// Krótko do małych komórek kalendarza: "8h", "7,5h".
String fmtHoursShort(int min) => '${fmtHours((min / 60 * 10).round() / 10)}h';

/// "1 zmiana", "2 zmiany", "5 zmian", "22 zmiany".
String fmtShiftCount(int n) {
  final mod10 = n % 10;
  final mod100 = n % 100;
  final word = n == 1
      ? 'zmiana'
      : (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14))
          ? 'zmiany'
          : 'zmian';
  return '$n $word';
}

/// Komórka tekstowa CSV: cudzysłowy są podwajane, a tekst zaczynający się od =, +, -, @,
/// tabulatora lub CR dostaje apostrof z przodu, żeby Excel nie wykonał go jako formuły.
String csvCell(String s) {
  final risky = s.isNotEmpty && '=+-@\t\r'.contains(s[0]);
  final v = risky ? "'$s" : s;
  return '"${v.replaceAll('"', '""')}"';
}

const weekdayShort = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];
