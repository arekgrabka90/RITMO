import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/models.dart';
import 'package:napiwnik/overview.dart';
import 'package:napiwnik/period.dart';

Shift _s({
  int id = 1,
  DateTime? date,
  int start = 16 * 60,
  int end = 22 * 60,
  int? wid,
  int? tipId,
}) =>
    Shift(
      id: id,
      workplaceId: wid,
      date: date ?? DateTime(2026, 11, 21),
      startMin: start,
      endMin: end,
      tipId: tipId,
    );

void main() {
  // sobota 21.11.2026, 18:30
  final now = DateTime(2026, 11, 21, 18, 30);

  group('faza i upłynięty czas', () {
    final s = _s(); // 16:00–22:00

    test('phaseOf', () {
      expect(phaseOf(s, DateTime(2026, 11, 21, 15, 59)), ShiftPhase.upcoming);
      expect(phaseOf(s, DateTime(2026, 11, 21, 16, 0)), ShiftPhase.ongoing);
      expect(phaseOf(s, DateTime(2026, 11, 21, 21, 59)), ShiftPhase.ongoing);
      expect(phaseOf(s, DateTime(2026, 11, 21, 22, 0)), ShiftPhase.ended);
    });

    test('elapsedMin', () {
      expect(elapsedMin(s, DateTime(2026, 11, 21, 15, 0)), 0);
      expect(elapsedMin(s, DateTime(2026, 11, 21, 18, 30)), 150);
      expect(elapsedMin(s, DateTime(2026, 11, 21, 23, 0)), 360);
    });

    test('shiftVisibleUntil: 4 godziny po zakończeniu', () {
      expect(shiftVisibleUntil(s), DateTime(2026, 11, 22, 2, 0));
      final night = _s(start: 22 * 60, end: 6 * 60);
      expect(shiftVisibleUntil(night), DateTime(2026, 11, 22, 10, 0));
    });
  });

  group('pickFocusShift', () {
    test('trwająca zmiana wygrywa', () {
      final ongoing = _s(id: 1);
      final later = _s(id: 2, start: 23 * 60, end: 23 * 60 + 30);
      expect(pickFocusShift([later, ongoing], now)?.id, 1);
    });

    test('skończona zmiana zostaje do 4 godzin po zakończeniu', () {
      final ended = _s(start: 13 * 60, end: 15 * 60); // kończy się 15:00, widoczna do 19:00
      expect(pickFocusShift([ended], DateTime(2026, 11, 21, 18, 59))?.id, 1);
      expect(pickFocusShift([ended], DateTime(2026, 11, 21, 19, 0)), isNull);
    });

    test('skończona bez napiwków ma pierwszeństwo przed dzisiejszą przyszłą', () {
      final ended = _s(id: 1, start: 13 * 60, end: 15 * 60);
      final upcoming = _s(id: 2, start: 20 * 60, end: 23 * 60);
      expect(pickFocusShift([upcoming, ended], now)?.id, 1);
    });

    test('skończona z napiwkami ustępuje dzisiejszej przyszłej', () {
      final done = _s(id: 1, start: 13 * 60, end: 15 * 60, tipId: 9);
      final upcoming = _s(id: 2, start: 20 * 60, end: 23 * 60);
      expect(pickFocusShift([done, upcoming], now)?.id, 2);
    });

    test('zmiana jutrzejsza nie jest pokazywana jako dzisiejsza', () {
      final tomorrow = _s(date: DateTime(2026, 11, 22), start: 10 * 60, end: 18 * 60);
      expect(pickFocusShift([tomorrow], now), isNull);
    });

    test('zmiana przez północ zaczęta wczoraj nadal trwa', () {
      final night = _s(date: DateTime(2026, 11, 20), start: 22 * 60, end: 6 * 60);
      expect(pickFocusShift([night], DateTime(2026, 11, 21, 5, 0))?.id, 1);
      // po zakończeniu o 6:00 zostaje jeszcze do 10:00
      expect(pickFocusShift([night], DateTime(2026, 11, 21, 9, 59))?.id, 1);
      expect(pickFocusShift([night], DateTime(2026, 11, 21, 10, 0)), isNull);
    });

    test('brak zmian', () {
      expect(pickFocusShift([], now), isNull);
    });
  });

  group('upcomingShifts', () {
    final a = _s(id: 5, start: 20 * 60, end: 23 * 60);
    final b = _s(id: 6, date: DateTime(2026, 11, 22), start: 10 * 60, end: 14 * 60);
    final c = _s(id: 7, date: DateTime(2026, 11, 23), start: 10 * 60, end: 14 * 60);
    final past = _s(id: 8, date: DateTime(2026, 11, 20));

    test('tylko przyszłe, od najwcześniejszej', () {
      expect(upcomingShifts([c, past, b, a], now).map((s) => s.id), [5, 6, 7]);
    });

    test('limit i wykluczenie', () {
      expect(upcomingShifts([a, b, c], now, limit: 2).map((s) => s.id), [5, 6]);
      expect(upcomingShifts([a, b, c], now, exclude: a).map((s) => s.id), [6, 7]);
    });
  });

  test('unfilledShifts: zakończone bez napiwków z ostatnich 31 dni, od najstarszej', () {
    final shifts = [
      _s(id: 1, date: DateTime(2026, 11, 20)),
      _s(id: 2, date: DateTime(2026, 11, 19), tipId: 5),
      _s(id: 3, start: 13 * 60, end: 15 * 60),
      _s(id: 4, start: 20 * 60, end: 23 * 60),
      _s(id: 5, date: DateTime(2026, 10, 10)),
      _s(id: 6),
    ];
    expect(unfilledShifts(shifts, now).map((s) => s.id), [1, 3]);
  });

  group('computePeriodStats', () {
    final period = BillingPeriod(DateTime(2026, 11, 16), DateTime(2026, 11, 22));
    final statsNow = DateTime(2026, 11, 21, 18, 0);
    final shifts = [
      _s(id: 1, date: DateTime(2026, 11, 17), start: 600, end: 840, wid: 1, tipId: 1),
      _s(id: 2, date: DateTime(2026, 11, 18), start: 600, end: 720, wid: 1),
      _s(id: 3, date: DateTime(2026, 11, 21), start: 960, end: 1320, wid: 1),
      _s(id: 4, date: DateTime(2026, 11, 10), start: 600, end: 840, wid: 1),
    ];
    final tips = [
      Tip(id: 1, workplaceId: 1, date: DateTime(2026, 11, 17), cash: 1000, hours: 4),
      Tip(id: 2, workplaceId: 1, date: DateTime(2026, 11, 19), card: 500, hours: 3),
      Tip(id: 3, workplaceId: 1, date: DateTime(2026, 11, 10), cash: 9999),
    ];

    test('godziny liczą się raz, a stawka dotyczy odpracowanych', () {
      final st = computePeriodStats(
        period: period,
        shifts: shifts,
        tips: tips,
        rates: {1: 3000},
        now: statsNow,
      );
      expect(st.shiftCount, 3);
      expect(st.tipCount, 2);
      expect(st.tipsNet, 1500);
      expect(st.tipsGross, 1500);
      // zmiany: 240 + 120 + 120 (trwająca), wpis bez zmiany: 180; wpis połączony ze zmianą nie liczy się drugi raz
      expect(st.workedMin, 660);
      expect(st.remainingMin, 240);
      expect(st.wages, 33000);
      expect(st.total, 34500);
      expect(st.hasRates, isTrue);
      expect(st.tipsPerHour, 136);
    });

    test('bez stawek zarobki to 0', () {
      final st = computePeriodStats(
        period: period,
        shifts: shifts,
        tips: tips,
        rates: const {},
        now: statsNow,
      );
      expect(st.hasRates, isFalse);
      expect(st.wages, 0);
      expect(st.total, st.tipsNet);
    });

    test('pusty okres', () {
      final st = computePeriodStats(
        period: BillingPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 31)),
        shifts: shifts,
        tips: tips,
        rates: {1: 3000},
        now: statsNow,
      );
      expect(st.tipsNet, 0);
      expect(st.workedMin, 0);
      expect(st.tipsPerHour, isNull);
    });
  });

  test('tipsByWorkplace', () {
    final period = BillingPeriod(DateTime(2026, 11, 1), DateTime(2026, 11, 30));
    final tips = [
      Tip(workplaceId: 1, date: DateTime(2026, 11, 3), cash: 1000),
      Tip(workplaceId: 1, date: DateTime(2026, 11, 4), cash: 500, tipOut: 100),
      Tip(workplaceId: null, date: DateTime(2026, 11, 5), card: 300),
      Tip(workplaceId: 2, date: DateTime(2026, 10, 31), cash: 9999),
    ];
    final m = tipsByWorkplace(period, tips);
    expect(m[1], 1400);
    expect(m[null], 300);
    expect(m.containsKey(2), isFalse);
  });
}
