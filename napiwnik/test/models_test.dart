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
}
