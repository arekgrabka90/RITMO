import 'dates.dart';
import 'models.dart';
import 'percent.dart';
import 'period.dart';
import 'util.dart';

/// Przez ile godzin po zakończeniu zmiana zostaje na Dashboardzie (żeby zdążyć wpisać napiwki).
const dashboardLingerHours = 4;

enum ShiftPhase { upcoming, ongoing, ended }

ShiftPhase phaseOf(Shift s, DateTime now) {
  if (now.isBefore(s.start)) return ShiftPhase.upcoming;
  if (now.isBefore(s.end)) return ShiftPhase.ongoing;
  return ShiftPhase.ended;
}

/// Ile minut zmiany już upłynęło: 0 przed początkiem, pełny czas po zakończeniu.
int elapsedMin(Shift s, DateTime now) {
  if (!now.isAfter(s.start)) return 0;
  if (!now.isBefore(s.end)) return s.durationMin;
  final m = now.difference(s.start).inMinutes;
  return m > s.durationMin ? s.durationMin : m;
}

/// Do kiedy zmiana jest pokazywana na Dashboardzie jako „bieżąca”.
DateTime shiftVisibleUntil(Shift s) {
  final e = s.end;
  return DateTime(e.year, e.month, e.day, e.hour + dashboardLingerHours, e.minute);
}

/// Zmiana, którą pokazujemy na karcie „Dziś”: trwa teraz, albo skończyła się niedawno, albo zaczyna
/// się dziś. Kolejność: trwająca, skończona bez napiwków, dzisiejsza przyszła, skończona z napiwkami.
/// Zmiana znika po [dashboardLingerHours] godzinach od zakończenia.
Shift? pickFocusShift(List<Shift> shifts, DateTime now) {
  final endOfToday = DateTime(now.year, now.month, now.day + 1);
  Shift? best;
  var bestRank = 99;
  for (final s in shifts) {
    if (!now.isBefore(shiftVisibleUntil(s))) continue;
    if (!s.start.isBefore(endOfToday)) continue;
    final phase = phaseOf(s, now);
    final int rank;
    if (phase == ShiftPhase.ongoing) {
      rank = 0;
    } else if (phase == ShiftPhase.ended && !s.isDone) {
      rank = 1;
    } else if (phase == ShiftPhase.upcoming) {
      rank = 2;
    } else {
      rank = 3;
    }
    if (best == null || rank < bestRank || (rank == bestRank && s.start.isBefore(best.start))) {
      best = s;
      bestRank = rank;
    }
  }
  return best;
}

/// Najbliższe zmiany, które jeszcze się nie zaczęły (bez [exclude]), od najwcześniejszej.
List<Shift> upcomingShifts(List<Shift> shifts, DateTime now, {Shift? exclude, int limit = 4}) {
  final list = shifts
      .where((s) => s.start.isAfter(now) && (exclude == null || s.id != exclude.id))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  return list.take(limit).toList();
}

/// Zakończone zmiany z ostatnich 31 dni, do których nie wpisano napiwków (od najstarszej).
List<Shift> unfilledShifts(List<Shift> shifts, DateTime now) {
  final oldest = addDays(dateOnly(now), -31);
  final list = shifts
      .where((s) => s.hasEnded(now) && !s.isDone && !s.date.isBefore(oldest))
      .toList()
    ..sort((a, b) => a.start.compareTo(b.start));
  return list;
}

class PeriodStats {
  final int tipsNet; // napiwki netto w okresie
  final int tipsGross;
  final int tipCount;
  final int shiftCount;
  final int workedMin; // odpracowane (wliczając trwającą zmianę)
  final int remainingMin; // zaplanowane, jeszcze do przepracowania
  final int wages; // godziny × stawka, dotychczas
  final bool hasRates;

  /// Wynagrodzenie za zaplanowane, jeszcze nieodpracowane godziny (do prognozy).
  final int remainingWages;

  /// Suma utargu ze wpisów, w których go podano (informacyjnie), i napiwki brutto z tych samych wpisów.
  final int salesTotal;
  final int salesTipsGross;

  const PeriodStats({
    required this.tipsNet,
    required this.tipsGross,
    required this.tipCount,
    required this.shiftCount,
    required this.workedMin,
    required this.remainingMin,
    required this.wages,
    required this.hasRates,
    this.remainingWages = 0,
    this.salesTotal = 0,
    this.salesTipsGross = 0,
  });

  int get total => wages + tipsNet;

  /// Napiwki netto na godzinę (grosze) albo null, gdy brak godzin lub wpisów.
  int? get tipsPerHour =>
      (workedMin > 0 && tipCount > 0) ? (tipsNet * 60 / workedMin).round() : null;

  /// Napiwki jako procent utargu (tylko wpisy z utargiem) albo null.
  double? get tipsPercent => salesTotal > 0 ? salesTipsGross * 100 / salesTotal : null;

