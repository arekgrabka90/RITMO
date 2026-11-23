import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/backup.dart';
import 'package:napiwnik/models.dart';
import 'package:napiwnik/overview.dart';
import 'package:napiwnik/percent.dart';
import 'package:napiwnik/period.dart';

String _backupWithTip(Map<String, Object?> tip) => jsonEncode({
      'app': 'napiwnik',
      'version': 2,
      'workplaces': [],
      'tips': [tip],
      'shifts': [],
      'goal': 0,
    });

void main() {
  group('fmtPercent', () {
    test('całkowite bez przecinka, ułamki z jednym miejscem', () {
      expect(fmtPercent(11.0), '11%');
      expect(fmtPercent(11.234), '11,2%');
      expect(fmtPercent(0), '0%');
      expect(fmtPercent(9.96), '10%');
      expect(fmtPercent(8.04), '8%');
    });
  });

  group('Tip i utarg', () {
    test('procent z napiwków brutto', () {
      final t = Tip(date: DateTime(2026, 11, 20), cash: 1000, card: 500, tipOut: 200, sales: 15000);
      expect(t.tipPercent, 10.0);
    });

    test('bez utargu lub z zerem nie ma procentu', () {
      expect(Tip(date: DateTime(2026, 11, 20), cash: 1000).tipPercent, isNull);
      expect(Tip(date: DateTime(2026, 11, 20), cash: 1000, sales: 0).tipPercent, isNull);
    });

    test('utarg nie zmienia kwot', () {
      final a = Tip(date: DateTime(2026, 11, 20), cash: 1000, card: 500, tipOut: 200);
      final b = Tip(date: DateTime(2026, 11, 20), cash: 1000, card: 500, tipOut: 200, sales: 99999);
      expect(b.net, a.net);
      expect(b.gross, a.gross);
    });

    test('toMap, fromMap, asNew i withId zachowują utarg', () {
      final t = Tip(id: 3, date: DateTime(2026, 11, 20), cash: 1000, sales: 12345);
      expect(Tip.fromMap(t.toMap()).sales, 12345);
      expect(t.asNew().sales, 12345);
      expect(t.withId(9).sales, 12345);
      expect(Tip.fromMap(Tip(date: DateTime(2026, 11, 20), cash: 1).toMap()).sales, isNull);
    });
  });

  group('kopia zapasowa a utarg', () {
    test('utarg przechodzi przez kopię, wpis bez utargu zostaje bez', () {
      final data = parseBackup(encodeBackup(
        workplaces: const [],
        tips: [
          Tip(id: 1, date: DateTime(2026, 11, 20), cash: 1000, sales: 12345),
          Tip(id: 2, date: DateTime(2026, 11, 21), cash: 500),
        ],
        goal: 0,
      ));
      expect(data.tips.first.sales, 12345);
      expect(data.tips.last.sales, isNull);
    });

    test('starsza kopia bez pola utargu wczytuje się', () {
      final data = parseBackup(_backupWithTip({
        'id': 1,
        'workplace_id': null,
        'date': '2026-11-20',
        'cash': 100,
        'card': 0,
        'tip_out': 0,
        'hours': null,
        'note': '',
      }));
      expect(data.tips.single.sales, isNull);
    });

    test('ujemny utarg to uszkodzony plik', () {
      expect(
        () => parseBackup(_backupWithTip({
          'id': 1,
          'workplace_id': null,
          'date': '2026-11-20',
          'cash': 100,
          'card': 0,
          'tip_out': 0,
          'hours': null,
          'note': '',
          'sales': -5,
        })),
        throwsFormatException,
      );
    });

    test('wpis z nieistniejącym miejscem zachowuje utarg', () {
      final data = parseBackup(jsonEncode({
        'app': 'napiwnik',
        'version': 2,
        'workplaces': [],
        'tips': [
          {
            'id': 1,
            'workplace_id': 99,
            'date': '2026-11-20',
            'cash': 100,
            'card': 0,
            'tip_out': 0,
            'hours': null,
            'note': '',
            'sales': 5000,
          }
        ],
        'shifts': [],
        'goal': 0,
      }));
      expect(data.tips.single.workplaceId, isNull);
      expect(data.tips.single.sales, 5000);
    });
  });

  group('utarg w podsumowaniu okresu', () {
    final period = BillingPeriod(DateTime(2026, 11, 1), DateTime(2026, 11, 30));
    final now = DateTime(2026, 11, 21, 18, 0);

    PeriodStats stats(List<Tip> tips) => computePeriodStats(
          period: period,
          shifts: const [],
          tips: tips,
          rates: const {},
          now: now,
        );

    test('procent liczy się tylko z wpisów z utargiem', () {
      final s = stats([
        Tip(date: DateTime(2026, 11, 3), cash: 1000, sales: 10000),
        Tip(date: DateTime(2026, 11, 4), cash: 500), // bez utargu, nie psuje średniej
        Tip(date: DateTime(2026, 11, 5), card: 200, sales: 5000),
      ]);
      expect(s.salesTotal, 15000);
      expect(s.salesTipsGross, 1200);
      expect(s.tipsPercent, 8.0);
      expect(s.tipsNet, 1700);
      expect(salesLine(s), 'utarg 150,00 zł · 8% napiwków');
    });

    test('bez utargu brak linijki', () {
      final s = stats([Tip(date: DateTime(2026, 11, 3), cash: 1000)]);
      expect(s.salesTotal, 0);
      expect(s.tipsPercent, isNull);
      expect(salesLine(s), isNull);
    });

    test('utarg spoza okresu się nie liczy', () {
      final s = stats([Tip(date: DateTime(2026, 10, 31), cash: 1000, sales: 10000)]);
      expect(s.salesTotal, 0);
    });
  });
}
