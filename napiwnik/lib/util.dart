import 'package:intl/intl.dart';

String fmtMoney(int grosze) {
  final neg = grosze < 0;
  final a = grosze.abs();
  final zl = NumberFormat.decimalPattern('pl').format(a ~/ 100);
  final gr = (a % 100).toString().padLeft(2, '0');
  return '${neg ? '-' : ''}$zl,$gr zł';
}

String fmtInput(int grosze) =>
    grosze == 0 ? '' : (grosze / 100).toStringAsFixed(2).replaceAll('.', ',');

/// Pusty tekst = 0. Zwraca null przy błędnej wartości.
int? parseMoney(String s) {
  final t = s.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (t.isEmpty) return 0;
  final d = double.tryParse(t);
  if (d == null || d < 0) return null;
  return (d * 100).round();
}

double? parseHours(String s) {
  final t = s.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  final d = double.tryParse(t);
  if (d == null || d <= 0 || d > 48) return null;
  return d;
}

const weekdayShort = ['Pn', 'Wt', 'Śr', 'Cz', 'Pt', 'So', 'Nd'];
