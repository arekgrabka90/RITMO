import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/models.dart';

void main() {
  group('Tip', () {
    test('brutto, netto i stawka za godzinę', () {
      final t = Tip(
        date: DateTime(2026, 11, 21),
        cash: 10000,
        card: 5000,
        tipOut: 2000,
        hours: 5,
      );
      expect(t.gross, 15000);
      expect(t.net, 13000);
      expect(t.perHour, 2600);
    });

    test('bez godzin nie ma stawki za godzinę', () {
      expect(Tip(date: DateTime(2026, 11, 21), cash: 100).perHour, isNull);
      expect(Tip(date: DateTime(2026, 11, 21), cash: 100, hours: 0).perHour, isNull);
    });

    test('zmiana bez napiwków ma netto 0 i stawkę 0', () {
      final t = Tip(date: DateTime(2026, 11, 21), hours: 6);
      expect(t.net, 0);
      expect(t.perHour, 0);
    });

    test('toMap i fromMap zachowują dane', () {
      final t = Tip(
        id: 3,
        workplaceId: 2,
        date: DateTime(2026, 11, 20),
        cash: 1000,
        card: 500,
        tipOut: 100,
        hours: 6.5,
        note: 'wesele',
      );
      final back = Tip.fromMap(t.toMap());
      expect(back.id, 3);
      expect(back.workplaceId, 2);
      expect(back.date, DateTime(2026, 11, 20));
      expect(back.cash, 1000);
      expect(back.card, 500);
      expect(back.tipOut, 100);
      expect(back.hours, 6.5);
      expect(back.note, 'wesele');
    });

    test('asNew czyści id, withId je ustawia', () {
      final t = Tip(id: 7, date: DateTime(2026, 11, 20), cash: 100);
      expect(t.asNew().id, isNull);
      expect(t.asNew().withId(9).id, 9);
    });
  });

  group('Shift', () {
    test('czas trwania zwykłej zmiany', () {
      final s = Shift(date: DateTime(2026, 11, 20), startMin: 10 * 60, endMin: 18 * 60);
      expect(s.durationMin, 480);
      expect(s.hours, 8.0);
      expect(s.overnight, isFalse);
    });

    test('zmiana przez północ kończy się następnego dnia', () {
      final s = Shift(date: DateTime(2026, 11, 20), startMin: 22 * 60, endMin: 6 * 60);
      expect(s.durationMin, 480);
      expect(s.overnight, isTrue);
      expect(s.start, DateTime(2026, 11, 20, 22, 0));
      expect(s.end, DateTime(2026, 11, 21, 6, 0));
    });

    test('godziny zaokrąglone do 2 miejsc', () {
      final s = Shift(date: DateTime(2026, 11, 20), startMin: 600, endMin: 600 + 440);
      expect(s.hours, 7.33);
    });

    test('hasEnded: dopiero po zakończeniu zmiany', () {
      final s = Shift(date: DateTime(2026, 11, 20), startMin: 22 * 60, endMin: 6 * 60);
      expect(s.hasEnded(DateTime(2026, 11, 21, 5, 59)), isFalse);
      expect(s.hasEnded(DateTime(2026, 11, 21, 6, 0)), isTrue);
      expect(s.hasEnded(DateTime(2026, 11, 21, 12, 0)), isTrue);
      expect(s.hasEnded(DateTime(2026, 11, 19, 12, 0)), isFalse);
    });

    test('toMap i fromMap zachowują dane', () {
      final s = Shift(
        id: 4,
        workplaceId: 2,
        date: DateTime(2026, 11, 20),
        startMin: 600,
        endMin: 960,
        note: 'wesele',
        tipId: 9,
      );
      final back = Shift.fromMap(s.toMap());
      expect(back.id, 4);
      expect(back.workplaceId, 2);
      expect(back.date, DateTime(2026, 11, 20));
      expect(back.startMin, 600);
      expect(back.endMin, 960);
      expect(back.note, 'wesele');
      expect(back.tipId, 9);
      expect(back.isDone, isTrue);
    });

    test('withTip, withId i asNew', () {
      final s = Shift(id: 4, date: DateTime(2026, 11, 20), startMin: 600, endMin: 960, tipId: 9);
      expect(s.withTip(null).tipId, isNull);
      expect(s.withTip(null).isDone, isFalse);
      expect(s.withId(5).id, 5);
      expect(s.asNew().id, isNull);
      expect(s.asNew().tipId, 9);
    });
  });
}