  /// Szacunek całego okresu przy obecnym tempie: dotychczasowe zarobki plus zaplanowane godziny
  /// (stawka i dotychczasowa średnia napiwków na godzinę). Null, gdy nie ma co przewidywać.
  int? get forecastTotal {
    if (remainingMin <= 0) return null;
    final ph = tipsPerHour;
    if (!hasRates && ph == null) return null;
    return total + remainingWages + (ph == null ? 0 : (ph * remainingMin / 60).round());
  }
}

/// „utarg 15 000,00 zł · 8% napiwków” albo null, gdy w okresie nikt nie podał utargu.
String? salesLine(PeriodStats s) {
  if (s.salesTotal <= 0) return null;
  final p = s.tipsPercent;
  return 'utarg ${fmtMoney(s.salesTotal)}${p != null ? ' · ${fmtPercent(p)} napiwków' : ''}';
}

/// Porównanie z poprzednim okresem: „+150,00 zł (+10%) wobec poprzedniego okresu”.
/// Null, gdy poprzedni okres nie miał napiwków (nie ma z czym porównać).
String? deltaLine(int current, int previous) {
  if (previous <= 0) return null;
  final diff = current - previous;
  if (diff == 0) return 'tyle samo co w poprzednim okresie';
  final sign = diff > 0 ? '+' : '-';
  final pct = diff.abs() * 100 / previous;
  return '$sign${fmtMoney(diff.abs())} ($sign${fmtPercent(pct)}) wobec poprzedniego okresu';
}

/// Tekstowe podsumowanie okresu do udostępnienia.
String periodReportText({required BillingPeriod period, required PeriodStats stats}) {
  final lines = <String>[
    'Napiwnik, okres ${periodRangeLabel(period)}',
    'Napiwki netto: ${fmtMoney(stats.tipsNet)}',
    'Godziny: ${fmtDuration(stats.workedMin)}',
  ];
  final ph = stats.tipsPerHour;
  if (ph != null) lines.add('Napiwki na godzinę: ${fmtMoney(ph)}');
  final sales = salesLine(stats);
  if (sales != null) lines.add('${sales[0].toUpperCase()}${sales.substring(1)}');
  if (stats.hasRates) {
    lines.add('Wypłata (stawka × godziny): ${fmtMoney(stats.wages)}');
    lines.add('Razem: ${fmtMoney(stats.total)}');
  }
  return lines.join('\n');
}

int _pay(int rate, int minutes) => (rate * minutes / 60).round();

/// Podsumowanie okresu. Godziny liczą się raz: ze zmian z grafiku, a z wpisów napiwków tylko
/// z tych, które nie są połączone z żadną zmianą. Zmiana należy do okresu dniem rozpoczęcia.
/// [rates] to stawki godzinowe miejsc pracy (id -> grosze za godzinę).
PeriodStats computePeriodStats({
  required BillingPeriod period,
  required List<Shift> shifts,
  required List<Tip> tips,
  required Map<int, int> rates,
  required DateTime now,
}) {
  final linked = <int>{for (final s in shifts) if (s.tipId != null) s.tipId!};
  var worked = 0;
  var remaining = 0;
  var wages = 0;
  var remainingWages = 0;
  var shiftCount = 0;
  for (final s in shifts) {
    if (!period.contains(s.date)) continue;
    shiftCount++;
    final e = elapsedMin(s, now);
    final rate = rates[s.workplaceId] ?? 0;
    worked += e;
    remaining += s.durationMin - e;
    wages += _pay(rate, e);
    remainingWages += _pay(rate, s.durationMin - e);
  }
  var net = 0;
  var gross = 0;
  var tipCount = 0;
  var salesTotal = 0;
  var salesGross = 0;
  for (final t in tips) {
    if (!period.contains(t.date)) continue;
    tipCount++;
    net += t.net;
    gross += t.gross;
    final sv = t.sales;
    if (sv != null && sv > 0) {
      salesTotal += sv;
      salesGross += t.gross;
    }
    final id = t.id;
    if (id != null && linked.contains(id)) continue; // godziny policzone ze zmiany
    final h = t.hours;
    if (h != null && h > 0) {
      final m = (h * 60).round();
      worked += m;
      wages += _pay(rates[t.workplaceId] ?? 0, m);
    }
  }
  return PeriodStats(
    tipsNet: net,
    tipsGross: gross,
    tipCount: tipCount,
    shiftCount: shiftCount,
    workedMin: worked,
    remainingMin: remaining,
    wages: wages,
    hasRates: rates.values.any((r) => r > 0),
    remainingWages: remainingWages,
    salesTotal: salesTotal,
    salesTipsGross: salesGross,
  );
}

/// Napiwki netto w okresie według miejsca pracy (null = bez miejsca).
Map<int?, int> tipsByWorkplace(BillingPeriod period, List<Tip> tips) {
  final out = <int?, int>{};
  for (final t in tips) {
    if (!period.contains(t.date)) continue;
    out[t.workplaceId] = (out[t.workplaceId] ?? 0) + t.net;
  }
  return out;
}
