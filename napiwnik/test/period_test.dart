import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:napiwnik/period.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl');
  });

  final anyAnchor = DateTime(2026, 1, 5);

  group('periodFor', () {
    test('miesiąc kalendarzowy', () {
      final p = periodFor(DateTime(2026, 11, 21), PeriodType.monthly, anyAnchor);
      expect(p.start, DateTime(2026, 11, 1));
      expect(p.end, DateTime(2026, 11, 30));
      expect(p.days, 30);
      expect(periodFor(DateTime(2028, 2, 10), PeriodType.monthly, anyAnchor).end, DateTime(2028, 2, 29));
    });

    test('co tydzień od dnia początkowego', () {
      final anchor = DateTime(2026, 11, 16);
      final p = periodFor(DateTime(2026, 11, 21), PeriodType.weekly, anchor);
      expect(p.start, DateTime(2026, 11, 16));
      expect(p.end, DateTime(2026, 11, 22));
      expect(periodFor(DateTime(2026, 11, 23), PeriodType.weekly, anchor).start, DateTime(2026, 11, 23));
      expect(periodFor(DateTime(2026, 11, 29), PeriodType.weekly, anchor).end, DateTime(2026, 11, 29));
    });

    test('co tydzień, dzień początkowy w środku tygodnia', () {
      final anchor = DateTime(2026, 11, 18); // środa
      final p = periodFor(DateTime(2026, 11, 24), PeriodType.weekly, anchor);
      expect(p.start, DateTime(2026, 11, 18));
      expect(p.end, DateTime(2026, 11, 24));
    });

    test('dni sprzed dnia początkowego też należą do okresu', () {
      final anchor = DateTime(2026, 11, 16);
      final p = periodFor(DateTime(2026, 11, 15), PeriodType.weekly, anchor);
      expect(p.start, DateTime(2026, 11, 9));
      expect(p.end, DateTime(2026, 11, 15));
    });

    test('co dwa tygodnie', () {
      final anchor = DateTime(2026, 11, 2);
      final a = periodFor(DateTime(2026, 11, 21), PeriodType.biweekly, anchor);
      expect(a.start, DateTime(2026, 11, 16));
      expect(a.end, DateTime(2026, 11, 29));
      expect(a.days, 14);
      final b = periodFor(DateTime(2026, 11, 15), PeriodType.biweekly, anchor);
      expect(b.start, DateTime(2026, 11, 2));
      expect(b.end, DateTime(2026, 11, 15));
      final c = periodFor(DateTime(2026, 10, 30), PeriodType.biweekly, anchor);
      expect(c.start, DateTime(2026, 10, 19));
      expect(c.end, DateTime(2026, 11, 1));
    });

    test('każdy dzień należy do dokładnie jednego okresu', () {
      final anchor = DateTime(2026, 11, 4);
      for (final type in PeriodType.values) {
        var day = DateTime(2026, 10, 1);
        for (var i = 0; i < 120; i++) {
          day = DateTime(2026, 10, 1 + i);
          final p = periodFor(day, type, anchor);
          expect(p.contains(day), isTrue, reason: '$type $day');
          final prev = previousPeriod(p, type, anchor);
          final next = nextPeriod(p, type, anchor);
          expect(prev.end.add(const Duration(days: 1)).day, p.start.day);
          expect(next.start.day, DateTime(p.end.year, p.end.month, p.end.day + 1).day);
        }
        expect(day.isAfter(DateTime(2026, 10, 1)), isTrue);
      }
    });
  });

  group('previousPeriod i nextPeriod', () {
    test('miesiąc', () {
      final nov = periodFor(DateTime(2026, 11, 21), PeriodType.monthly, anyAnchor);
      final prev = previousPeriod(nov, PeriodType.monthly, anyAnchor);
      final next = nextPeriod(nov, PeriodType.monthly, anyAnchor);
      expect(prev.start, DateTime(2026, 10, 1));
      expect(prev.end, DateTime(2026, 10, 31));
      expect(next.start, DateTime(2026, 12, 1));
      expect(next.end, DateTime(2026, 12, 31));
    });

    test('tydzień', () {
      final anchor = DateTime(2026, 11, 16);
      final w = periodFor(DateTime(2026, 11, 21), PeriodType.weekly, anchor);
      expect(previousPeriod(w, PeriodType.weekly, anchor).start, DateTime(2026, 11, 9));
      expect(nextPeriod(w, PeriodType.weekly, anchor).start, DateTime(2026, 11, 23));
    });
  });

  group('BillingPeriod', () {
    final p = BillingPeriod(DateTime(2026, 11, 1), DateTime(2026, 11, 30));

    test('contains obejmuje granice', () {
      expect(p.contains(DateTime(2026, 11, 1)), isTrue);
      expect(p.contains(DateTime(2026, 11, 30, 23, 59)), isTrue);
      expect(p.contains(DateTime(2026, 10, 31)), isFalse);
      expect(p.contains(DateTime(2026, 12, 1)), isFalse);
    });

    test('daysLeft liczy dzisiejszy dzień', () {
      expect(p.daysLeft(DateTime(2026, 11, 21)), 10);
      expect(p.daysLeft(DateTime(2026, 11, 30)), 1);
      expect(p.daysLeft(DateTime(2026, 12, 2)), 0);
      expect(p.daysLeft(DateTime(2026, 11, 1)), 30);
    });
  });

  test('periodRangeLabel', () {
    expect(
      periodRangeLabel(BillingPeriod(DateTime(2026, 11, 10), DateTime(2026, 11, 23))),
      '10.11–23.11',
    );
    expect(
      periodRangeLabel(BillingPeriod(DateTime(2026, 12, 28), DateTime(2027, 1, 10))),
      '28.12.2026–10.01.2027',
    );
  });

  group('wypłata', () {
    test('nextPayday', () {
      expect(nextPayday(DateTime(2026, 11, 21), 10), DateTime(2026, 12, 10));
      expect(nextPayday(DateTime(2026, 11, 21), 25), DateTime(2026, 11, 25));
      expect(nextPayday(DateTime(2026, 11, 21), 21), DateTime(2026, 11, 21));
      expect(nextPayday(DateTime(2026, 11, 21), 1), DateTime(2026, 12, 1));
    });

    test('w krótkich miesiącach wypłata przypada na ostatni dzień', () {
      expect(nextPayday(DateTime(2026, 11, 21), 31), DateTime(2026, 11, 30));
      expect(nextPayday(DateTime(2026, 11, 30), 31), DateTime(2026, 11, 30));
      expect(nextPayday(DateTime(2026, 12, 1), 31), DateTime(2026, 12, 31));
      expect(nextPayday(DateTime(2027, 1, 31), 30), DateTime(2027, 1, 30).isBefore(DateTime(2027, 1, 31)) ? DateTime(2027, 2, 28) : DateTime(2027, 1, 30));
    });

    test('brak wypłaty', () {
      expect(nextPayday(DateTime(2026, 11, 21), 0), isNull);
      expect(nextPayday(DateTime(2026, 11, 21), 32), isNull);
      expect(daysToPayday(DateTime(2026, 11, 21), 0), isNull);
    });

    test('daysToPayday', () {
      expect(daysToPayday(DateTime(2026, 11, 21), 25), 4);
      expect(daysToPayday(DateTime(2026, 11, 25), 25), 0);
      expect(daysToPayday(DateTime(2026, 11, 26), 25), 29);
      expect(daysToPayday(DateTime(2026, 11, 21, 23, 30), 22), 1);
    });
  });

  test('periodTypeName', () {
    expect(periodTypeName(PeriodType.weekly), 'Co tydzień');
    expect(periodTypeName(PeriodType.biweekly), 'Co dwa tygodnie');
    expect(periodTypeName(PeriodType.monthly), 'Co miesiąc (kalendarzowy)');
  });
}
