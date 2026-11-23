import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:napiwnik/models.dart';
import 'package:napiwnik/overview.dart';
import 'package:napiwnik/period.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl');
  });

  group('prognoza okresu', () {
    final period = BillingPeriod(DateTime(2026, 11, 16), DateTime(2026, 11, 30));
    final now = DateTime(2026, 11, 21, 12, 0);

    test('dotychczasowe zarobki plus zaplanowane godziny', () {
      final shifts = [
        Shift(id: 1, workplaceId: 1, date: DateTime(2026, 11, 17), startMin: 600, endMin: 840, tipId: 1),
        Shift(id: 2, workplaceId: 1, date: DateTime(2026, 11, 25), startMin: 600, endMin: 840),
      ];
      final tips = [Tip(id: 1, workplaceId: 1, date: DateTime(2026, 11, 17), cash: 2000)];
      final st = computePeriodStats(
        period: period,
        shifts: shifts,
        tips: tips,
        rates: {1: 3000},
        now: now,
      );
      expect(st.workedMin, 240);
      expect(st.remainingMin, 240);
      expect(st.wages, 12000);
      expect(st.remainingWages, 12000);
      expect(st.tipsPerHour, 500);
      // 14000 dotychczas + 12000 wypłaty za plan + 4 h × 5,00 zł napiwków na godzinę = 28000
      expect(st.forecastTotal, 28000);
    });

    test('bez zaplanowanych godzin brak prognozy', () {
      final shifts = [
        Shift(id: 1, workplaceId: 1, date: DateTime(2026, 11, 17), startMin: 600, endMin: 840),
      ];
      final st = computePeriodStats(
        period: period,
        shifts: shifts,
        tips: const [],
        rates: {1: 3000},
        now: now,
      );
      expect(st.forecastTotal, isNull);
    });

    test('bez stawek i bez napiwków brak prognozy', () {
      final shifts = [
        Shift(id: 2, date: DateTime(2026, 11, 25), startMin: 600, endMin: 840),
      ];
      final st = computePeriodStats(
        period: period,
        shifts: shifts,
        tips: const [],
        rates: const {},
        now: now,
      );
      expect(st.remainingMin, 240);
      expect(st.forecastTotal, isNull);
    });
  });

  group('deltaLine', () {
    test('więcej, mniej i tyle samo', () {
      expect(deltaLine(11000, 10000), '+10,00 zł (+10%) wobec poprzedniego okresu');
      expect(deltaLine(9000, 10000), '-10,00 zł (-10%) wobec poprzedniego okresu');
      expect(deltaLine(10000, 10000), 'tyle samo co w poprzednim okresie');
    });

    test('brak poprzedniego okresu', () {
      expect(deltaLine(5000, 0), isNull);
      expect(deltaLine(5000, -5), isNull);
    });
  });

  group('periodReportText', () {
    final period = BillingPeriod(DateTime(2026, 11, 1), DateTime(2026, 11, 30));

    test('z wypłatą', () {
      const st = PeriodStats(
        tipsNet: 14800,
        tipsGross: 14800,
        tipCount: 5,
        shiftCount: 0,
        workedMin: 2550,
        remainingMin: 0,
        wages: 32000,
        hasRates: true,
      );
      expect(periodReportText(period: period, stats: st), [
        'Napiwnik, okres 1.11–30.11',
        'Napiwki netto: 148,00 zł',
        'Godziny: 42 h 30 min',
        'Napiwki na godzinę: 3,48 zł',
        'Wypłata (stawka × godziny): 320,00 zł',
        'Razem: 468,00 zł',
      ].join('\n'));
    });

    test('bez stawek, z utargiem', () {
      const st = PeriodStats(
        tipsNet: 400,
        tipsGross: 400,
        tipCount: 1,
        shiftCount: 0,
        workedMin: 0,
        remainingMin: 0,
        wages: 0,
        hasRates: false,
        salesTotal: 5000,
        salesTipsGross: 400,
      );
      final text = periodReportText(period: period, stats: st);
      expect(text.contains('Utarg 50,00 zł · 8% napiwków'), isTrue);
      expect(text.contains('Razem'), isFalse);
      expect(text.contains('Napiwki na godzinę'), isFalse);
    });
  });
}
