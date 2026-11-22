import 'package:flutter_test/flutter_test.dart';
import 'package:napiwnik/models.dart';
import 'package:napiwnik/planning.dart';

void main() {
  final d1 = DateTime(2026, 11, 20);
  final d2 = DateTime(2026, 11, 21);
  const day = TimeRange(16 * 60, 22 * 60);

  group('TimeRange', () {
    test('minuty i poprawność', () {
      expect(day.minutes, 360);
      expect(day.valid, isTrue);
      expect(const TimeRange(22 * 60, 6 * 60).minutes, 480);
      expect(const TimeRange(600, 600).valid, isFalse);
      expect(const TimeRange(0, 1440).valid, isFalse);
      expect(const TimeRange(-1, 100).valid, isFalse);
    });

    test('porównywanie', () {
      expect(const TimeRange(600, 900), const TimeRange(600, 900));
      expect(const TimeRange(600, 900) == const TimeRange(600, 901), isFalse);
    });
  });

  group('dni', () {
    test('weekDays to 7 dni od poniedziałku do niedzieli', () {
      final w = weekDays(DateTime(2026, 11, 16));
      expect(w.length, 7);
      expect(w.first.weekday, DateTime.monday);
      expect(w.last.weekday, DateTime.sunday);
      expect(w.last, DateTime(2026, 11, 22));
    });

    test('daysOfWeekdayInMonth', () {
      final mondays = daysOfWeekdayInMonth(DateTime(2026, 11, 15), DateTime.monday);
      expect(mondays.length, 5);
      expect(mondays.first, DateTime(2026, 11, 2));
      expect(mondays.last, DateTime(2026, 11, 30));
      final fridays = daysOfWeekdayInMonth(DateTime(2026, 11, 1), DateTime.friday);
      expect(fridays, [
        DateTime(2026, 11, 6),
        DateTime(2026, 11, 13),
        DateTime(2026, 11, 20),
        DateTime(2026, 11, 27),
      ]);
    });
  });

  group('buildBulkPlan', () {
    BulkPlan plan({
      Set<DateTime>? days,
      Map<DateTime, TimeRange> overrides = const {},
      List<Shift> existing = const [],
      Conflict conflict = Conflict.skip,
    }) =>
        buildBulkPlan(
          days: days ?? {d2, d1},
          defaultRange: day,
          overrides: overrides,
          workplaceId: 3,
          existing: existing,
          conflict: conflict,
        );

    test('te same godziny dla wszystkich dni, wynik posortowany po dacie', () {
      final p = plan();
      expect(p.add.length, 2);
      expect(p.add.first.date, d1);
      expect(p.add.last.date, d2);
      for (final s in p.add) {
        expect(s.startMin, 960);
        expect(s.endMin, 1320);
        expect(s.workplaceId, 3);
        expect(s.tipId, isNull);
      }
      expect(p.replace, isEmpty);
      expect(p.skippedDays, 0);
    });

    test('godziny niestandardowe dla jednego dnia', () {
      final p = plan(overrides: {d2: const TimeRange(600, 900)});
      expect(p.add.first.startMin, 960);
      expect(p.add.last.startMin, 600);
      expect(p.add.last.endMin, 900);
    });

    test('konflikt: pomiń', () {
      final p = plan(existing: [Shift(id: 1, date: d1, startMin: 600, endMin: 900)]);
      expect(p.add.map((s) => s.date), [d2]);
      expect(p.skippedDays, 1);
    });

    test('konflikt: dodaj obok', () {
      final p = plan(
        existing: [Shift(id: 1, date: d1, startMin: 600, endMin: 900)],
        conflict: Conflict.add,
      );
      expect(p.add.length, 2);
      expect(p.replace, isEmpty);
      expect(p.skippedDays, 0);
    });

    test('konflikt: zastąp nie rusza zmian z wpisanymi napiwkami', () {
      final planned = Shift(id: 1, date: d1, startMin: 600, endMin: 900);
      final done = Shift(id: 2, date: d1, startMin: 1000, endMin: 1200, tipId: 5);
      final p = plan(existing: [planned, done], conflict: Conflict.replace);
      expect(p.replace.map((s) => s.id), [1]);
      expect(p.add.length, 2);
    });

    test('puste zaznaczenie nic nie dodaje', () {
      final p = plan(days: <DateTime>{});
      expect(p.add, isEmpty);
      expect(p.replace, isEmpty);
    });
  });
}
