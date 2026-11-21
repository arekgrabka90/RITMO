import 'package:intl/intl.dart';

import 'models.dart';
import 'util.dart';

class Bucket {
  final String label;
  final double value; // w złotych
  const Bucket(this.label, this.value);
}

/// Suma netto na każdy z ostatnich [days] dni (kończąc na [today]).
List<Bucket> dailyBuckets(List<Tip> tips, DateTime today, int days, {required bool weekdayLabels}) {
  final sums = <DateTime, int>{};
  for (final t in tips) {
    final k = DateTime(t.date.year, t.date.month, t.date.day);
    sums[k] = (sums[k] ?? 0) + t.net;
  }
  final start = DateTime(today.year, today.month, today.day - (days - 1));
  return [
    for (var i = 0; i < days; i++)
      () {
        final d = DateTime(start.year, start.month, start.day + i);
        final label = weekdayLabels ? weekdayShort[d.weekday - 1] : '${d.day}';
        return Bucket(label, (sums[d] ?? 0) / 100);
      }(),
  ];
}

/// Suma netto na każdy z ostatnich [months] miesięcy (kończąc na miesiącu [today]).
List<Bucket> monthlyBuckets(List<Tip> tips, DateTime today, int months) {
  final sums = <int, int>{};
  for (final t in tips) {
    final k = t.date.year * 12 + t.date.month - 1;
    sums[k] = (sums[k] ?? 0) + t.net;
  }
  return [
    for (var i = months - 1; i >= 0; i--)
      () {
        final m = DateTime(today.year, today.month - i, 1);
        final k = m.year * 12 + m.month - 1;
        return Bucket(DateFormat('LLL', 'pl').format(m), (sums[k] ?? 0) / 100);
      }(),
  ];
}

/// Suma netto na każdy rok od najstarszego wpisu do roku [today].
List<Bucket> yearlyBuckets(List<Tip> tips, DateTime today) {
  final sums = <int, int>{};
  var first = today.year;
  for (final t in tips) {
    sums[t.date.year] = (sums[t.date.year] ?? 0) + t.net;
    if (t.date.year < first) first = t.date.year;
  }
  return [
    for (var y = first; y <= today.year; y++) Bucket('$y', (sums[y] ?? 0) / 100),
  ];
}

/// Liczba miesięcy od najstarszego wpisu do miesiąca [today] włącznie (minimum 1).
int monthsSpanned(List<Tip> tips, DateTime today) {
  if (tips.isEmpty) return 1;
  final first = tips.map((t) => t.date).reduce((a, b) => a.isBefore(b) ? a : b);
  final m = (today.year - first.year) * 12 + today.month - first.month + 1;
  return m < 1 ? 1 : m;
}
