import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/period.dart';

void main() {
  group('nextPaydayAfterPeriod', () {
    test('co tydzień, 3 dni po końcu okresu', () {
      final anchor = DateTime(2026, 11, 16); // okres 16–22.11
      expect(
        nextPaydayAfterPeriod(DateTime(2026, 11, 21), PeriodType.weekly, anchor, 3),
        DateTime(2026, 11, 25),
      );
      expect(
        nextPaydayAfterPeriod(DateTime(2026, 11, 26), PeriodType.weekly, anchor, 3),
        DateTime(2026, 12, 2),
      );
    });

    test('0 dni: wypłata w ostatnim dniu okresu, dzisiejsza się liczy', () {
      final anchor = DateTime(2026, 11, 16);
      expect(
        nextPaydayAfterPeriod(DateTime(2026, 11, 22), PeriodType.weekly, anchor, 0),
        DateTime(2026, 11, 22),
      );
      expect(
        nextPaydayAfterPeriod(DateTime(2026, 11, 23), PeriodType.weekly, anchor, 0),
        DateTime(2026, 11, 29),
      );
    });

    test('co dwa tygodnie', () {
      final anchor = DateTime(2026, 11, 2); // okresy 2–15.11, 16–29.11
      expect(
        nextPaydayAfterPeriod(DateTime(2026, 11, 16), PeriodType.biweekly, anchor, 5),
        DateTime(2026, 11, 20),
      );
      expect(
        nextPaydayAfterPeriod(DateTime(2026, 11, 21), PeriodType.biweekly, anchor, 5),
        DateTime(2026, 12, 4),
      );
    });

    test('duże opóźnienie: wypłata za wcześniejszy okres', () {
      final anchor = DateTime(2026, 11, 16);
      // okres 9–15.11 + 14 dni = 29.11, okres 2–8.11 + 14 dni = 22.11 (już minione)
      expect(
        nextPaydayAfterPeriod(DateTime(2026, 11, 24), PeriodType.weekly, anchor, 14),
        DateTime(2026, 11, 29),
      );
    });

    test('zły zakres to null', () {
      final anchor = DateTime(2026, 11, 16);
      expect(nextPaydayAfterPeriod(DateTime(2026, 11, 21), PeriodType.weekly, anchor, -1), isNull);
      expect(nextPaydayAfterPeriod(DateTime(2026, 11, 21), PeriodType.weekly, anchor, 15), isNull);
    });
  });
}
